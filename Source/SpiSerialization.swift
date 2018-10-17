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
                if let error = self.delegate.error {
                    result = .failure(error)
                } else {
                    do {
                        let json = try self.getjson(from: self.delegate.data)
                        result = .success(json)
                    } catch {
                        result = .failure(error)
                    }
                }
                var jsonResponse = DataResponse(request: self.request, response: self.response, data: self.delegate.data, result: result, timeline: self.timeline)
                jsonResponse.add(self.delegate.metrics)
                completionHandler(jsonResponse)
            }
        }
        return self
    }
    
    
    @discardableResult
    public func response<T>(queue: DispatchQueue? = nil,
                            tranform: @escaping ([String: Any]) throws -> T,
                            completionHandler: @escaping(DataResponse<T>) -> Void) -> Self {
        delegate.queue.addOperation {
            (queue ?? DispatchQueue.main).async {
                var jsonResult: SpiResult<[String: Any]>!
                if let error = self.delegate.error {
                    jsonResult = .failure(error)
                } else {
                    do {
                        let json = try self.getjson(from: self.delegate.data)
                        jsonResult = .success(json)
                    } catch {
                        jsonResult = .failure(error)
                    }
                }
                var jsonResponse = DataResponse(request: self.request, response: self.response, data: self.delegate.data, result: jsonResult, timeline: self.timeline)
                jsonResponse.add(self.delegate.metrics)
                let response = jsonResponse.flatMap(tranform)
                completionHandler(response)
            }
        }
        return self
    }

    /// 获取json
    func getjson(from data: Data?) throws -> [String: Any] {
        if let data = data {
            do {
                let  object = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                if let json = object as? [String: Any]{
                    return json
                } else {
                    throw SpiError.responseSerializationFailed(reason: .jsonIsNotADictionary)
                }
                
            } catch  {
                throw SpiError.responseSerializationFailed(reason: .jsonSerializationFailed(error))
            }
        } else {
            throw SpiError.responseSerializationFailed(reason: .dataIsNil)
        }
    }
    
    /// 从给定的路径获取值
    func getValue(_ json: [String: Any], path: [String]) -> Any? {
        var jsonValue: Any? = json
        path.forEach({ (key) in
            if let subJson = jsonValue as? [String: Any]{
                jsonValue = subJson[key]
            }
        })
        return jsonValue
    }
    
}
