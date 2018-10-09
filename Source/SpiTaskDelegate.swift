//
//  SpiTaskDelegate.swift
//  Spider
//
//  Created by ios on 2018/9/30.
//  Copyright © 2018 ios. All rights reserved.
//

import Foundation

open class SpiTaskDelegate: NSObject {
    
    public let queue: OperationQueue
    public var data: Data? { return nil }
    public var error: Error?
    
    var task: URLSessionTask?{
        set {
            taskLock.lock(); defer { taskLock.unlock() }
            _task = newValue
        }
        get {
            taskLock.lock(); defer { taskLock.unlock() }
            return _task
        }
    }
    
    private var _task: URLSessionTask?{ didSet { reset() } }
    private let taskLock = NSLock()
    
    var initialResponseTime: CFAbsoluteTime?
    var metrics: AnyObject?
    var credential: URLCredential?
    
    public var taskEvents: SpiSessionTaskDelegateEvents!
    
    init(task: URLSessionTask?) {
        _task = task
        queue = {
            let operationQueue = OperationQueue()
            operationQueue.maxConcurrentOperationCount = 1
            operationQueue.isSuspended = true
            operationQueue.qualityOfService = .utility
            return operationQueue
        }()
        taskEvents = SpiSessionTaskDelegateEvents()
    }
    
    func reset() {
        error = nil
        initialResponseTime = nil
    }
}

// MARK: 任务代理事件处理
extension SpiTaskDelegate {
    
    @objc(URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:)
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void)
    {
        var redirectRequest: URLRequest? = request
        
        if let taskWillPerformHTTPRedirection = taskEvents.taskWillPerformHTTPRedirection {
            redirectRequest = taskWillPerformHTTPRedirection(session, task, response, request)
        }
        
        completionHandler(redirectRequest)
    }
    
    @objc(URLSession:task:didReceiveChallenge:completionHandler:)
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        var disposition: URLSession.AuthChallengeDisposition = .performDefaultHandling
        var credential: URLCredential?
        
        if let taskDidReceiveChallenge = taskEvents.taskDidReceiveChallenge {
            (disposition, credential) = taskDidReceiveChallenge(session, task, challenge)
        } else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            let host = challenge.protectionSpace.host
            
            if
                let serverTrustPolicy = session.serverTrustPolicyManager?.serverTrustPolicy(forHost: host),
                let serverTrust = challenge.protectionSpace.serverTrust
            {
                if serverTrustPolicy.evaluate(serverTrust, forHost: host) {
                    disposition = .useCredential
                    credential = URLCredential(trust: serverTrust)
                } else {
                    disposition = .cancelAuthenticationChallenge
                }
            }
        } else {
            if challenge.previousFailureCount > 0 {
                disposition = .rejectProtectionSpace
            } else {
                credential = self.credential ?? session.configuration.urlCredentialStorage?.defaultCredential(for: challenge.protectionSpace)
                
                if credential != nil {
                    disposition = .useCredential
                }
            }
        }
        
        completionHandler(disposition, credential)
    }
    
    @objc(URLSession:task:needNewBodyStream:)
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        needNewBodyStream completionHandler: @escaping (InputStream?) -> Void)
    {
        var bodyStream: InputStream?
        
        if let taskNeedNewBodyStream = taskEvents.taskNeedNewBodyStream {
            bodyStream = taskNeedNewBodyStream(session, task)
        }
        
        completionHandler(bodyStream)
    }
    
    @objc(URLSession:task:didCompleteWithError:)
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let taskDidComplete = taskEvents.taskDidComplete {
            taskDidComplete(session, task, error)
        }
        else {
            if let error = error {
                if self.error == nil { self.error = error }
                if
                    let downloadDelegate = self as? SpiDownloadTaskDelegate,
                    let resumeData = (error as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data
                {
                    downloadDelegate.resumeData = resumeData
                }
            }
            queue.isSuspended = false
        }
    }
}

// MARK: - DataTaskDelegate

open class SpiDataTaskDelegate: SpiTaskDelegate {
    
    var dataTask: URLSessionDataTask { return task as! URLSessionDataTask }
    
    override public var data: Data? {
        return dataStream != nil ? nil : mutableData
    }
    
    var progress: Progress
    var progressHandler: (closure: SpiRequest.ProgressHandler, queue: DispatchQueue)?
    var dataStream: ((_ data: Data) -> Void)?
    
    var dataEvents: SpiSessionDataDelegateEvents!
    
    private var totalBytesReceived: Int64 = 0
    private var mutableData: Data
    private var expectedContentLength: Int64?
    
    override init(task: URLSessionTask?) {
        mutableData = Data()
        progress = Progress(totalUnitCount: 0)
        dataEvents = SpiSessionDataDelegateEvents()
        super.init(task: task)
    }
    
    override func reset() {
        super.reset()
        totalBytesReceived = 0
        mutableData = Data()
        expectedContentLength = nil
    }
}

// MARK: 数据任务代理事件处理
extension SpiDataTaskDelegate: URLSessionDataDelegate {
    
    public func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void)
    {
        var disposition: URLSession.ResponseDisposition = .allow
        
        expectedContentLength = response.expectedContentLength
        
        if let dataTaskDidReceiveResponse = dataEvents.dataTaskDidReceiveResponse {
            disposition = dataTaskDidReceiveResponse(session, dataTask, response)
        }
        
        completionHandler(disposition)
    }
    
    public func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didBecome downloadTask: URLSessionDownloadTask)
    {
        dataEvents.dataTaskDidBecomeDownloadTask?(session, dataTask, downloadTask)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if initialResponseTime == nil { initialResponseTime = CFAbsoluteTimeGetCurrent() }
        
        if let dataTaskDidReceiveData = dataEvents.dataTaskDidReceiveData {
            dataTaskDidReceiveData(session, dataTask, data)
        } else {
            if let dataStream = dataStream {
                dataStream(data)
            } else {
                mutableData.append(data)
            }
            
            let bytesReceived = Int64(data.count)
            totalBytesReceived += bytesReceived
            let totalBytesExpected = dataTask.response?.expectedContentLength ?? NSURLSessionTransferSizeUnknown
            
            progress.totalUnitCount = totalBytesExpected
            progress.completedUnitCount = totalBytesReceived
            
            if let progressHandler = progressHandler {
                progressHandler.queue.async { progressHandler.closure(self.progress) }
            }
        }
    }
    
    public func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        willCacheResponse proposedResponse: CachedURLResponse,
        completionHandler: @escaping (CachedURLResponse?) -> Void)
    {
        var cachedResponse: CachedURLResponse? = proposedResponse
        
        if let dataTaskWillCacheResponse = dataEvents.dataTaskWillCacheResponse {
            cachedResponse = dataTaskWillCacheResponse(session, dataTask, proposedResponse)
        }
        
        completionHandler(cachedResponse)
    }
}

// MARK: - DownloadTaskDelegate

open class SpiDownloadTaskDelegate: SpiTaskDelegate {
    
    // MARK: Properties
    
    var downloadTask: URLSessionDownloadTask { return task as! URLSessionDownloadTask }
    
    var progress: Progress
    var progressHandler: (closure: SpiRequest.ProgressHandler, queue: DispatchQueue)?
    
    var resumeData: Data?
    override public var data: Data? { return resumeData }
    
    var destination: SpiDownloadRequest.DownloadFileDestination?
    
    var temporaryURL: URL?
    var destinationURL: URL?
    
    var fileURL: URL? { return temporaryURL }
    
    public var downloadEvents: SpiSessionDownloadDelegateEvents!
    
    // MARK: Lifecycle
    
    override init(task: URLSessionTask?) {
        downloadEvents = SpiSessionDownloadDelegateEvents()
        progress = Progress(totalUnitCount: 0)
        super.init(task: task)
    }
    
    override func reset() {
        super.reset()
        
        progress = Progress(totalUnitCount: 0)
        resumeData = nil
    }
}

// MARK: 下载任务代理事件处理
extension SpiDownloadTaskDelegate: URLSessionDownloadDelegate {
    
    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL)
    {
        temporaryURL = location
        
        guard
            let destination = destination,
            let response = downloadTask.response as? HTTPURLResponse
            else { return }
        
        let result = destination(location, response)
        let destinationURL = result.destinationURL
        let options = result.options
        
        self.destinationURL = destinationURL
        
        do {
            if options.contains(.removePreviousFile), FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            if options.contains(.createIntermediateDirectories) {
                let directory = destinationURL.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            }
            
            try FileManager.default.moveItem(at: location, to: destinationURL)
        } catch {
            self.error = error
        }
    }
    
    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64)
    {
        if initialResponseTime == nil { initialResponseTime = CFAbsoluteTimeGetCurrent() }
        
        if let downloadTaskDidWriteData = downloadEvents.downloadTaskDidWriteData {
            downloadTaskDidWriteData(
                session,
                downloadTask,
                bytesWritten,
                totalBytesWritten,
                totalBytesExpectedToWrite
            )
        } else {
            progress.totalUnitCount = totalBytesExpectedToWrite
            progress.completedUnitCount = totalBytesWritten
            
            if let progressHandler = progressHandler {
                progressHandler.queue.async { progressHandler.closure(self.progress) }
            }
        }
    }
    
    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didResumeAtOffset fileOffset: Int64,
        expectedTotalBytes: Int64)
    {
        if let downloadTaskDidResumeAtOffset = downloadEvents.downloadTaskDidResumeAtOffset {
            downloadTaskDidResumeAtOffset(session, downloadTask, fileOffset, expectedTotalBytes)
        } else {
            progress.totalUnitCount = expectedTotalBytes
            progress.completedUnitCount = fileOffset
        }
    }
}

open class SpiUploadTaskDelegate: SpiTaskDelegate {
    // MARK: Properties
    
    var uploadTask: URLSessionUploadTask { return task as! URLSessionUploadTask }
    
    var uploadProgress: Progress
    var uploadProgressHandler: (closure: SpiRequest.ProgressHandler, queue: DispatchQueue)?
    
    // MARK: Lifecycle
    
    override init(task: URLSessionTask?) {
        uploadProgress = Progress(totalUnitCount: 0)
        super.init(task: task)
    }
    
    override func reset() {
        super.reset()
        uploadProgress = Progress(totalUnitCount: 0)
    }
    
    // MARK: URLSessionTaskDelegate
    
    var taskDidSendBodyData: ((URLSession, URLSessionTask, Int64, Int64, Int64) -> Void)?
    
    func URLSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64)
    {
        if initialResponseTime == nil { initialResponseTime = CFAbsoluteTimeGetCurrent() }
        
        if let taskDidSendBodyData = taskDidSendBodyData {
            taskDidSendBodyData(session, task, bytesSent, totalBytesSent, totalBytesExpectedToSend)
        } else {
            uploadProgress.totalUnitCount = totalBytesExpectedToSend
            uploadProgress.completedUnitCount = totalBytesSent
            
            if let uploadProgressHandler = uploadProgressHandler {
                uploadProgressHandler.queue.async { uploadProgressHandler.closure(self.uploadProgress) }
            }
        }
    }
}
