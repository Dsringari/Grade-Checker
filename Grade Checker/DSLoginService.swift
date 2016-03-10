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
        // we use the default session configuration instead of the shared configuration because we want cookies to be stored; sapphire requires cookies to function
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        session = NSURLSession(configuration: config)
    }
    
    func login(completion: (successful: Bool) -> Void) {
        
        completion(successful: true)
    }
    
}