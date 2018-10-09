//
//  SpiTimeline.swift
//  Spider
//
//  Created by ios on 2018/10/8.
//  Copyright © 2018 ios. All rights reserved.
//

import Foundation

public struct SpiTimeline {
    
    public let requestStartTime: CFAbsoluteTime
    
    public let initialResponseTime: CFAbsoluteTime
    
    public let requestCompletedTime: CFAbsoluteTime
    
    public let serializationCompletedTime: CFAbsoluteTime
    
    public let latency: TimeInterval
    
    public let requestDuration: TimeInterval
    
    public let serializationDuration: TimeInterval
    
    public let totalDuration: TimeInterval
    
    public init(
        requestStartTime: CFAbsoluteTime = 0.0,
        initialResponseTime: CFAbsoluteTime = 0.0,
        requestCompletedTime: CFAbsoluteTime = 0.0,
        serializationCompletedTime: CFAbsoluteTime = 0.0)
    {
        self.requestStartTime = requestStartTime
        self.initialResponseTime = initialResponseTime
        self.requestCompletedTime = requestCompletedTime
        self.serializationCompletedTime = serializationCompletedTime
        
        self.latency = initialResponseTime - requestStartTime
        self.requestDuration = requestCompletedTime - initialResponseTime
        self.serializationDuration = serializationCompletedTime - requestCompletedTime
        self.totalDuration = serializationCompletedTime - requestStartTime
    }
}

extension SpiTimeline: CustomStringConvertible {
    
    public var description: String {
        let latency = String(format: "%.3f", self.latency)
        let requestDuration = String(format: "%.3f", self.requestDuration)
        let serializationDuration = String(format: "%.3f", self.serializationDuration)
        let totalDuration = String(format: "%.3f", self.totalDuration)
        
        let timing = [
            "\"Latency\": " + latency + "secs",
            "\"Request Duration\": " + requestDuration + "secs",
            "\"Serialization Duration\": " + serializationDuration + "secs",
            "\"Total Duration\": " + totalDuration + "secs"
        ]
        return "Timeline: {" + timing.joined(separator: ",") + "}"
    }
    
}

extension SpiTimeline: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        let requestStartTime = String(format: "%.3f", self.requestStartTime)
        let initialResponseTime = String(format: "%.3f", self.initialResponseTime)
        let requestCompletedTime = String(format: "%.3f", self.requestCompletedTime)
        let serializationCompletedTime = String(format: "%.3f", self.serializationCompletedTime)
        let latency = String(format: "%.3f", self.latency)
        let requestDuration = String(format: "%.3f", self.requestDuration)
        let serializationDuration = String(format: "%.3f", self.serializationDuration)
        let totalDuration = String(format: "%.3f", self.totalDuration)
        
        let timing = [
            "\"Request Start Time\": " + requestStartTime + "secs",
            "\"Initial Response Time\": " + initialResponseTime + "secs",
            "\"Request Completed time\": " + requestCompletedTime + "secs",
            "\"Serialization Completed Time\": " + serializationCompletedTime + "secs",
            "\"Latency\": " + latency + "secs",
            "\"Request Duration\": " + requestDuration + "secs",
            "\"Serialization Duration\": " + serializationDuration + "secs",
            "\"Total Duration\": " + totalDuration + "secs"
        ]
        return "Timeline: {" + timing.joined(separator: ",") + "}"
    }
    
    
}
