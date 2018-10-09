//
//  Spi.swift
//  Spider
//
//  Created by ios on 2018/9/27.
//  Copyright © 2018 ios. All rights reserved.
//

import Foundation

/// Spi 请求体，包含请求的各种参数
open class Spi {
    
    //MARK: - Properties
    
    public let target: SpiTarget
    public let type: SpiderType
    var parameters: Parameters?
    var features: [SpiFeature]?
    
    //MARK: - Initialization
    public init(_ target: SpiTarget, _ type: SpiderType = .default){
        self.target = target
        self.type = type
        parameters = target.parameters
    }
    
    //MARK: - Setters
    /// 根据 key 设置 Bat 中网络请求参数的值
    @discardableResult
    public func setParameter(_ key: String, _ value: Any) -> Self {
        if parameters == nil {
            parameters = [:]
        }
        parameters!.updateValue(value, forKey: key)
        return self
    }
    
    public subscript(features: SpiFeature...) -> Spi {
        var featuresSet: Set<SpiFeature> = []
        features.forEach{featuresSet.insert($0)}
        self.features = .init(featuresSet)
        return self
    }
    
    /// 设置 Bat 中网络请求参数的值
    @discardableResult
    public func setParameters(_ parameters: Parameters) -> Self {
        self.parameters = parameters
        return self
    }
    
    //MARK: - Getters
    var originalRequest: SpiResult<URLRequest> {
        do {
            var request = try URLRequest(url: target.asURL())
        
            request.allowsCellularAccess = target.allowsCellularAccess
            request.allHTTPHeaderFields = target.headers
            request.httpMethod = target.method.rawValue
            request.timeoutInterval = target.timeoutInterval
            
            features?.forEach{ $0.config(&request) }
            
            let encoder = URLEncoder()
            request = try! encoder.encode(request, parameters: parameters, method: target.method)
            return .success(request)
        } catch {
            return .failure(error)
        }
    }
    
    var session: URLSession {
        return SpiManager.manager.getSession(type, features)
    }
    
    //MARK: - 网络事件操作
    @discardableResult
    public func send() -> SpiDataRequest {
        let request = SpiDataRequest(self)
        if (target.startImmediately) {
            request.resume()
        }
        return request
    }
}

/// Spi 请求的基础类型
///
/// - default: 基础类型
/// - backgound: 后台类型，string 为后台唯一参数
/// - ephemeral: 临时类型
public enum SpiderType: Hashable {
    case `default`
    case background(String)
    case ephemeral
}

/// 实现 SpiderType 的 rawValue
public extension SpiderType {
    var rawValue: String {
        switch self {
        case .default: return "default"
        case .background: return "background"
        case .ephemeral: return "ephemeral"
        }
    }
    
}
