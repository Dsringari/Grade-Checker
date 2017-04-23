//
//  Student+CoreDataProperties.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 8/1/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Student {

    @NSManaged var name: String?
    @NSManaged var grade: String?
    @NSManaged var school: String?
    @NSManaged var id: String?
    @NSManaged var subjects: NSSet?
    @NSManaged var user: User?

}
