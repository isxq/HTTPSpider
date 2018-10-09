//
//  SpiEncoder.swift
//  Spider
//
//  Created by ios on 2018/9/27.
//  Copyright © 2018 ios. All rights reserved.
//

import Foundation

/// 负责 URL 的参数编码
public struct URLEncoder {
    
    // MARK: - 编码方式及值定义
    
    /// 编码类型
    ///
    /// - methodDependent:  依据传入的请求方式判断
    /// - queryString:      请求字符串
    /// - httpBody:         请求体
    public enum Destination {
        case methodDependent, queryString, httpBody
    }
    
    /// 数组编码方式
    ///
    /// - brackets: 带中括号
    /// - noBrackets: 不带中括号
    public enum ArrayEncoding {
        case brackets, noBrackets
        
        func encode(key: String) -> String {
            switch self {
            case .brackets:
                return "\(key)[]"
            case .noBrackets:
                return key
            }
        }
    }
    
    /// 布尔值编码方式
    ///
    /// - numeric: 数值方式
    /// - literal: 字面量
    public enum BoolEncoding {
        case numeric, literal
        
        func encode(value: Bool) -> String {
            switch self {
            case .numeric:
                return value ? "1" : "0"
            case .literal:
                return value ? "true" : "false"
            }
        }
    }
    
    //MARK: - Properties
    public let destination: Destination
    
    public let arrayEncoding: ArrayEncoding
    
    public let boolEncoding: BoolEncoding
    
    /// 返回一个默认的 `URLEncoder`实例
    public static var `default`: URLEncoder { return URLEncoder() }
    
    /// 返回一个依据方法判断的 `URLEncoder`实例
    public static var methodDependent: URLEncoder { return URLEncoder() }
    
    /// 返回一个进行字符串编码的 `URLEncoder`实例
    public static var queryString: URLEncoder { return URLEncoder(destination: .queryString) }
    
    /// 返回一个进行请求体编码的 `URLEncoder`实例
    public static var httpBody: URLEncoder { return URLEncoder(destination: .httpBody) }
    
    /// escapeString 自定义回调
    var filterEscapeString: ((String) -> String?)?
    
    //MARK: - Initialization
    
    public init(destination: Destination = .methodDependent, arrayEncoding: ArrayEncoding = .brackets, boolEncoding: BoolEncoding = .numeric) {
        self.destination = destination
        self.arrayEncoding = arrayEncoding
        self.boolEncoding = boolEncoding
    }
    
    //MARK: - Encoding
    
    /// 根据提供的 `Target` 创建一个编码后的 `URLRequest`
    ///
    /// - Parameter :
    ///     - originalRequest:  原始请求
    ///     - parameters:       请求参数
    ///     - method:           请求方式
    /// - throws: 编码过程中遇到的错误
    /// - returns: 编码后的 `URLRequest` 实例
    public func encode(_ originalRequest: URLRequest, parameters: Parameters?, method: HTTPMethod) throws -> URLRequest {
        var request = originalRequest
        guard let parameters = parameters else { return request }
        if encodesParametersInURL(with: method) {
            guard let url = request.url else {
                throw SpiError.parameterEncodingFalied(reason: .missingURL)
            }
            if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
                !parameters.isEmpty {
                let percentEncodedQuery = (urlComponents.percentEncodedQuery.map{ $0 + "&" } ?? "") + query(parameters)
                urlComponents.percentEncodedQuery = percentEncodedQuery
                request.url = urlComponents.url
            }
        } else {
            if request.value(forHTTPHeaderField: "Content-Type") == nil {
                request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
            }
            
            request.httpBody = query(parameters).data(using: .utf8, allowLossyConversion: false)
        }
        return request
    }
    
    /// 递归转化参数键值对
    ///
    /// - key:      编码值的索引
    /// - value:    编码值（字典、数组、数字、布尔值或字符串）
    public func queryComponents(fromKey key: String, value: Any) -> [(String, String)] {
        var components: [(String, String)] = []
        if let dictionary = value as? [String: Any] {
            for (nestedKey, v) in dictionary {
                components += queryComponents(fromKey: "\(key)[\(nestedKey)]", value: v)
            }
        } else if let array = value as? [Any] {
            for v in array {
                components += queryComponents(fromKey: arrayEncoding.encode(key: key), value: v)
            }
        } else if let number = value as? NSNumber {
            if number.isBool {
                components.append((escape(key), escape(boolEncoding.encode(value: number.boolValue))))
            } else {
                components.append((escape(key), escape("\(number)")))
            }
        } else if let bool = value as? Bool {
            components.append((escape(key), escape(boolEncoding.encode(value: bool))))
        } else {
            components.append((escape(key), escape("\(value)")))
        }
        
        return components
    }
    
    /// 过滤非法字符
    public func escape(_ string: String) -> String {
        
        let generalDelimitersToEncode = ":#[]@"
        let subDelimitersToEncode = "!$&'()*+,;="
        
        let escapeString = filterEscapeString?("\(generalDelimitersToEncode)\(subDelimitersToEncode)") ?? "\(generalDelimitersToEncode)\(subDelimitersToEncode)"
        
        
        var allowedCharacterSet = CharacterSet.urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: escapeString)
        
        var escaped = ""
        
        if #available(iOS 8.3, *) {
            escaped = string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? string
        } else {
            let batchSize = 50
            var index = string.startIndex
            
            while index != string.endIndex {
                let startIndex = index
                let endIndex = string.index(index, offsetBy: batchSize, limitedBy: string.endIndex) ?? string.endIndex
                let range = startIndex..<endIndex
                
                let substring = string[range]
                
                escaped += substring.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? String(substring)
                
                index = endIndex
            }
        }
        
        return escaped
    }
    
    /// 将参数转化为编码字符串
    private func query(_ parameters: [String: Any]) -> String {
        var components: [(String, String)] = []
        
        for key in parameters.keys.sorted(by: <) {
            let value = parameters[key]!
            components += queryComponents(fromKey: key, value: value)
            
        }
        return components.map{"\($0)=\($1)"}.joined(separator: "&")
        
    }
    
    /// 判断当前采用的编码方式
    private func encodesParametersInURL(with method: HTTPMethod) -> Bool{
        switch destination {
        case .queryString:
            return true
        case .httpBody:
            return false
        default:
            break;
        }
        
        switch method {
        case .get, .head, .delete:
            return true
        default:
            return false
        }
    }
}

extension NSNumber {
    fileprivate var isBool: Bool { return CFBooleanGetTypeID() == CFGetTypeID(self) }
}
