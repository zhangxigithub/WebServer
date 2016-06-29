//
//  Server.swift
//  WebServer
//
//  Created by 张玺 on 6/26/16.
//  Copyright © 2016 me.zhangxi. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

typealias RequestHandler = (request:Request)->HTTPResponse
typealias Router         = (method:String,path:String,handler:RequestHandler)

class Server : NSObject, GCDAsyncSocketDelegate
{
    var server:GCDAsyncSocket!
    var routers = [Router]()
    
    convenience init(listen port:UInt16)
    {
        self.init()
        server = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
        do
        {
            try server.acceptOnPort(port)
            print("ok")
        }catch {
            print("error")
        }
    }
    
    
    func router(method:String,path:String,handler:RequestHandler)
    {
        self.routers.append((method:method,path:path,handler:handler))
    }
    
    
    func socket(sock: GCDAsyncSocket!, didAcceptNewSocket newSocket: GCDAsyncSocket!) {
        print("didAcceptNewSocket")
        print("newSocket \(newSocket.userData) \(newSocket.localHost) \(newSocket.localPort)")
        newSocket.readDataWithTimeout(-1, tag:1)
    }
    
    func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        print("didReadData")
        print("sock \(sock.userData) \(sock.localHost) \(sock.localPort) \(tag)")
        
        let request = Request(data:data)
        print(request.method)
        print(request.path)
        
        var  notFound = true
        for router in self.routers
        {
            if router.method == request.method
            {
                if router.path == request.path
                {
                    let response = router.handler(request: request)
                    sock.writeData(response.data, withTimeout: -1, tag: 0)
                    notFound = false
                }
            }
        }
        if notFound
        {
            print("\(request.path) 404")
            let response = HTTPResponse(html: "404")
            sock.writeData(response.data, withTimeout: -1, tag: 0)

        }
        
    }
}


class Request
{
    var header:Dictionary<String,String>!
    var headerString:String!
    
    var method:String!
    var path:String!
    var HTTPVersion:String!
    
    convenience init(data:NSData)
    {
        self.init()
        
        header = [String:String]()
        
        if let string = String(data: data, encoding: NSUTF8StringEncoding)
        {
            self.headerString = string
            
            let headerArray = string.componentsSeparatedByString("\r\n")
            
            if let info = headerArray.first
            {
                let infoArray = info.componentsSeparatedByString(" ")
                if infoArray.count == 3
                {
                    method      = infoArray[0]
                    path        = infoArray[1]
                    HTTPVersion = infoArray[2]
                }
                for i in 1 ..< headerArray.count
                {
                    if let range = headerArray[i].rangeOfString(": ")
                    {
                        let key   = headerArray[i].substringToIndex(range.startIndex)
                        let value = headerArray[i].substringFromIndex(range.endIndex)
                        header[key] = value
                    }
                }
            }
        }
    }
}
class HTTPResponse
{
    var html:String?
    var statusCode:Int = 0
    
    var data:NSData?
        {
        get{
            var response = "HTTP/1.1 \(statusCode) OK\nContent-Type: text/html; charset=UTF-8\n\n"
            response += self.html ?? ""
            return response.dataUsingEncoding(NSUTF8StringEncoding)
        }
    }
    convenience init(html:String)
    {
        self.init()
        self.html = html
    }
    
}