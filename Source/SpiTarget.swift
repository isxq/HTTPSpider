//
//  SpiTarget.swift
//  Spider
//
//  Created by ios on 2018/9/26.
//  Copyright © 2018 ios. All rights reserved.
//

import Foundation

/// SpiderTarget 是 Spider 发出网络请求的配置规则
public protocol SpiTarget {
    /// 发出网络请求的基础地址字符串，默认返回 Spider 中配置的静态变量
    var baseURL: String {get}
    
    /// 网络请求的路径字符串
    var path: String {get}
    
    /// 网络请求的方式，默认返回get
    var method: HTTPMethod {get}
    
    /// 网络请求参数
    var parameters: Parameters? {get}
    
    /// 网络请求头，默认返回 nil
    var headers: HTTPHeaders? {get}
    
    /// 网络请求超时时间，默认返回 Bat 中配置的静态变量
    var timeoutInterval: TimeInterval {get}
    
    /// 是否允许蜂窝数据网络连接，默认返回 Bat 中配置的静态变量
    var allowsCellularAccess: Bool {get}
    
    /// 生成请求后是否立即进行请求，默认返回 Bat 中配置的静态变量
    var startImmediately: Bool {get}
}

//MARK: - extensions

extension SpiTarget {
    public var baseURL: String {
        return SpiManager.config.baseURL ?? ""
    }
    
    public var headers: HTTPHeaders? {
        return SpiManager.config.httpHeaders
    }
    
    public var timeoutInterval: TimeInterval {
        return SpiManager.config.timeoutInterval ?? 60.0
    }
    
    public var allowsCellularAccess: Bool {
        return SpiManager.config.allowsCellucerAccess ?? true
    }
    
    public var startImmediately: Bool {
        return SpiManager.config.startImmediately ?? true
    }
}

extension SpiTarget{
    /// 根据当前配置生成 URL
    ///
    /// return:
    /// - URL:  拼接 baseURL 及 path 生成的 url
    /// - BatError: bathURL 或 path 不符合规则
    func asURL() throws -> URL {
        if var url = URL(string: baseURL){
            url.appendPathComponent(path)
            return url
        } else {
            throw SpiError.invalidURL(baseURL: baseURL, path: path)
        }
    }
}

//MARK: -

/// HTTP 请求头 字典
public typealias HTTPHeaders = [String: String]

/// HTTP 请求参数 字典
public typealias Parameters = [String: Any]

/// HTTP 请求方法
///
/// 具体描述见 https://tools.ietf.org/html/rfc7231#section-4.3
public enum HTTPMethod: String {
    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
}
