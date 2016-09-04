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
	private var mostRecentAssignment: Assignment? {
		let markingPeriods = self.markingPeriods!.allObjects as! [MarkingPeriod]
		if (markingPeriods.filter { !$0.empty!.boolValue }.isEmpty) {
			return nil
		}
		var assignments = markingPeriods.filter { !$0.empty!.boolValue }.sort { Int($0.number!) > Int($1.number!) }[0].assignments!.allObjects as! [Assignment]
		assignments.sortInPlace { $0.dateCreated!.compare($1.dateCreated!) == NSComparisonResult.OrderedDescending }
		return assignments[0]
	}
    
    /// Returns the most recent date that the subject has between the mostRecentAssignment and lastUpdated values
    lazy var mostRecentDate: NSDate? = {
        if let date = self.lastUpdated, let assignment = self.mostRecentAssignment {
            return date.compare(assignment.dateCreated!) == NSComparisonResult.OrderedDescending ? date : assignment.dateCreated!
        } else if let assignment = self.mostRecentAssignment {
            return assignment.dateCreated!
        }
        
        return nil
    }()

}
