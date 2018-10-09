//
//  SpiResponse.swift
//  Spider
//
//  Created by ios on 2018/10/8.
//  Copyright © 2018 ios. All rights reserved.
//

import Foundation

protocol SpiResponse {
    var _metrics: AnyObject? { get set }
    mutating func add(_ metrics: AnyObject?)
}

public struct DefaultDataResponse {
    
    public let request: URLRequest?
    
    public let response: HTTPURLResponse?
    
    public let data: Data?
    
    public let error: Error?
    
    var timeline: SpiTimeline
    
    var _metrics: AnyObject?
    
    public init(
        request: URLRequest?,
        response: HTTPURLResponse?,
        data: Data?,
        error: Error?,
        timeline: SpiTimeline = SpiTimeline(),
        metrics: AnyObject? = nil) {
        self.request = request
        self.response = response
        self.data = data
        self.error = error
        self.timeline = timeline
    }
}

public struct DataResponse<Value> {
    
    public let request: URLRequest?
    
    public let response: HTTPURLResponse?
    
    public let data: Data?
    
    public let result: SpiResult<Value>
    
    public let timeline: SpiTimeline
    
    public var value: Value? { return result.value }
    
    public var error: Error? { return result.error }
    
    var _metrics: AnyObject?
    
    public init(
        request: URLRequest?,
        response: HTTPURLResponse?,
        data: Data?,
        result: SpiResult<Value>,
        timeline: SpiTimeline = SpiTimeline())
    {
        self.request = request
        self.response = response
        self.data = data
        self.result = result
        self.timeline = timeline
    }
}

extension DataResponse: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        return result.description
    }
    
    public var debugDescription: String {
        var output: [String] = []
        output.append(request != nil ? "[Request]: \(request?.httpMethod ?? "GET") \(request!)" : "[Request]: nil")
        output.append(response != nil ? "[Response]: \(response!)" : "[Response]: nil")
        output.append("[Data]: \(data?.count ?? 0) bytes")
        output.append("[Result]: \(result.debugDescription)")
        output.append("[Timeline]: \(timeline.debugDescription)")
        return output.joined(separator: "\n")
    }
    
}

extension DataResponse {
    
    public func map<T>(_ transform: (Value) -> T) -> DataResponse<T> {
        var response = DataResponse<T>(request: request, response: self.response, data: data, result: result.map(transform), timeline: timeline)
        response._metrics = _metrics
        return response
    }
    
    public func flatMap<T>(_ transform: (Value) throws -> T) -> DataResponse<T> {
        var response = DataResponse<T>(request: request, response: self.response, data: data, result: result.flatMap(transform), timeline: timeline)
        response._metrics = _metrics
        return response
    }
    
    public func mapError<E: Error>(_ transform: (Error) -> E) -> DataResponse {
        var response = DataResponse(request: request, response: self.response, data: data, result: result.mapError(transform), timeline: timeline)
        response._metrics = _metrics
        return response
    }
    
    public func flatMapError<E: Error>(_ transform: (Error) throws -> E) -> DataResponse {
        var response = DataResponse(request: request, response: self.response, data: data, result: result.flatMapError(transform), timeline: timeline)
        response._metrics = _metrics
        return response
    }
}

extension SpiResponse {
    
    mutating func add(_ metrics: AnyObject?) {
        #if !os(watchOS)
        guard #available(iOS 10.0, macOS 10.12, tvOS 10.10, *) else { return }
        guard let metrics = metrics as? URLSessionTaskMetrics else { return }
        _metrics = metrics
        #endif
    }
    
}

@available(iOS 10.0, macOS 10.12, tvOS 10.10, *)
extension DefaultDataResponse: SpiResponse {
    #if !os(watchOS)
    public var metrics: URLSessionTaskMetrics? {
        return _metrics as? URLSessionTaskMetrics
    }
    #endif
}

@available(iOS 10.0, macOS 10.12, tvOS 10.10, *)
extension DataResponse: SpiResponse {
    #if !os(watchOS)
    public var metrics: URLSessionTaskMetrics? {
        return _metrics as? URLSessionTaskMetrics
    }
    #endif
}
