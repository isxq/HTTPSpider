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
        Spi(Api.post).send().response( jsonPath: ["json", "other"]) { (response: DataResponse<String>) in
            switch response.result{
            case let .success(str):
                print(str)
            case let .failure(error):
                print(error)
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
        case .post: return ["user": ["name": "yahaha", "age": 100], "other":"hehe"]
        }
    }
    
}
