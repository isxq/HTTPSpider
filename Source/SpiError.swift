//
//  SpiError.swift
//  Spider
//
//  Created by ios on 2018/9/27.
//  Copyright © 2018 ios. All rights reserved.
//

import Foundation

///Bat 请求过程中出现的错误
///
/// - invalidURL:   构造URL失败或生成的为无效的URL
///     - baseURL:  构造URL的基地址
///     - path:     URL请求路径
/// - parameterEncodingFalied:  参数编码过程中出现的错误
/// - responseValidationFailed: 当`validate（）`调用失败时返回
/// - responseSerializationFailed: 响应序列化程序在序列化过程中遇到错误时返回
/// - responseCodableFailed: 响应结果编码错误

public enum SpiError: Error {
    
    /// 参数编码失败原因
    ///
    /// - missingURL:           无可用URL
    /// - jsonEncodingFailed:   JSON序列化过程出现错误
    public enum ParameterEncodingFailureReason {
        case missingURL
        case jsonEncodingFailed(Error)
    }
    
    /// 响应验证错误
    ///
    /// - dataFileNil:     数据文件为空
    /// - dataFileReadFailed: 数据文件读取失败
    /// - missingContentType: 响应数据中不包含 “Content-Type” 并且提供的 “acceptableContentTypes” 中不包含通配符
    /// - unacceptableContentType: 响应数据中的“Content-Type”在“acceptableContentTypes”找不到匹配项
    /// - unacceptableStatusCode: 状态码不被接受
    public enum ResponseValidationFailureReason {
        case dataFileNil
        case dataFileReadFailed(at: URL)
        case missingContentType(acceptableContentTypes: [String])
        case unacceptableContentType(acceptableContentTypes: [String], responseContentType: String)
        case unacceptableStatusCode(code: Int)
    }
    
    /// 响应数据序列化失败原因
    ///
    /// - dataIsNil: 响应数据为空
    /// - jsonIsNotADictionary: 序列化结果不是字典
    /// - jsonSerializationFailed: JSON 序列化失败
    public enum ResponseSerializationFailureReason {
        case dataIsNil
        case jsonIsNotADictionary
        case jsonSerializationFailed(Error)
        case dataLengthIsZero
    }
    
    case invalidURL(baseURL: String, path: String)
    case parameterEncodingFailed(reason: ParameterEncodingFailureReason)
    case responseValidationFailed(reason: ResponseValidationFailureReason)
    case responseSerializationFailed(reason: ResponseSerializationFailureReason)
}

struct AdaptError: Error {
    let error: Error
}

extension Error {
    var underlyingAdaptError: Error? { return (self as? AdaptError)?.error }
}

extension SpiError {
    
    public var isInvalidURL : Bool {
        if case .invalidURL = self {return true}
        return false
    }
    
    public var isParameterEncodingFailed : Bool {
        if case .parameterEncodingFailed = self {return true}
        return false
    }
    
    public var isResponseValidationFailed : Bool {
        if case .responseValidationFailed = self {return true}
        return false
    }
    
    public var isResponseSerializationFailed : Bool {
        if case .responseSerializationFailed = self {return true}
        return false
    }
}

extension SpiError {
    
    var underlyingError: Error? {
        switch self {
        case .parameterEncodingFailed(reason: let reason):
            return reason.underlyingError
        case .responseSerializationFailed(reason: let reason):
            return reason.underlyingError
        case .responseValidationFailed(reason: let reason):
            return reason.underlyingError
        default:
            return nil
        }
    }
}

extension SpiError.ParameterEncodingFailureReason {
    
    var underlyingError: Error? {
        switch self {
        case .jsonEncodingFailed(let error):
            return error
        default:
            return nil
        }
    }
    
}

extension SpiError.ResponseSerializationFailureReason {
    
    var underlyingError: Error? {
        switch  self {
        case .jsonSerializationFailed(let error):
            return error
        default:
            return nil
        }
    }
    
}

extension SpiError.ResponseValidationFailureReason {
    
    var underlyingError: Error? {
        return nil
    }
}

extension SpiError: LocalizedError {
    public var errorDescription: String?{
        switch self {
        case .invalidURL(let base, let path):
            return "Invalid URL :=> base:\(base), path:\(path)"
        case .parameterEncodingFailed(let reason):
            return reason.errorDescription
        case .responseSerializationFailed(let reason):
            return reason.errorDescription
        case .responseValidationFailed(let reason):
            return reason.errorDescription
        }
    }
}

extension SpiError.ParameterEncodingFailureReason: LocalizedError {
    public var errorDescription: String?{
        switch self {
        case .missingURL:
            return "Missing url"
        case .jsonEncodingFailed(let error):
            return "Parameter Json Encoding Failed:\(error.localizedDescription)"
        }
    }
}

extension SpiError.ResponseSerializationFailureReason: LocalizedError{
    public var errorDescription: String?{
        switch self {
        case .dataIsNil:
            return "The data in response was nil"
        case .jsonSerializationFailed(let error):
            return "Response Serialization Failed: \(error.localizedDescription)"
        case .jsonIsNotADictionary:
            return "The Serialization Result is not a Dictionary"
        case .dataLengthIsZero:
            return "The return data length was zero"
        }
    }
}

extension SpiError.ResponseValidationFailureReason: LocalizedError{
    var localizedDescription: String {
        switch self {
        case .dataFileNil:
            return "Response could not be validated, data file was nil."
        case .dataFileReadFailed(let url):
            return "Response could not be validated, data file could not be read: \(url)."
        case .missingContentType(let types):
            return (
                "Response Content-Type was missing and acceptable content types " +
                "(\(types.joined(separator: ","))) do not match \"*/*\"."
            )
        case .unacceptableContentType(let acceptableTypes, let responseType):
            return (
                "Response Content-Type \"\(responseType)\" does not match any acceptable types: " +
                "\(acceptableTypes.joined(separator: ","))."
            )
        case .unacceptableStatusCode(let code):
            return "Response status code was unacceptable: \(code)."
        }
    }
}
