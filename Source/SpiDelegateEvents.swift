//
//  SpiDelegateEvents.swift
//  Spider
//
//  Created by ios on 2018/9/30.
//  Copyright © 2018 ios. All rights reserved.
//

import Foundation

/// URLSessionDelegate Overrides
public struct SpiSessionDelegateEvents {
    
    /// 告诉当前代理，会话已不可用
    ///
    /// `urlSession(_:didBecomeInvalidWithError:)`
    public var sessionDidBecomeInvalidWithError: ((URLSession, Error?) -> Void)?
    
    /// 从当前代理获取凭据以响应来自远程服务器的会话级身份验证请求
    ///
    /// `urlSession(_:didReceive:completionHandler:)`
    public var sessionDidReceiveChallenge: ((URLSession, URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?))?
    
    /// 从当前代理获取凭据以响应来自远程服务器的会话级身份验证请求, 需调用完成回调
    ///
    /// `urlSession(_:didReceive:completionHandler:)`
    public var sessionDidReceiveChallengeWithCompletion: ((URLSession, URLAuthenticationChallenge, @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Void)?
    
    /// 告诉当前代理，会话中所有请求均已完成
    ///
    /// `urlSessionDidFinishEvents(forBackgroundURLSession:)`
    public var sessionDidFinishEventsForBackgroundURLSession: ((URLSession) -> Void)?
    
}

/// URLSessionTaskDelegate Overrides
public struct SpiSessionTaskDelegateEvents {
    /// 告诉当前代理，远程服务器请求 HTTP 重定向
    ///
    ///  `urlSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:)`
    public var taskWillPerformHTTPRedirection: ((URLSession, URLSessionTask, HTTPURLResponse, URLRequest) -> URLRequest?)?
    /// 告诉当前代理，远程服务器请求 HTTP 重定向，需要调用完成回调。
    ///
    ///  `urlSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:)`
    public var taskWillPerformHTTPRedirectionWithCompletion: ((URLSession, URLSessionTask, HTTPURLResponse, URLRequest, @escaping (URLRequest?) -> Void) -> Void)?
    
    /// 响应来自远程服务器的身份验证请求，从委托请求凭据。
    ///
    /// `urlSession(_:task:didReceive:completionHandler:)`
    public var taskDidReceiveChallenge: ((URLSession, URLSessionTask, URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?))?
    /// 响应来自远程服务器的身份验证请求，从委托请求凭据。需调用完成回调。
    ///
    /// `urlSession(_:task:didReceive:completionHandler:)`
    public var taskDidReceiveChallengeWithCompletion: ((URLSession, URLSessionTask, URLAuthenticationChallenge, @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Void)?
    
    /// 从委托请求发送数据
    ///
    /// `urlSession(_:task:needNewBodyStream:)`
    public var taskNeedNewBodyStream: ((URLSession, URLSessionTask) -> InputStream?)?
    /// 从委托请求发送数据，需完成回调
    ///
    /// `urlSession(_:task:needNewBodyStream:)`
    public var taskNeedNewBodyStreamWithCompletion: ((URLSession, URLSessionTask, @escaping (InputStream?) -> Void) -> Void)?
    
    /// 内容发送进度
    ///
    /// `urlSession(_:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:)`
    public var taskDidSendBodyData: ((URLSession, URLSessionTask, Int64, Int64, Int64) -> Void)?
    
    /// 数据转化完成
    ///
    /// `urlSession(_:task:didCompleteWithError:)`
    public var taskDidComplete: ((URLSession, URLSessionTask, Error?) -> Void)?
}

/// URLSessionDataDelegate Overrides
public struct SpiSessionDataDelegateEvents {
    /// 初始化回复
    ///
    /// `urlSession(_:dataTask:didReceive:completionHandler:)`
    public var dataTaskDidReceiveResponse: ((URLSession, URLSessionDataTask, URLResponse) -> URLSession.ResponseDisposition)?
    /// 初始化回复，需调用完成回调
    ///
    /// `urlSession(_:dataTask:didReceive:completionHandler:)`
    public var dataTaskDidReceiveResponseWithCompletion: ((URLSession, URLSessionDataTask, URLResponse, @escaping (URLSession.ResponseDisposition) -> Void) -> Void)?
    
    /// 转化为下载任务
    ///
    /// `urlSession(_:dataTask:didBecome:)`
    public var dataTaskDidBecomeDownloadTask: ((URLSession, URLSessionDataTask, URLSessionDownloadTask) -> Void)?
    
    /// 接收到响应数据
    ///
    /// `urlSession(_:dataTask:didReceive:)`
    public var dataTaskDidReceiveData: ((URLSession, URLSessionDataTask, Data) -> Void)?
    
    /// 是否缓存响应
    ///
    /// `urlSession(_:dataTask:willCacheResponse:completionHandler:)`
    public var dataTaskWillCacheResponse: ((URLSession, URLSessionDataTask, CachedURLResponse) -> CachedURLResponse?)?
    /// 是否缓存响应，需调用完成回调
    ///
    /// `urlSession(_:dataTask:willCacheResponse:completionHandler:)`
    public var dataTaskWillCacheResponseWithCompletion: ((URLSession, URLSessionDataTask, CachedURLResponse, @escaping (CachedURLResponse?) -> Void) -> Void)?
}

public struct SpiSessionDownloadDelegateEvents {
    
    ///
    ///
    /// `urlSession(_:downloadTask:didFinishDownloadingTo:)`
    public var downloadTaskDidFinishDownloadingToURL: ((URLSession, URLSessionDownloadTask, URL) -> Void)?
    
    ///
    ///
    /// `urlSession(_:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:)`.
    public var downloadTaskDidWriteData: ((URLSession, URLSessionDownloadTask, Int64, Int64, Int64) -> Void)?
    
    ///
    ///
    /// `urlSession(_:downloadTask:didResumeAtOffset:expectedTotalBytes:)`.
    public var downloadTaskDidResumeAtOffset: ((URLSession, URLSessionDownloadTask, Int64, Int64) -> Void)?
}

public struct SpiSessionStreamDelegateEvents {

#if !os(watchOS)
    var _streamTaskReadClosed: Any?
    var _streamTaskWriteClosed: Any?
    var _streamTaskBetterRouteDiscovered: Any?
    var _streamTaskDidBecomeInputStream: Any?
    
    ///
    ///
    /// `urlSession(_:readClosedFor:)`
    @available(iOS 9.0, macOS 10.11, tvOS 9.0, *)
    public var streamTaskReadClosed: ((URLSession, URLSessionStreamTask) -> Void)? {
        get {
            return _streamTaskReadClosed as? (URLSession, URLSessionStreamTask) -> Void
        }
        set {
            _streamTaskReadClosed = newValue
        }
    }
    
    ///
    ///
    /// `urlSession(_:writeClosedFor:)`
    @available(iOS 9.0, macOS 10.11, tvOS 9.0, *)
    public var streamTaskWriteClosed: ((URLSession, URLSessionStreamTask) -> Void)? {
        get {
            return _streamTaskWriteClosed as? (URLSession, URLSessionStreamTask) -> Void
        }
        set {
            _streamTaskWriteClosed = newValue
        }
    }
    
    ///
    ///
    /// `urlSession(_:betterRouteDiscoveredFor:)`
    @available(iOS 9.0, macOS 10.11, tvOS 9.0, *)
    public var streamTaskBetterRouteDiscovered: ((URLSession, URLSessionStreamTask) -> Void)? {
        get {
            return _streamTaskBetterRouteDiscovered as? (URLSession, URLSessionStreamTask) -> Void
        }
        set {
            _streamTaskBetterRouteDiscovered = newValue
        }
    }
    
    ///
    ///
    /// `urlSession(_:streamTask:didBecome:outputStream:)`
    @available(iOS 9.0, macOS 10.11, tvOS 9.0, *)
    public var streamTaskDidBecomeInputAndOutputStreams: ((URLSession, URLSessionStreamTask, InputStream, OutputStream) -> Void)? {
        get {
            return _streamTaskDidBecomeInputStream as? (URLSession, URLSessionStreamTask, InputStream, OutputStream) -> Void
        }
        set {
            _streamTaskDidBecomeInputStream = newValue
        }
    }
    
#endif
    
}
