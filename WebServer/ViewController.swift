//
//  ViewController.swift
//  WebServer
//
//  Created by 张玺 on 6/26/16.
//  Copyright © 2016 me.zhangxi. All rights reserved.
//

import UIKit


class ViewController: UIViewController {

    var server = Server(listen: 1081)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    
        server.router("GET", path: "/") { (request) in
            
            print(request.header)
            
            let response = HTTPResponse(html: "root path")
            
            return response
        }
        server.router("GET", path: "/note/") { (request) in
            
            let response = HTTPResponse(html: "老婆呢?")
            
            return response
        }
    }

}



