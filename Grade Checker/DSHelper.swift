//
//  DSHelper.swift
//  Grade Checker
//
//  Created by Dhruv Sringari on 4/7/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import Foundation
import CoreData

// Array Extensions
extension Array where Element: Equatable {
    // Removes an Object from a swift array
    mutating func removeObject(object: Element) {
        if let index = self.indexOf(object) {
            self.removeAtIndex(index)
        }
    }
    
    // Removes a set of objects from a swift array
    mutating func removeObjectsInArray(array: [Element]) {
        for object in array {
            self.removeObject(object)
        }
    }
    
    // Returns a random object from a swift array
    var randomObject: Element? {
        if (self.count == 0) {
            return nil
        }
        let index = Int(arc4random_uniform(UInt32(self.count)))
        return self[index]
    }
}

extension NSArray {
    func getObjectInArray(predicateString: String, args: [AnyObject]?) -> AnyObject? {
        let predicate = NSPredicate(format: predicateString, argumentArray: args)
        let result = self.filteredArrayUsingPredicate(predicate)
        if result.count == 0 {
            return nil
        } else if result.count > 1 {
            print("Wanted one object got multiple returning nil")
            return nil
        }
        return result[0]
    }
    
    
    class func getObjectsInArray(predicateString: String, args: [AnyObject]?, array: NSArray) -> [AnyObject] {
        let predicate = NSPredicate(format: predicateString, argumentArray: args)
        let result = array.filteredArrayUsingPredicate(predicate)
        if result.count == 0 {
            return []
        }
        return result
    }

}

extension NSManagedObjectContext {
     func getObjectsFromStore(entityName: String, predicateString: String?, args: [AnyObject]?) -> [AnyObject] {
        
        var predicate: NSPredicate?
        if let p = predicateString {
            predicate = NSPredicate(format: p, argumentArray: args)
        }
        
        let objectRequest = NSFetchRequest()
        objectRequest.entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: self)
        objectRequest.predicate = predicate
        
        do {
            let objects = try self.executeFetchRequest(objectRequest)
            return objects
        } catch {
            print("***************************")
            print("Failed to Fetch", entityName + ":", error, separator: " ", terminator: "\n")
            return []
        }
    }
    
     func getObjectFromStore(entityName: String, predicateString: String?, args: [AnyObject]?) -> AnyObject? {
        var predicate: NSPredicate?
        if let p = predicateString {
            predicate = NSPredicate(format: p, argumentArray: args)
        }
        
        let objectRequest = NSFetchRequest()
        objectRequest.entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: self)
        objectRequest.predicate = predicate
        
        do {
            let objects = try self.executeFetchRequest(objectRequest)
            
            if (objects.count > 1 || objects.count == 0) {
                print("***************************")
                print("Failed to Fetch", entityName + ".", "Recieved", objects.count, "when 1 was requested. Returning nil.", separator: " ", terminator: "\n")
                return nil
            }
            
            return objects[0]
        } catch {
            print("***************************")
            print("Failed to Fetch", entityName + ":", error, separator: " ", terminator: "\n")
            return []
        }
    }
    
    func saveContext () {
        if self.hasChanges {
            do {
                try self.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
    
}
