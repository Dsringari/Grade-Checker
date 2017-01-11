//
//  NDataService.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 1/7/17.
//  Copyright © 2017 Dhruv Sringari. All rights reserved.
//

import Foundation

class Service {
    init?(studentID: NSManagedObjectID) {
        do {
            let object = try context.existingObject(with: studentID)
            if let s = object as? Student {
                student = s
                if let subs = student.subjects {
                    firstLoad = subs.allObjects.isEmpty
                } else {
                    firstLoad = true
                }
            } else {
                print("Failed to find student with object ID \(studentID). Could not cast NSManagedObject to Student")
                return nil
            }
        } catch let error as NSError {
            print("Failed to find student with object ID \(studentID). Error: \(error)")
            return nil
        }
        
    }
}
