//
//  SpiFeatures.swift
//  Spider
//
//  Created by ios on 2018/9/27.
//  Copyright © 2018 ios. All rights reserved.
//

import Foundation

public enum SpiFeature: Hashable {
    
    case cache(URLCache?, URLRequest.CachePolicy?)
    case trust([String: ServerTrustPolicy])
   
    
    var featureValue: String {
        switch self {
        case .cache(let cache, _): return "cache(\((cache ?? SpiManager.manager.urlCache).hashValue))"
        case .trust(let policies): return "trust(\(policies.hashValue))"
        }
    }
}

// hashable
extension SpiFeature {
    public static func == (lhs: SpiFeature, rhs: SpiFeature) -> Bool {
        return lhs.featureValue == rhs.featureValue
    }
    public var hashValue: Int {
        return featureValue.hashValue
    }
}

extension SpiFeature {
    
    func config(_ configuration: inout URLSessionConfiguration) {
        switch self {
        case .cache(let cache, _):
            let urlCache = cache ?? SpiManager.manager.urlCache
            configuration.urlCache = urlCache
        default: break
        }
    }
    
    func config(_ request: inout URLRequest) {
        switch self {
        case .cache(_, let policy):
            request.cachePolicy = policy ?? .useProtocolCachePolicy
        default: break
        }
    }
    
    func config(_ session: inout URLSession) {
        switch self {
        case .trust(let policies):
            session.serverTrustPolicyManager = ServerTrustPolicyManager(policies: policies)
        default: break
        }
    }
}
