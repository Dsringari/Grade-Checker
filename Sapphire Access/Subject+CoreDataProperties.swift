//
//  Subject+CoreDataProperties.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 5/9/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Subject {

    @NSManaged var name: String
    @NSManaged var room: String
    @NSManaged var address: String
    @NSManaged var teacher: String
    @NSManaged var lastUpdated: Date?
    @NSManaged var otherGrades: String?
    @NSManaged var mostRecentGrade: String?
    @NSManaged var weight: NSDecimalNumber
    @NSManaged var credits: NSDecimalNumber
    @NSManaged var markingPeriods: NSSet?
    @NSManaged var student: Student?
    
    func mostRecentMarkingPeriod() -> MarkingPeriod {
        var sortedMPs = markingPeriods!.allObjects as! [MarkingPeriod]
        sortedMPs = sortedMPs.filter{!$0.empty!.boolValue}.sorted{$0.number > $1.number}
        return sortedMPs[0]
    }

}
