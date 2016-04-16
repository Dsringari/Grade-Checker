//
//  ErrorTypes.swift
//  Grade Checker
//
//  Created by Dhruv Sringari on 3/19/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import Foundation

// This is the NSError for errors relating to parsing or encoding.
private let unknownResponse = [NSLocalizedDescriptionKey: NSLocalizedString("Could not Login", comment: ""), NSLocalizedFailureReasonErrorKey: NSLocalizedString("Something Bad Happened", comment: ""), NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Try restarting the application. If error persists contact the developer.", comment: "")]
let unknownResponseError = NSError(domain: "Bad Response", code: 1, userInfo: unknownResponse)

// This is the NSError for bad credentials
private let badLogin = [NSLocalizedDescriptionKey: NSLocalizedString("Check Your Info", comment: ""), NSLocalizedFailureReasonErrorKey: NSLocalizedString("This account does not exist.", comment: ""), NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Please verify your credentials.", comment: "")]
let badLoginError = NSError(domain: "Bad Login", code: 1, userInfo: badLogin)

// This is the NSError for a bad connection
private let badConnection = [NSLocalizedDescriptionKey: NSLocalizedString("No Internet Connection", comment: ""), NSLocalizedFailureReasonErrorKey: NSLocalizedString("We couldn't connect to the internet.", comment: ""), NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Check your internet connection", comment: "")]
