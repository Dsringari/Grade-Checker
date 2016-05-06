//
//  Subject.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 5/5/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import Foundation
import CoreData


class Subject: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    var mostRecentDate: NSDate? {
        get {
            let markingPeriods = self.markingPeriods!.allObjects as! [MarkingPeriod]
            if (markingPeriods.filter{!$0.empty!.boolValue}.isEmpty) {
                return nil
            }
            var assignments = markingPeriods.filter { !$0.empty!.boolValue }.sort { Int($0.number!) > Int($1.number!) }[0].assignments!.allObjects as! [Assignment]
            assignments.sortInPlace{ $0.dateUpdated!.compare($1.dateUpdated!) == NSComparisonResult.OrderedDescending }
            return assignments[0].dateUpdated!
        }
    }
    
    var hasUpdates: Bool {
        get {
            let markingPeriods = self.markingPeriods!.allObjects as! [MarkingPeriod]
            if (markingPeriods.filter{!$0.empty!.boolValue}.isEmpty) {
                return false
            }
            var updatedAssignments: [Assignment] = []
            
            for mp in markingPeriods {
                let assignments = mp.assignments!.allObjects as! [Assignment]
                updatedAssignments.appendContentsOf(assignments.filter{$0.hadChanges!.boolValue})
            }
            
            return !updatedAssignments.isEmpty
        }
        
    }

}
