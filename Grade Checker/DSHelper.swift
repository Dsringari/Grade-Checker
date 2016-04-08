//
//  DSHelper.swift
//  Grade Checker
//
//  Created by Dhruv Sringari on 4/7/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import Foundation

// Array Extensions
extension Array where Element: Equatable {
    // Removes an Object from a swift array
    mutating func removeObject(object: Element) {
        if let index = self.indexOf(object) {
            self.removeAtIndex(index)
        }
    }
    
    // Removes a set of objects from a swift array
    mutating func removeObjectsInArray(array: [Element]) {
        for object in array {
            self.removeObject(object)
        }
    }
}
