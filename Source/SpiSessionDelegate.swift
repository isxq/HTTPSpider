//
//  SpiSessionDelegate.swift
//  Spider
//
//  Created by ios on 2018/9/29.
//  Copyright © 2018 ios. All rights reserved.
//

import Foundation

open class SpiSessionDelegate: NSObject {
    
    //MARK: - Properties
    
    weak var sessionManager: SpiManager?
    
    var requests: [Int: SpiRequest] = [:]
    
    private let lock = NSLock()
    
    /// 建立线程安全的 task - SpiRequest 映射关系
    open subscript(task: URLSessionTask) -> SpiRequest? {
        get {
            lock.lock() ; defer { lock.unlock() }
            return requests[task.taskIdentifier]
        }
        set {
            lock.lock() ; defer { lock.unlock() }
            requests[task.taskIdentifier] = newValue
        }
    }
    
    //MARK: - Delegates Overrides Properties
    open var sessionEvents: SpiSessionDelegateEvents!
    open var taskEvents: SpiSessionTaskDelegateEvents!
    open var dataEvents: SpiSessionDataDelegateEvents!
    open var downloadEvents: SpiSessionDownloadDelegateEvents!
    open var streamEvents: SpiSessionStreamDelegateEvents!
    
    // MARK: Initialization
    
    public override init() {
        super.init()
        sessionEvents = SpiSessionDelegateEvents()
        taskEvents = SpiSessionTaskDelegateEvents()
        dataEvents = SpiSessionDataDelegateEvents()
        downloadEvents = SpiSessionDownloadDelegateEvents()
        streamEvents = SpiSessionStreamDelegateEvents()
    }
    
    /// 完成 delegate 方法消息分发
    override open func responds(to aSelector: Selector!) -> Bool {
        #if !os(macOS)
        if aSelector == #selector(URLSessionDelegate.urlSessionDidFinishEvents(forBackgroundURLSession:)) {
            return sessionEvents.sessionDidFinishEventsForBackgroundURLSession != nil
        }
        #endif
        
        #if !os(watchOS)
        if #available(iOS 9.0, macOS 10.11, tvOS 9.0, *) {
            switch aSelector {
            case #selector(URLSessionStreamDelegate.urlSession(_:readClosedFor:)):
                return streamEvents.streamTaskReadClosed != nil
            case #selector(URLSessionStreamDelegate.urlSession(_:writeClosedFor:)):
                return streamEvents.streamTaskWriteClosed != nil
            case #selector(URLSessionStreamDelegate.urlSession(_:betterRouteDiscoveredFor:)):
                return streamEvents.streamTaskBetterRouteDiscovered != nil
            case #selector(URLSessionStreamDelegate.urlSession(_:streamTask:didBecome:outputStream:)):
                return streamEvents.streamTaskDidBecomeInputAndOutputStreams != nil
            default:
                break
            }
        }
        #endif
        
        switch aSelector {
        case #selector(URLSessionDelegate.urlSession(_:didBecomeInvalidWithError:)):
            return sessionEvents.sessionDidBecomeInvalidWithError != nil
        case #selector(URLSessionDelegate.urlSession(_:didReceive:completionHandler:)):
            return (sessionEvents.sessionDidReceiveChallenge != nil  || sessionEvents.sessionDidReceiveChallengeWithCompletion != nil)
        case #selector(URLSessionTaskDelegate.urlSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:)):
            return (taskEvents.taskWillPerformHTTPRedirection != nil || taskEvents.taskWillPerformHTTPRedirectionWithCompletion != nil)
        case #selector(URLSessionDataDelegate.urlSession(_:dataTask:didReceive:completionHandler:)):
            return (dataEvents.dataTaskDidReceiveResponse != nil || dataEvents.dataTaskDidReceiveResponseWithCompletion != nil)
        default:
            return type(of: self).instancesRespond(to: aSelector)
        }
    }
}

// MARK: - URLSessionDelegate
extension SpiSessionDelegate: URLSessionDelegate {
    
    /// 告诉当前代理，会话已不可用
    ///
    /// - parameter session: 当前不可用的会话
    /// - parameter error: 导致不可用的原因，当原因很明确时为nil
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        sessionEvents.sessionDidBecomeInvalidWithError?(session, error)
    }
    
    /// 从当前代理获取凭据以响应来自远程服务器的会话级身份验证请求
    ///
    /// - parameter session: 请求身份验证的会话
    /// - parameter callenge: 身份验证请求对象
    /// - parameter completionHandler: 委托方法必须调用的处理程序，提供处置和证件。
    private func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard sessionEvents.sessionDidReceiveChallengeWithCompletion == nil else {
            sessionEvents.sessionDidReceiveChallengeWithCompletion?(session, challenge, completionHandler)
            return
        }
        
        var disposition: URLSession.AuthChallengeDisposition = .performDefaultHandling
        var credential: URLCredential?
        
        if let sessionDidReceiveChallenge = sessionEvents.sessionDidReceiveChallenge {
            (disposition, credential) = sessionDidReceiveChallenge(session, challenge)
        } else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            let host = challenge.protectionSpace.host
            
            if let serverTrustPolicy = session.serverTrustPolicyManager?.serverTrustPolicy(forHost: host),
                let serverTrust = challenge.protectionSpace.serverTrust {
                if serverTrustPolicy.evaluate(serverTrust, forHost: host){
                    disposition = .useCredential
                    credential = URLCredential(trust: serverTrust)
                } else {
                    disposition = .cancelAuthenticationChallenge
                }
            }
        }
        completionHandler(disposition, credential)
    }
    
    #if !os(macOS)
    /// 告诉当前代理，会话中所有请求均已完成
    ///
    /// - parameter session: 已完成所有请求的会话
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        sessionEvents.sessionDidFinishEventsForBackgroundURLSession?(session)
    }
    #endif
    
}

// MARK: - URLSessionTaskDelegate
extension SpiSessionDelegate: URLSessionTaskDelegate {
    
    /// 告诉当前代理，远程服务器请求 HTTP 重定向
    ///
    /// - parameter session: 包含请求导致重定向的任务的会话
    /// - parameter task: 请求导致重定向的任务
    /// - parameter response: 包含服务器对原始请求的响应的对象
    /// - parameter request: 使用新位置填写的URL请求对象
    /// - parameter completionHandler: 一个闭包，你的处理程序应该使用原请求，一个修改过的URL请求对象或NULL来调用，以拒绝重定向或返回重定向响应的主体。
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        guard taskEvents.taskWillPerformHTTPRedirectionWithCompletion == nil else {
            taskEvents.taskWillPerformHTTPRedirectionWithCompletion?(session, task, response, request, completionHandler)
            return
        }
        
        var redirectionRequest: URLRequest? = request
        if let taskWillPerformHTTPRedirection = taskEvents.taskWillPerformHTTPRedirection {
            redirectionRequest = taskWillPerformHTTPRedirection(session, task, response, request)
        }
        completionHandler(redirectionRequest)
    }
    
    /// 响应来自远程服务器的身份验证请求，从委托请求凭据。
    ///
    /// - parameter session: 包含请求需要认证的任务的会话。
    /// - parameter task: 其请求需要身份验证的任务。
    /// - parameter challenge: 包含身份验证请求的对象。
    /// - parameter completionHandler: 委托方法必须调用的处理程序，提供处置和凭证。
    open func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        // 执行任务代理
        if let delegate = self[task]?.delegate {
            delegate.urlSession(
                session,
                task: task,
                didReceive: challenge,
                completionHandler: completionHandler
            )
        }
        
        // 执行会话回调
        guard taskEvents.taskDidReceiveChallengeWithCompletion == nil else {
            taskEvents.taskDidReceiveChallengeWithCompletion?(session, task, challenge, completionHandler)
            return
        }
        if let taskDidReceiveChallenge = taskEvents.taskDidReceiveChallenge {
            let result = taskDidReceiveChallenge(session, task, challenge)
            completionHandler(result.0, result.1)
        } else {
            urlSession(session, didReceive: challenge, completionHandler: completionHandler)
        }
    }
    
    /// 当任务需要新的请求正文流发送到远程服务器时，告知委托
    ///
    /// - parameter session: 包含需要新主体流的任务的会话
    /// - parameter task: 需要新体流的任务
    /// - parameter completionHandler: 完成处理程序
    open func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        needNewBodyStream completionHandler: @escaping (InputStream?) -> Void)
    {
        // 执行任务代理
        if let delegate = self[task]?.delegate {
            delegate.urlSession(session, task: task, needNewBodyStream: completionHandler)
        }
        
        // 执行会话回调
        guard taskEvents.taskNeedNewBodyStreamWithCompletion == nil else {
            taskEvents.taskNeedNewBodyStreamWithCompletion?(session, task, completionHandler)
            return
        }
        
        if let taskNeedNewBodyStream = taskEvents.taskNeedNewBodyStream {
            completionHandler(taskNeedNewBodyStream(session, task))
        }
    }
    
    /// 定期通知代理将正文内容发送到服务器的进度。
    ///
    /// - parameter session: 包含数据任务的会话
    /// - parameter task:   数据任务
    /// - parameter bytesSent:  自上次调用此委托方法以来发送的字节数
    /// - parameter totalBytesSent:     到目前为止发送的总字节数
    /// - parameter totalBytesExpectedToSend: 正文数据的预期长度
    open func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64)
    {
        //  执行任务代理
        if let delegate = self[task]?.delegate as? SpiUploadTaskDelegate {
            delegate.URLSession(
                session,
                task: task,
                didSendBodyData: bytesSent,
                totalBytesSent: totalBytesSent,
                totalBytesExpectedToSend: totalBytesExpectedToSend
            )
        }
        
        // 执行会话回调
        if let taskDidSendBodyData = taskEvents.taskDidSendBodyData {
            taskDidSendBodyData(session, task, bytesSent, totalBytesSent, totalBytesExpectedToSend)
        }
    }
    
    #if !os(watchOS)
    
    /// 告诉委托会话已完成收集任务的指标。
    ///
    /// - parameter session: 收集指标的会话.
    /// - parameter task:    已收集齐指标的任务.
    /// - parameter metrics: 收集的指标.
    @available(iOS 10.0, macOS 10.12, tvOS 10.0, *)
    @objc(URLSession:task:didFinishCollectingMetrics:)
    open func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        self[task]?.delegate.metrics = metrics
    }
    
    #endif
    
    /// 告诉委托数据转化完成
    ///
    /// - parameter session: 相关的会话
    /// - parameter task: 完成数据转化的任务
    /// - parameter error: 如果发生错误，则表示传输失败的错误对象，否则为nil
    open func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        let complete: (URLSession, URLSessionTask, Error?) -> Void = {
            [weak self] session, task, error in
            guard let self = self else { return }
            defer { self[task] = nil }
            self.taskEvents.taskDidComplete?(session, task, error)
            self[task]?.delegate.urlSession(session, task: task, didCompleteWithError: error)
        }
        
        guard let request = self[task] else {
            complete(session, task, error)
            return
        }
        
        request.validations.forEach{ $0.validate() }
        
        var error: Error? = error
        
        if request.delegate.error != nil {
            error = request.delegate.error
        }
        
        complete(session, task, error)
    }
}

// MARK: - URLSessionDataDelegate
extension SpiSessionDelegate: URLSessionDataDelegate {
    
    /// 数据任务从服务器接受到初始化回复（header）
    ///
    /// - parameter session: 包含接收初始回复的数据任务的会话
    /// - parameter dataTask: 接收初始回复的数据任务
    /// - parameter response: 用 header 填充的URL响应对象
    /// - parameter completionHandler: 代码调用以继续传输的完成处理程序，传递一个常量来指示传输是继续作为数据任务还是应该成为下载任务
    open func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void)
    {
        guard dataEvents.dataTaskDidReceiveResponseWithCompletion == nil else {
            dataEvents.dataTaskDidReceiveResponseWithCompletion?(session, dataTask, response, completionHandler)
            return
        }
        
        var disposition: URLSession.ResponseDisposition = .allow
        
        if let dataTaskDidReceiveResponse = dataEvents.dataTaskDidReceiveResponse {
            disposition = dataTaskDidReceiveResponse(session, dataTask, response)
        }
        
        completionHandler(disposition)
    }
    
    /// 数据任务转化为下载任务
    ///
    /// - parameter session:      相关会话
    /// - parameter dataTask:     要转化的数据任务.
    /// - parameter downloadTask: 数据任务转化的下载任务.
    open func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didBecome downloadTask: URLSessionDownloadTask)
    {
        if let dataTaskDidBecomeDownloadTask = dataEvents.dataTaskDidBecomeDownloadTask {
            dataTaskDidBecomeDownloadTask(session, dataTask, downloadTask)
        }
        self[downloadTask]?.delegate = SpiDownloadTaskDelegate(task: downloadTask)
    }
    
    /// 接收到预期中的数据
    ///
    /// - parameter session:  相关的会话
    /// - parameter dataTask: 提供数据的数据任务
    /// - parameter data:     包含传输数据的数据对象
    open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let dataTaskDidReceiveData = dataEvents.dataTaskDidReceiveData {
            dataTaskDidReceiveData(session, dataTask, data)
        }
        if let delegate = self[dataTask]?.delegate as? SpiDataTaskDelegate {
            delegate.urlSession(session, dataTask: dataTask, didReceive: data)
        }
    }
    
    /// 数据（或上传）任务是否应将响应存储在缓存中
    ///
    /// - parameter session: 包含数据（或上传）任务的会话
    /// - parameter dataTask: 数据（或上传）任务
    /// - parameter proposedResponse: 默认的缓存行为。此行为基于当前确定缓存策略和某些收到的标头的值，例如Pragma和Cache-Control标头
    /// - parameter completionHandler: 处理程序必须调用的块，提供原始建议响应，该响应的修改版本，或NULL以防止缓存响应。如果您的委托实现此方法，则必须调用此完成处理程序;否则，你的应用程序泄漏内存
    open func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        willCacheResponse proposedResponse: CachedURLResponse,
        completionHandler: @escaping (CachedURLResponse?) -> Void)
    {
        // 执行任务代理
        if let delegate = self[dataTask]?.delegate as? SpiDataTaskDelegate {
            delegate.urlSession(
                session,
                dataTask: dataTask,
                willCacheResponse: proposedResponse,
                completionHandler: completionHandler
            )
        }
        
        // 执行会话回调
        guard dataEvents.dataTaskWillCacheResponseWithCompletion == nil else {
            dataEvents.dataTaskWillCacheResponseWithCompletion?(session, dataTask, proposedResponse, completionHandler)
            return
        }
        
        if let dataTaskWillCacheResponse = dataEvents.dataTaskWillCacheResponse {
            completionHandler(dataTaskWillCacheResponse(session, dataTask, proposedResponse))
        }
        else {
            completionHandler(proposedResponse)
        }
    }
}

// MARK: - URLSessionDownloadDelegate
extension SpiSessionDelegate: URLSessionDownloadDelegate {
   
    /// 下载任务已完成
    ///
    /// - parameter session:      包含已完成下载任务的会话
    /// - parameter downloadTask: 已完成的下载任务
    /// - parameter location:     临时文件的文件URL。由于该文件是临时文件，因此必须先打开文件进行读取，
    ///                           或者在从此委托方法返回之前将其移动到应用程序沙盒容器目录中的永久位置。
    open func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL)
    {
        if let downloadTaskDidFinishDownloadingToURL = downloadEvents.downloadTaskDidFinishDownloadingToURL {
            downloadTaskDidFinishDownloadingToURL(session, downloadTask, location)
        }
        if let delegate = self[downloadTask]?.delegate as? SpiDownloadTaskDelegate {
            delegate.urlSession(session, downloadTask: downloadTask, didFinishDownloadingTo: location)
        }
    }
    
    /// 定期通知代理有关下载进度的信息
    ///
    /// - parameter session:                   包含下载任务的会话.
    /// - parameter downloadTask:              下载任务.
    /// - parameter bytesWritten:              自上次调用此委托方法以来传输的字节数.
    /// - parameter totalBytesWritten:         到目前为止传输的总字节数.
    /// - parameter totalBytesExpectedToWrite: 文件的预期长度，由Content-Length标头提供。如果未提供此标头，
    ///                                        则值为“NSURLSessionTransferSizeUnknown”.
    open func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64)
    {
        if let downloadTaskDidWriteData = downloadEvents.downloadTaskDidWriteData {
            downloadTaskDidWriteData(session, downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
        }
        if let delegate = self[downloadTask]?.delegate as? SpiDownloadTaskDelegate {
            delegate.urlSession(
                session,
                downloadTask: downloadTask,
                didWriteData: bytesWritten,
                totalBytesWritten: totalBytesWritten,
                totalBytesExpectedToWrite: totalBytesExpectedToWrite
            )
        }
    }
    
    /// 断点续传.
    ///
    /// - parameter session:            包含已完成的下载任务的会话.
    /// - parameter downloadTask:       恢复的下载任务。
    /// - parameter fileOffset:         如果文件的缓存策略或上次修改日期阻止重用现有内容，则此值为零。
    ///                                 否则，此值是一个整数，表示磁盘上不需要再次检索的字节数。
    /// - parameter expectedTotalBytes: 文件的预期长度，由Content-Length标头提供。
    ///                                 如果未提供此标头，则值为 NSURLSessionTransferSizeUnknown。
    open func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didResumeAtOffset fileOffset: Int64,
        expectedTotalBytes: Int64)
    {
        if let downloadTaskDidResumeAtOffset = downloadEvents.downloadTaskDidResumeAtOffset {
            downloadTaskDidResumeAtOffset(session, downloadTask, fileOffset, expectedTotalBytes)
        }
        if let delegate = self[downloadTask]?.delegate as? SpiDownloadTaskDelegate {
            delegate.urlSession(
                session,
                downloadTask: downloadTask,
                didResumeAtOffset: fileOffset,
                expectedTotalBytes: expectedTotalBytes
            )
        }
    }
    
}

// MARK: - URLSessionStreamDelegate
#if !os(watchOS)

@available(iOS 9.0, macOS 10.11, tvOS 9.0, *)
extension SpiSessionDelegate: URLSessionStreamDelegate {
    
    /// 读取端已关闭
    ///
    /// - parameter session:    会话.
    /// - parameter streamTask: 流任务.
    open func urlSession(_ session: URLSession, readClosedFor streamTask: URLSessionStreamTask) {
        streamEvents.streamTaskReadClosed?(session, streamTask)
    }
    
    /// 写入端已关闭.
    ///
    /// - parameter session:    会话.
    /// - parameter streamTask: 流任务.
    open func urlSession(_ session: URLSession, writeClosedFor streamTask: URLSessionStreamTask) {
        streamEvents.streamTaskWriteClosed?(session, streamTask)
    }
    
    /// 发现了更好的主机路由.
    ///
    /// - parameter session:    会话.
    /// - parameter streamTask: 流任务.
    open func urlSession(_ session: URLSession, betterRouteDiscoveredFor streamTask: URLSessionStreamTask) {
        streamEvents.streamTaskBetterRouteDiscovered?(session, streamTask)
    }
    
    /// 任务完成.
    ///
    /// - parameter session:      会话.
    /// - parameter streamTask:   流任务.
    /// - parameter inputStream:  输入流.
    /// - parameter outputStream: 输出流.
    open func urlSession(
        _ session: URLSession,
        streamTask: URLSessionStreamTask,
        didBecome inputStream: InputStream,
        outputStream: OutputStream)
    {
        streamEvents.streamTaskDidBecomeInputAndOutputStreams?(session, streamTask, inputStream, outputStream)
    }
}
#endif
