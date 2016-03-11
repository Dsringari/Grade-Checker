//
//  DSLoginService.swift
//  Grade Checker
//
//  Created by Dhruv Sringari on 3/10/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import Foundation

class LoginService {
    let user: User
    let session: NSURLSession
    
    init(userToBeLoggedIn: User) {
        user = userToBeLoggedIn
        // We use the default session configuration instead of the shared configuration because we want cookies to be stored; sapphire requires cookies to function
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        config.HTTPCookieAcceptPolicy = .Always
        session = NSURLSession(configuration: config)
      
    }
    
    private func logout() {
        let headers = [
            "cache-control": "no-cache",
            "postman-token": "d956b37d-d7e5-2af9-ff95-a7ddf20f336e"
        ]
        
        let request = NSMutableURLRequest(URL: NSURL(string: "https://pamet-sapphire.k12system.com/CommunityWebPortal/Welcome.cfm?logout=1")!,
            cachePolicy: .UseProtocolCachePolicy,
            timeoutInterval: 10.0)
        request.HTTPMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let dataTask = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                print(error)
            } else {
                let httpResponse = response as? NSHTTPURLResponse
                //print(httpResponse)
            }
        })
        
        dataTask.resume()
    }
    
    func login(completion: (successful: Bool) -> Void ) {
        logout()
        
        let headers = [
            "cache-control": "no-cache",
            "postman-token": "5fd65459-4e9b-da37-af47-01b8347b8f53",
            "content-type": "application/x-www-form-urlencoded"
        ]
        
        let postData = NSMutableData(data: "javascript=true".dataUsingEncoding(NSUTF8StringEncoding)!)
        postData.appendData("&j_username=SringariDhruv".dataUsingEncoding(NSUTF8StringEncoding)!)
        postData.appendData("&j_password=181012".dataUsingEncoding(NSUTF8StringEncoding)!)
        postData.appendData("&J_pin=98095".dataUsingEncoding(NSUTF8StringEncoding)!)
        
        let request = NSMutableURLRequest(URL: NSURL(string: "https://pamet-sapphire.k12system.com/CommunityWebPortal/Welcome.cfm")!,
            cachePolicy: .UseProtocolCachePolicy,
            timeoutInterval: 10.0)
        request.HTTPMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.HTTPBody = postData
        
        _ = session.dataTaskWithRequest(request) // Repetition to fix cookie issue
        
        let dataTask = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                print(error)
            } else {
                if let httpResponse = response as? NSHTTPURLResponse {
                    print(httpResponse)
                }
                
                print(NSString(data: data!, encoding: NSUTF8StringEncoding)!)
            }
        })
        
        dataTask.resume()
        
    }
    
}