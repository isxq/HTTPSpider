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
        
        Spi(Api.post).send().response(tranform: { (json) -> String in
            if let value = json["json"] as? [String: Any], let ret = value["ret"] as? String, ret == "0" {
                if let str = value["other"] as? String {
                    return str
                }
                return "error0"
            } else {
                return "error1"
            }
        }) { (response) in
            switch response.result{
            case .success(let value):
                print(value)
            case .failure(let error):
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
        case .post: return ["ret": "-1", "msg": "not hahahaha", "user": ["name": "yahaha", "age": 100], "other":"hehe"]
        }
    }
    
    var debug: Bool {
        return true
    }
}
