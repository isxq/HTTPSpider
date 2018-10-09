//
//  ServerTrustPolicy.swift
//  Spider
//
//  Created by ios on 2018/9/29.
//  Copyright © 2018 ios. All rights reserved.
//

import Foundation

open class ServerTrustPolicyManager {
    
    public let policies: [String: ServerTrustPolicy]
    
    public init(policies: [String: ServerTrustPolicy]) {
        self.policies = policies
    }
    
    public func serverTrustPolicy(forHost host: String) -> ServerTrustPolicy? {
        return policies[host]
    }
    
}

extension URLSession {
    private struct AssociatedKeys  {
        static var managerKey = "URLSession.ServerTrustPolicyManager"
    }
    
    var serverTrustPolicyManager: ServerTrustPolicyManager? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.managerKey) as? ServerTrustPolicyManager
        }
        set (manager) {
            objc_setAssociatedObject(self, &AssociatedKeys.managerKey, manager, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

public enum ServerTrustPolicy {
    case performDefaultEvaluation(validateHost: Bool)
    case performRevokedEvaluation(validateHost: Bool, revocationFlags: CFOptionFlags)
    case pinCertificates(certificates: [SecCertificate], validateCertificateChain: Bool, validateHost: Bool)
    case pinPublicKeys(publicKeys: [SecKey], validateCertificateChain: Bool, validateHost: Bool)
    case disableEvaluation
    case customEvaluation((_ serverTrust: SecTrust, _ host: String) -> Bool)
    
    // MARK: - Bundle Location
    
    public static func certificates(in bundle: Bundle = Bundle.main) -> [SecCertificate] {
        var certificates: [SecCertificate] = []
        
        let paths = Set([".cer", ".CER", ".crt", ".CRT", ".der", ".DER"].map { fileExtension in
            bundle.paths(forResourcesOfType: fileExtension, inDirectory: nil)
            }.joined())
        
        for path in paths {
            if
                let certificateData = try? Data(contentsOf: URL(fileURLWithPath: path)) as CFData,
                let certificate = SecCertificateCreateWithData(nil, certificateData)
            {
                certificates.append(certificate)
            }
        }
        
        return certificates
    }
    
    public static func publicKeys(in bundle: Bundle = Bundle.main) -> [SecKey] {
        var publicKeys: [SecKey] = []
        
        for certificate in certificates(in: bundle) {
            if let publicKey = publicKey(for: certificate) {
                publicKeys.append(publicKey)
            }
        }
        
        return publicKeys
    }
    
    // MARK: - Evaluation
    public func evaluate(_ serverTrust: SecTrust, forHost host: String) -> Bool {
        var serverTrustIsValid = false
        
        switch self {
        case let .performDefaultEvaluation(validateHost):
            let policy = SecPolicyCreateSSL(true, validateHost ? host as CFString : nil)
            SecTrustSetPolicies(serverTrust, policy)
            
            serverTrustIsValid = trustIsValid(serverTrust)
        case let .performRevokedEvaluation(validateHost, revocationFlags):
            let defaultPolicy = SecPolicyCreateSSL(true, validateHost ? host as CFString : nil)
            let revokedPolicy = SecPolicyCreateRevocation(revocationFlags)
            SecTrustSetPolicies(serverTrust, [defaultPolicy, revokedPolicy] as CFTypeRef)
            
            serverTrustIsValid = trustIsValid(serverTrust)
        case let .pinCertificates(pinnedCertificates, validateCertificateChain, validateHost):
            if validateCertificateChain {
                let policy = SecPolicyCreateSSL(true, validateHost ? host as CFString : nil)
                SecTrustSetPolicies(serverTrust, policy)
                
                SecTrustSetAnchorCertificates(serverTrust, pinnedCertificates as CFArray)
                SecTrustSetAnchorCertificatesOnly(serverTrust, true)
                
                serverTrustIsValid = trustIsValid(serverTrust)
            } else {
                let serverCertificatesDataArray = certificateData(for: serverTrust)
                let pinnedCertificatesDataArray = certificateData(for: pinnedCertificates)
                
                outerLoop: for serverCertificateData in serverCertificatesDataArray {
                    for pinnedCertificateData in pinnedCertificatesDataArray {
                        if serverCertificateData == pinnedCertificateData {
                            serverTrustIsValid = true
                            break outerLoop
                        }
                    }
                }
            }
        case let .pinPublicKeys(pinnedPublicKeys, validateCertificateChain, validateHost):
            var certificateChainEvaluationPassed = true
            
            if validateCertificateChain {
                let policy = SecPolicyCreateSSL(true, validateHost ? host as CFString : nil)
                SecTrustSetPolicies(serverTrust, policy)
                
                certificateChainEvaluationPassed = trustIsValid(serverTrust)
            }
            
            if certificateChainEvaluationPassed {
                outerLoop: for serverPublicKey in ServerTrustPolicy.publicKeys(for: serverTrust) as [AnyObject] {
                    for pinnedPublicKey in pinnedPublicKeys as [AnyObject] {
                        if serverPublicKey.isEqual(pinnedPublicKey) {
                            serverTrustIsValid = true
                            break outerLoop
                        }
                    }
                }
            }
        case .disableEvaluation:
            serverTrustIsValid = true
        case let .customEvaluation(closure):
            serverTrustIsValid = closure(serverTrust, host)
        }
        
        return serverTrustIsValid
    }
    
    // MARK: - Private - Trust Validation
    
    private func trustIsValid(_ trust: SecTrust) -> Bool {
        var isValid = false
        
        var result = SecTrustResultType.invalid
        let status = SecTrustEvaluate(trust, &result)
        
        if status == errSecSuccess {
            let unspecified = SecTrustResultType.unspecified
            let proceed = SecTrustResultType.proceed
            
            
            isValid = result == unspecified || result == proceed
        }
        
        return isValid
    }
    
    // MARK: - Private - Certificate Data
    
    private func certificateData(for trust: SecTrust) -> [Data] {
        var certificates: [SecCertificate] = []
        
        for index in 0..<SecTrustGetCertificateCount(trust) {
            if let certificate = SecTrustGetCertificateAtIndex(trust, index) {
                certificates.append(certificate)
            }
        }
        
        return certificateData(for: certificates)
    }
    
    private func certificateData(for certificates: [SecCertificate]) -> [Data] {
        return certificates.map { SecCertificateCopyData($0) as Data }
    }
    
    // MARK: - Private - Public Key Extraction
    
    private static func publicKeys(for trust: SecTrust) -> [SecKey] {
        var publicKeys: [SecKey] = []
        
        for index in 0..<SecTrustGetCertificateCount(trust) {
            if
                let certificate = SecTrustGetCertificateAtIndex(trust, index),
                let publicKey = publicKey(for: certificate)
            {
                publicKeys.append(publicKey)
            }
        }
        
        return publicKeys
    }
    
    private static func publicKey(for certificate: SecCertificate) -> SecKey? {
        var publicKey: SecKey?
        
        let policy = SecPolicyCreateBasicX509()
        var trust: SecTrust?
        let trustCreationStatus = SecTrustCreateWithCertificates(certificate, policy, &trust)
        
        if let trust = trust, trustCreationStatus == errSecSuccess {
            publicKey = SecTrustCopyPublicKey(trust)
        }
        
        return publicKey
    }
}

extension ServerTrustPolicy: Hashable {
    
    public static func == (lhs: ServerTrustPolicy, rhs: ServerTrustPolicy) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    public var hashValue: Int {
        switch self {
        case .customEvaluation:         return 0
        case .disableEvaluation:        return 1
        case .performDefaultEvaluation: return 2
        case .performRevokedEvaluation: return 3
        case .pinCertificates:          return 4
        case .pinPublicKeys:            return 5
        }
    }
    
}
