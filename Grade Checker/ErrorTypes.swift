//
//  ErrorTypes.swift
//  Grade Checker
//
//  Created by Dhruv Sringari on 3/19/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import Foundation

// This is the NSError for errors relating to parsing or encoding.
private let unknownResponse = [NSLocalizedDescriptionKey: NSLocalizedString("Could not Login.", comment: ""), NSLocalizedFailureReasonErrorKey: NSLocalizedString("Could not understand the response made by the server.", comment: ""), NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Try restarting the application. If error persists contact the developer.", comment: "")]
let unknownResponseError = NSError(domain: "Bad Response", code: 1, userInfo: unknownResponse)

// This is the NSError for bad credentials
private let badLogin = [NSLocalizedDescriptionKey: NSLocalizedString("Could not Login.", comment: ""), NSLocalizedFailureReasonErrorKey: NSLocalizedString("Credentials may be invalid.", comment: ""), NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Please verify your credentials.", comment: "")]
let badLoginError = NSError(domain: "Bad Login", code: 1, userInfo: badLogin)
