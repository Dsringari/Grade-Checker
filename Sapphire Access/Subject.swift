//
//  Subject.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 5/5/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import Foundation
import CoreData
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class Subject: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
	fileprivate var mostRecentAssignment: Assignment? {
		let markingPeriods = self.markingPeriods!.allObjects as! [MarkingPeriod]
		if (markingPeriods.filter { !$0.empty!.boolValue }.isEmpty) {
			return nil
		}
		var assignments = markingPeriods.filter { !$0.empty!.boolValue }.sorted { Int($0.number!) > Int($1.number!) }[0].assignments!.allObjects as! [Assignment]
		assignments.sort { $0.dateCreated!.compare($1.dateCreated! as Date) == ComparisonResult.orderedDescending }
		return assignments[0]
	}
    
    /// Returns the most recent date that the subject has between the mostRecentAssignment and lastUpdated values
    lazy var mostRecentDate: Date? = {
        if let date = self.lastUpdated, let assignment = self.mostRecentAssignment {
            return (date.compare(assignment.dateCreated! as Date) == ComparisonResult.orderedDescending ? date : assignment.dateCreated!) as Date
        } else if let assignment = self.mostRecentAssignment {
            return assignment.dateCreated! as Date
        }
        
        return nil
    }()

}
