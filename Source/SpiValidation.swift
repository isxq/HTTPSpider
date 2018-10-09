//
//  SpiValidation.swift
//  Spider
//
//  Created by ios on 2018/10/8.
//  Copyright © 2018 ios. All rights reserved.
//

import Foundation

open class SpiValidation {
    
    fileprivate typealias ErrorReason = SpiError.ResponseValidationFailureReason
    public typealias Validation = (URLRequest?, HTTPURLResponse, Data?) -> ValidationResult
    weak var request: SpiRequest?
    var validation: Validation!
    
    public enum ValidationResult {
        case success
        case failure(Error)
    }
    
    fileprivate struct MIMEType {
        let type: String
        let subtype: String
        
        var isWildcard: Bool { return type == "*" && subtype == "*" }
        
        init?(_ string: String) {
            let components: [String] = {
                let stripped = string.trimmingCharacters(in: .whitespacesAndNewlines)
                
                #if swift(>=3.2)
                let split = stripped[..<(stripped.range(of: ";")?.lowerBound ?? stripped.endIndex)]
                #else
                let split = stripped.substring(to: stripped.range(of: ";")?.lowerBound ?? stripped.endIndex)
                #endif
                
                return split.components(separatedBy: "/")
            }()
            
            if let type = components.first, let subtype = components.last {
                self.type = type
                self.subtype = subtype
            } else {
                return nil
            }
        }
        
        func matches(_ mime: MIMEType) -> Bool {
            switch (type, subtype) {
            case (mime.type, mime.subtype), (mime.type, "*"), ("*", mime.subtype), ("*", "*"):
                return true
            default:
                return false
            }
        }
    }
    
    fileprivate var acceptableStatusCodes: [Int] { return Array(200..<300) }
    
    fileprivate var acceptableContentTypes: [String] {
        if let accept = request?.request?.value(forHTTPHeaderField: "Accept") {
            return accept.components(separatedBy: ",")
        }
        
        return ["*/*"]
    }
    
    fileprivate init() {}
    
    public init(_ validation: @escaping Validation) {
        self.validation = validation
    }
    
    func validate() {
        if let request = request,
            let originalRequest = request.request,
            let response = request.response,
            case let .failure(error) = validation(originalRequest, response, request.delegate.data)
        {
            request.delegate.error = error
        }
    }
    
}

open class StatuCodeValidation: SpiValidation {
    
    public init(_ statuCodes: [Int]? = nil) {
        super.init()
        let statuCodes = statuCodes ?? self.acceptableStatusCodes
        validation = { [unowned self](_, response, _) -> SpiValidation.ValidationResult in
            return self.validate(statusCode: statuCodes, response: response)
        }
    }
    
    fileprivate func validate(
        statusCode acceptableStatusCodes: [Int],
        response: HTTPURLResponse)
        -> ValidationResult
    {
        if acceptableStatusCodes.contains(response.statusCode) {
            return .success
        } else {
            let reason: ErrorReason = .unacceptableStatusCode(code: response.statusCode)
            return .failure(SpiError.responseValidationFailed(reason: reason))
        }
    }
    
}

open class ContentTypeValidation: SpiValidation {
    
    public init(_ contentTypes: [String]? = nil) {
        super.init()
        let contentTypes = contentTypes ?? self.acceptableContentTypes
        validation = { [unowned self](_, response, data) -> SpiValidation.ValidationResult in
            return self.validate(contentType: contentTypes, response: response, data: data)
        }
    }
    
    fileprivate func validate<S: Sequence>(
        contentType acceptableContentTypes: S,
        response: HTTPURLResponse,
        data: Data?)
        -> ValidationResult
        where S.Iterator.Element == String
    {
        guard let data = data, data.count > 0 else { return .success }
        
        guard
            let responseContentType = response.mimeType,
            let responseMIMEType = MIMEType(responseContentType)
            else {
                for contentType in acceptableContentTypes {
                    if let mimeType = MIMEType(contentType), mimeType.isWildcard {
                        return .success
                    }
                }
                
                let error: SpiError = {
                    let reason: ErrorReason = .missingContentType(acceptableContentTypes: Array(acceptableContentTypes))
                    return SpiError.responseValidationFailed(reason: reason)
                }()
                
                return .failure(error)
        }
        
        for contentType in acceptableContentTypes {
            if let acceptableMIMEType = MIMEType(contentType), acceptableMIMEType.matches(responseMIMEType) {
                return .success
            }
        }
        
        let error: SpiError = {
            let reason: ErrorReason = .unacceptableContentType(
                acceptableContentTypes: Array(acceptableContentTypes),
                responseContentType: responseContentType
            )
            
            return SpiError.responseValidationFailed(reason: reason)
        }()
        
        return .failure(error)
    }
}

extension SpiRequest {
    
    @discardableResult
    public func validates(_ validates: SpiValidation...) -> Self {
        validations.append(contentsOf: validates)
        return self
    }
    
}

// TODO: 下载相关验证
