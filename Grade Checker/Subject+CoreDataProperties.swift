//
//  Subject+CoreDataProperties.swift
//  Grade Checker
//
//  Created by Dhruv Sringari on 3/19/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Subject {

    @NSManaged var name: String
    @NSManaged var teacher: String
    @NSManaged var htmlPage: String
    @NSManaged var totalPoints: NSNumber?
    @NSManaged var possiblePoints: NSNumber?
    @NSManaged var room: String
    @NSManaged var user: User

}
