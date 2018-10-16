//
//  SpiSerialization.swift
//  Spider
//
//  Created by ios on 2018/10/8.
//  Copyright © 2018 ios. All rights reserved.
//

import Foundation

//MARK: - 结果处理

/// Timeline
/// Timeline
extension SpiRequest {
    var timeline: SpiTimeline {
        let requestStartTime = self.startTime ?? CFAbsoluteTimeGetCurrent()
        let requestCompletedTime = self.endTime ?? CFAbsoluteTimeGetCurrent()
        let initialResponseTime = self.delegate.initialResponseTime ?? requestCompletedTime
        
        return SpiTimeline(requestStartTime: requestStartTime,
                           initialResponseTime: initialResponseTime,
                           requestCompletedTime: requestCompletedTime,
                           serializationCompletedTime: CFAbsoluteTimeGetCurrent())
    }
    
}

extension SpiDataRequest {
    
    @discardableResult
    public func response(queue: DispatchQueue? = nil , completionHandler: @escaping (DefaultDataResponse) -> Void) -> Self {
        delegate.queue.addOperation {
            (queue ?? DispatchQueue.main).async {
                var dataResponse = DefaultDataResponse(request: self.request,
                                                       response: self.response,
                                                       data: self.delegate.data,
                                                       error: self.delegate.error,
                                                       timeline: self.timeline)
                dataResponse.add(self.delegate.metrics)
                completionHandler(dataResponse)
            }
        }
        return self
    }
    
    @discardableResult
    public func responseJSON(queue: DispatchQueue? = nil, completionHandler: @escaping (DataResponse<[String: Any]>) -> Void) -> Self {
        delegate.queue.addOperation {
            (queue ?? DispatchQueue.main).async {
                var result: SpiResult<[String: Any]>!
                do {
                    let json = try self.getjson(from: self.delegate.data)
                    result = .success(json)
                } catch {
                    result = .failure(error)
                }
                let jsonResponse = DataResponse(request: self.request, response: self.response, data: self.delegate.data, result: result, timeline: self.timeline)
                completionHandler(jsonResponse)
            }
        }
        return self
    }
    
    @discardableResult
    public func response<T: Codable>(queue: DispatchQueue? = nil,
                                     jsonPath:[String]? = nil,
                                     checkPath:[String]? = nil,
                                     checkValue: String? = nil,
                                     errorPath:[String]? = nil,
                                     completionHandler: @escaping(DataResponse<T>) -> Void) -> Self {
        delegate.queue.addOperation {
            (queue ?? DispatchQueue.main).async {
                
                var result: SpiResult<T>!
                do {
                    let json = try self.getjson(from: self.delegate.data)
                    if let path = checkPath, let value = checkValue, let error = errorPath {
                        try self.checkValue(json, path: path, checkValue: value, error: error)
                    }
                    var value: Any = json
                    if let path = jsonPath {
                        if let subValue = try self.getValue(json, path: path){
                            value = subValue
                        } else {
                            throw SpiError.responseSerializationFailed(reason: .canNotFindDataForJsonPath)
                        }
                    }
                    result = try self.decodeValue(value)
                } catch {
                    result = .failure(error)
                }
                let jsonResponse = DataResponse(request: self.request, response: self.response, data: self.delegate.data, result: result, timeline: self.timeline)
                completionHandler(jsonResponse)
            }
        }
        return self
    }

    /// 获取json
    func getjson(from data: Data?) throws -> [String: Any] {
        if let data = data {
            if let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? [String: Any]{
                return json
            } else {
                throw SpiError.responseSerializationFailed(reason: .transformError)
            }
        } else {
            throw SpiError.responseSerializationFailed(reason: .dataIsNil)
        }
    }
    
    /// 从给定的路径获取值
    func getValue(_ json: [String: Any], path: [String]) throws -> Any? {
        
        var jsonValue: Any? = json
        try path.forEach({ (key) in
            if let subJson = jsonValue as? [String: Any]{
                jsonValue = subJson[key]
            } else {
                throw SpiError.responseSerializationFailed(reason: .canNotFindDataForJsonPath)
            }
        })
        return jsonValue
    }
    
    /// 将值进行编码
    func decodeValue<T: Codable>(_ jsonValue: Any) throws -> SpiResult<T> {
        
        var result: SpiResult<T>!
        
        if let dicValue = jsonValue as? [String: Any] {
            let decoder = JSONDecoder()
            let data = try JSONSerialization.data(withJSONObject: dicValue, options: .prettyPrinted)
            let value = try decoder.decode(T.self, from: data)
            result = .success(value)
        } else if let value = jsonValue as? T {
            result = .success(value)
        } else {
            result = .failure(SpiError.responseSerializationFailed(reason: .canNotReadCodableType))
        }
        return result
    }
    
    /// 检查值
    func checkValue(_ json: [String: Any], path:[String], checkValue: String, error: [String]) throws {
        if let value = try getValue(json, path: path) as? String {
            if value != checkValue {
                if let message = try getValue(json, path: error) as? String {
                    throw SpiError.responseValidationFailed(reason: .resultCheckError(message: message))
                } else {
                    throw SpiError.responseSerializationFailed(reason: .canNotFindDataForJsonPath)
                }
            }
        } else {
            throw SpiError.responseSerializationFailed(reason: .canNotFindDataForJsonPath)
        }
        
    }
}
