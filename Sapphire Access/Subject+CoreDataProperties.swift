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

    @NSManaged var htmlPage: String?
    @NSManaged var name: String?
    @NSManaged var room: String?
    @NSManaged var sectionGUID: String?
    @NSManaged var teacher: String?
    @NSManaged var lastUpdated: NSDate?
    @NSManaged var markingPeriods: NSSet?
    @NSManaged var student: Student?

}
