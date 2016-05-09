//
//  Assignment+CoreDataProperties.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 5/7/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Assignment {

    @NSManaged var dateCreated: NSDate?
    @NSManaged var name: String?
    @NSManaged var possiblePoints: String?
    @NSManaged var totalPoints: String?
    @NSManaged var category: String?
    @NSManaged var markingPeriod: MarkingPeriod?

}
