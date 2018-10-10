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
                if let data = self.delegate.data{
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]{
                            result = .success(json)
                        } else {
                            result = .failure(SpiError.responseSerializationFailed(reason: .transformError))
                        }
                    } catch {
                        result = .failure(error)
                    }
                } else {
                    result = .failure(SpiError.responseSerializationFailed(reason: .dataIsNil))
                }
                let jsonResponse = DataResponse(request: self.request, response: self.response, data: self.delegate.data, result: result, timeline: self.timeline)
                completionHandler(jsonResponse)
            }
        }
        return self
    }
    
    @discardableResult
    public func response<T: Codable>(queue: DispatchQueue? = nil, jsonPath:[String]? = nil,  completionHandler: @escaping(DataResponse<T>) -> Void) -> Self {
        delegate.queue.addOperation {
            (queue ?? DispatchQueue.main).async {
                var result: SpiResult<T>!
                if let data = self.delegate.data{
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? [String: Any]{
                            
                            var jsonValue: Any? = json
                            jsonPath?.forEach({ (key) in
                                if let subJson = jsonValue as? [String: Any]{
                                    jsonValue = subJson[key]
                                }
                            })
                            
                            if jsonValue != nil {
                                if let dicValue = jsonValue as? [String: Any]{
                                    let decoder = JSONDecoder()
                                    let data = try JSONSerialization.data(withJSONObject: dicValue, options: .prettyPrinted)
                                    let value = try decoder.decode(T.self, from: data)
                                    result = .success(value)
                                } else if let value = jsonValue as? T {
                                    result = .success(value)
                                } else {
                                    result = .failure(SpiError.responseSerializationFailed(reason: .canNotFindDataForJsonPath))
                                }
                            } else {
                                result = .failure(SpiError.responseSerializationFailed(reason: .canNotFindDataForJsonPath))
                            }
                        } else {
                            result = .failure(SpiError.responseSerializationFailed(reason: .transformError))
                        }
                    } catch {
                        result = .failure(error)
                    }
                } else {
                    result = .failure(SpiError.responseSerializationFailed(reason: .dataIsNil))
                }
                let jsonResponse = DataResponse(request: self.request, response: self.response, data: self.delegate.data, result: result, timeline: self.timeline)
                completionHandler(jsonResponse)
            }
        }
        return self
    }
}
