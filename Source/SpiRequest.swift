//
//  SpiRequest.swift
//  Spider
//
//  Created by ios on 2018/9/27.
//  Copyright © 2018 ios. All rights reserved.
//

import Foundation

open class SpiRequest {
    
    open internal(set) var spi: Spi!
    open var session: URLSession { return spi.session }
    open var originalRequest: URLRequest? { return spi.originalRequest.value }
    open var error: Error?
    open var task: URLSessionTask? { return delegate.task }
    open var request: URLRequest? { return task?.originalRequest }
    open var response: HTTPURLResponse? { return task?.response as? HTTPURLResponse }
    public typealias ProgressHandler = (Progress) -> Void
    
    open internal(set) var delegate: SpiTaskDelegate {
        get {
            taskDelegateLock.lock() ; defer { taskDelegateLock.unlock() }
            return taskDelegate
        }
        set {
            taskDelegateLock.lock() ; defer { taskDelegateLock.unlock() }
            taskDelegate = newValue
        }
    }
    
    private var taskDelegate: SpiTaskDelegate!
    private var taskDelegateLock = NSLock()
    
    var startTime: CFAbsoluteTime?
    var endTime: CFAbsoluteTime?
    
    var validations: [SpiValidation] = []

}

/// 认证
extension SpiRequest {
    
    /// 将HTTP Basic凭据与请求关联.
    ///
    /// - parameter user:        用户.
    /// - parameter password:    密码.
    /// - parameter persistence: URL凭据持久性。 `.ForSession`默认情况下.
    ///
    /// - returns: 请求.
    @discardableResult
    open func authenticate(
        user: String,
        password: String,
        persistence: URLCredential.Persistence = .forSession)
        -> Self
    {
        let credential = URLCredential(user: user, password: password, persistence: persistence)
        return authenticate(usingCredential: credential)
    }
    
    /// 将指定的凭证与请求相关联.
    ///
    /// - parameter credential: 凭据.
    ///
    /// - returns: 请求
    @discardableResult
    open func authenticate(usingCredential credential: URLCredential) -> Self {
        delegate.credential = credential
        return self
    }
    
    /// 返回base64编码的基本身份验证凭据作为授权标头元组.
    ///
    /// - parameter user:     用户.
    /// - parameter password: 密码.
    ///
    /// - returns: 如果编码成功，则具有Authorization标头和凭证值的元组，否则为“nil”.
    open class func authorizationHeader(user: String, password: String) -> (key: String, value: String)? {
        guard let data = "\(user):\(password)".data(using: .utf8) else { return nil }
        
        let credential = data.base64EncodedString(options: [])
        
        return (key: "Authorization", value: "Basic \(credential)")
    }
}

//MARK: - 网络任务操作
extension SpiRequest {
    
    func resume() {
        guard let task = task else { return }
        
        if startTime == nil { startTime = CFAbsoluteTimeGetCurrent()}
        task.resume()
    }
    
    func suspend() {
        guard let task = task else { return }
        task.suspend()
    }
    
    func cancel() {
        guard let task = task else { return }
        task.cancel()
    }
}

/// 数据请求任务
open class SpiDataRequest: SpiRequest {
    
    open var progress: Progress { return dataDelegate.progress }
    var dataDelegate: SpiDataTaskDelegate { return delegate as! SpiDataTaskDelegate }
    
    init(_ spi: Spi) {
        super.init()
        self.spi = spi
        var task: URLSessionTask?
        if let request = spi.originalRequest.value {
            task = spi.session.dataTask(with: request)
        }
        if let task = task {
            SpiManager.manager.delegate[task] = self
        }
        delegate = SpiDataTaskDelegate(task: task)
        delegate.error = spi.originalRequest.error
    }
    
    @discardableResult
    open func stream(closure: ((Data) -> Void)? = nil) -> Self {
        dataDelegate.dataStream = closure
        return self
    }
    
    @discardableResult
    open func downloadProgress(queue: DispatchQueue = DispatchQueue.main, closure: @escaping ProgressHandler) -> Self {
        dataDelegate.progressHandler = (closure, queue)
        return self
    }
    
}

open class SpiDownloadRequest: SpiRequest {
    
    public struct DownloadOptions: OptionSet {
        public let rawValue: UInt
        public static let createIntermediateDirectories = DownloadOptions(rawValue: 1 << 0)
        public static let removePreviousFile = DownloadOptions(rawValue: 1 << 1)
        
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
    }
    
    public typealias DownloadFileDestination = (
        _ temporaryURL: URL,
        _ response: HTTPURLResponse)
        -> (destinationURL: URL, options: DownloadOptions)
    
}


