//
//  ViewController.swift
//  HTTPSpiderExample
//
//  Created by ios on 2018/10/9.
//  Copyright © 2018 ios. All rights reserved.
//

import UIKit
import HTTPSpider

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        Spi(Api.post).send().response{(response: DataResponse<[User]>) in
            switch response.result{
            case .success(let value):
                print(value)
            case .failure(let error):
                print("-------")
                print(error.localizedDescription)
            }
        }
    }

}

enum Api {
    case get
    case post
}

extension Api: SpiTarget{
    
    var path: String {
        switch self {
        case .get: return "get"
        case .post: return "post"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .get: return .get
        case .post: return .post
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case .get: return ["user": ["name": "yahaha", "age": 100], "other":"hehe"]
        case .post: return ["ret": "0",
                            "msg": "not hahahaha",
                            "users": [
                                ["Name": "yahaha", "age": 100],
                                ["Name": "yahaha", "age": 100],
                                ["Name": "yahaha", "age": 100]],
                            "other":"hehe"]
        }
    }
    
    var debug: Bool {
        return true
    }
}


struct User: Codable {
    var Name: String?
    var age: String?
}


extension SpiDataRequest {
    
    enum SelfError: Error{
        case error
    }
    
    @discardableResult
    func response<T: Codable>(queue: OperationQueue? = nil, completionHandler: @escaping (DataResponse<T>) -> Void) -> Self {
        response(tranform: { (json) -> T in
            if let value = json["json"] as? [String: Any], let ret = value["ret"] as? String, ret == "0" {
                if let object = value["users"] {
                    do {
                        let data = try JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
                        let decoder = JSONDecoder()
                        let user = try decoder.decode(T.self, from: data)
                        return user
                    } catch {
                        throw error
                    }
                } else {
                    print(">>>>>>>>")
                    throw SelfError.error
                }
            } else {
                print("<<<<<<<")
                throw SelfError.error
            }
        }, completionHandler: completionHandler)
        return self
    }
    
}
