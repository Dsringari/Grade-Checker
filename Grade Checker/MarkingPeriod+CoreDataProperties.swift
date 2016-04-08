//
//  MarkingPeriod+CoreDataProperties.swift
//  Grade Checker
//
//  Created by Dhruv Sringari on 4/8/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension MarkingPeriod {

    @NSManaged var htmlPage: String?
    @NSManaged var number: String?
    @NSManaged var possiblePoints: NSNumber?
    @NSManaged var totalPoints: NSNumber?
    @NSManaged var percentGrade: String?
    @NSManaged var empty: NSNumber?
    @NSManaged var assignments: NSSet?
    @NSManaged var subject: Subject?

}
