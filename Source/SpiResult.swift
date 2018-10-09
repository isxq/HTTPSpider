//
//  SpiResult.swift
//  Spider
//
//  Created by ios on 2018/9/27.
//  Copyright © 2018 ios. All rights reserved.
//

import Foundation

public enum SpiResult<Value> {
    case success(Value)
    case failure(Error)
    
    public var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    public var isFailed: Bool {
        return !isSuccess
    }
    
    public var value: Value? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
            
        }
    }
    
    public var error: Error? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}

extension SpiResult: CustomStringConvertible {
    public var description: String {
        switch self {
        case .success:
            return "SUCCESS"
        case .failure:
            return "FAILURE"
        }
    }
}

extension SpiResult: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .success(let value):
            return "SUCCESS:\(value)"
        case .failure(let error):
            return "FAILURE:\(error)"
        }
    }
}

extension SpiResult {
    
    public init(value: () throws -> Value) {
        do {
            self = try .success(value())
        } catch {
            self = .failure(error)
        }
    }
    
    public func unwrap() throws -> Value {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
    
    public func map<T>(_ transform: (Value) -> T) -> SpiResult<T> {
        switch self {
        case .success(let value):
            return .success(transform(value))
        case .failure(let error):
            return .failure(error)
        }
    }
    
    public func flatMap<T>(_ transform: (Value) throws -> T) -> SpiResult<T> {
        switch self {
        case .success(let value):
            do {
                return try .success(transform(value))
            } catch {
                return .failure(error)
            }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    public func mapError<E: Error>(_ transform: (Error) -> E) -> SpiResult {
        switch self {
        case .failure(let error):
            return .failure(transform(error))
        case .success:
            return self
        }
    }
    
    public func flatMapError<E: Error>(_ transform: (Error) throws -> E) -> SpiResult {
        switch self {
        case .failure(let error):
            do {
                return try .failure(transform(error))
            } catch {
                return .failure(error)
            }
        case .success:
            return self
        }
    }
    
    @discardableResult
    public func withValue(_ closure: (Value) -> Void) -> SpiResult {
        if case let .success(value) = self { closure(value) }
        return self
    }
    
    @discardableResult
    public func withError(_ clousure: (Error) -> Void) -> SpiResult {
        if case let .failure(error) = self { clousure(error) }
        return self
    }
    
    @discardableResult
    public func ifSuccess(_ closure: ()-> Void) -> SpiResult {
        if isSuccess { closure() }
        return self
    }
}
