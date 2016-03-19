//
//  User+CoreDataProperties.swift
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

extension User {

    @NSManaged var username: String
    @NSManaged var password: String
    @NSManaged var pin: String
    @NSManaged var id: String?
    @NSManaged var subjects: NSSet?

}
