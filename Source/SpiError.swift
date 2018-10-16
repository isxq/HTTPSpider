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
///
public enum SpiError: Error {
    
    /// 参数编码失败原因
    ///
    /// - missingURL:      无可用URL
    public enum ParameterEncodingFailureReason {
        case missingURL
        case jsonEncodingFailed(Error)
    }
    
    public enum ResponseValidationFailureReason {
        case dataFileNil
        case dataFileReadFailed(at: URL)
        case missingContentType(acceptableContentTypes: [String])
        case unacceptableContentType(acceptableContentTypes: [String], responseContentType: String)
        case unacceptableStatusCode(code: Int)
        case resultCheckError(message: String)
        case resultCheckNotFind
    }
    
    public enum ResponseSerializationFailureReason {
        case dataIsNil
        case serializationError
        case transformError
        case canNotFindDataForJsonPath
        case jsonCanNotEncode
        case canNotReadCodableType
    }
    
    case invalidURL(baseURL: String, path: String)
    case parameterEncodingFailed(reason: ParameterEncodingFailureReason)
    case responseValidationFailed(reason: ResponseValidationFailureReason)
    case responseSerializationFailed(reason: ResponseSerializationFailureReason)
}
