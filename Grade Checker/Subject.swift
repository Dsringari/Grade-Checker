//
//  Subject.swift
//  Grade Checker
//
//  Created by Dhruv Sringari on 3/19/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import Foundation
import CoreData


class Subject: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    var percentGrade: Int? {
        if (possiblePoints != nil && totalPoints != nil) {
            return (totalPoints!.integerValue/possiblePoints!.integerValue) * 100
        }
        return nil
    }
}
