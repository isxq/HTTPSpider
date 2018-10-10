//
//  SpiManager.swift
//  Spider
//
//  Created by ios on 2018/9/27.
//  Copyright © 2018 ios. All rights reserved.
//

import Foundation

/// Session 管理
open class SpiManager {
    
    // MARK: - 统一设置
    public struct config {
        public static var baseURL: String?
        public static var httpHeaders: HTTPHeaders?
        public static var startImmediately: Bool?
        public static var allowsCellucerAccess: Bool?
        public static var timeoutInterval: TimeInterval?
        public static var encoderType: SpiEncoderType?
        
        /// 静态方法，设置 Bat 全局配置
        public static func setConfig(baseURL: String = "",
                                     httpHeaders: HTTPHeaders? = nil,
                                     startImmediately: Bool = true,
                                     allowsCellucerAccess: Bool = true,
                                     timeoutInterval: TimeInterval = 60,
                                     encoderType: SpiEncoderType = .url) {
            self.baseURL = baseURL
            self.httpHeaders = httpHeaders
            self.startImmediately = startImmediately
            self.allowsCellucerAccess = allowsCellucerAccess
            self.timeoutInterval = timeoutInterval
            self.encoderType = encoderType
        }
    }
    
    // MARK: -
    /// session 管理单例
    public static let manager = SpiManager ()
    
    // MARK: -
    /// session 集合
    open var sessionPool: [String: URLSession] = [:]
    open var urlCache: URLCache = URLCache(memoryCapacity: 1024 * 1024 * 50,
                                           diskCapacity: 1024 * 1024 * 50, diskPath: nil)
    public let delegate: SpiSessionDelegate = SpiSessionDelegate()
    
    //MARK: - Initialization
    
    init() {}
    
    /// 从 Session Pool 中获取 session 对象
    ///
    /// - Parameters:
    ///     - type: 请求基础类型
    ///     - features: 请求附加功能
    /// - Returns: URLSession 实例
    func getSession(_ type: SpiderType, _ features: [SpiFeature]?) -> URLSession {
        let key = getKey(type, features)
        if let session = sessionPool[key] {
            return session
        }
        let config = createConfiguration(type, features)
        let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        sessionPool.updateValue(session, forKey: key)
        return session
    }
    
    /// 根据类型生成 Key 值
    ///
    /// - Parameters:
    ///     - type: 请求基础类型
    ///     - features: 请求附加功能
    /// - Returns: 生成的设置描述 key 值
    func getKey(_ type: SpiderType, _ features: [SpiFeature]?) -> String {
        let typeValue = type.rawValue
        let features = features?.map{$0.featureValue}.sorted(by: <)
        let featureValue = features?.joined(separator: "_")
        return "\(typeValue)\((featureValue != nil) ? "_\(featureValue!)" : ""))"
    }
    
    /// 根据类型创建网络配置
    ///
    /// - Parameters:
    ///     - type: 请求基础类型
    ///     - features: 请求附加功能
    /// - Returns: 生成的会话配置实例
    func createConfiguration(_ type: SpiderType, _ features: [SpiFeature]?) -> URLSessionConfiguration {
        var configuration: URLSessionConfiguration!
        
        switch type {
        case .default:
            configuration = URLSessionConfiguration.default
        case .background(let identifire):
            configuration = URLSessionConfiguration.background(withIdentifier: identifire)
        case .ephemeral:
            configuration = URLSessionConfiguration.ephemeral
        }
        features?.forEach{ $0.config(&configuration) }
        return configuration
        
    }
    
}
