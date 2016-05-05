//
//  AppDelegate.swift
//  Grade Checker
//
//  Created by Dhruv Sringari on 3/8/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		// Override point for customization after application launch.
		// Set the UINavigationBar Back button tint color to the green color
		UINavigationBar.appearance().tintColor = UIColor(colorLiteralRed: 86 / 255, green: 100 / 255, blue: 115 / 255, alpha: 1.0)
		// Change Tab Bar Text Colors
		UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.whiteColor()], forState: .Normal)
		UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor(colorLiteralRed: 22 / 255, green: 160 / 255, blue: 133 / 255, alpha: 1.9)], forState: .Selected)
		// UITabBar.appearance().tintColor = UIColor.grayColor()
		// Set default preferences
		let appDefaults = ["setupTouchID": NSNumber(bool: true), "useTouchID": NSNumber(bool: false), "setupNotifications": NSNumber(bool: true)]
		NSUserDefaults.standardUserDefaults().registerDefaults(appDefaults)
		return true
	}

	func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		let settings = NSUserDefaults.standardUserDefaults()
		if (settings.stringForKey("selectedStudent") != nil) {
			UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
		} else {
			UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
		}
		return true
	}

	func applicationWillResignActive(application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

		let settings = NSUserDefaults.standardUserDefaults()
		if (settings.stringForKey("selectedStudent") != nil) {
			UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
		} else {
			UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
		}
	}

	func applicationWillEnterForeground(application: UIApplication) {
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}

	// MARK: - Core Data stack

	lazy var applicationDocumentsDirectory: NSURL = {
		// The directory the application uses to store the Core Data store file. This code uses a directory named "uk.co.plymouthsoftware.core_data" in the application's documents Application Support directory.
		let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
		return urls[urls.count - 1]
	}()

	lazy var managedObjectModel: NSManagedObjectModel = {
		// The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
		let modelURL = NSBundle.mainBundle().URLForResource("Model", withExtension: "momd")!
		return NSManagedObjectModel(contentsOfURL: modelURL)!
	}()

	lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
		// The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
		// Create the coordinator and store
		let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
		let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("GradeChecker.sqlite")
		var failureReason = "There was an error creating or loading the application's saved data."
		do {
			try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
		} catch {
			// Report any error we got.
			var dict = [String: AnyObject]()
			dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
			dict[NSLocalizedFailureReasonErrorKey] = failureReason

			dict[NSUnderlyingErrorKey] = error as NSError
			let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
			// Replace this with code to handle the error appropriately.
			// abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
			NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
			abort()
		}

		return coordinator
	}()

	lazy var managedObjectContext: NSManagedObjectContext = {
		// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
		let coordinator = self.persistentStoreCoordinator
		var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.shouldDeleteInaccessibleFaults = false
		managedObjectContext.persistentStoreCoordinator = coordinator
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(mocDidSaveNotification), name: "NSManagedObjectContextDidSaveNotification", object: nil)
		return managedObjectContext
	}()

	func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
		let settings = NSUserDefaults.standardUserDefaults()
		let selectedStudentName = settings.stringForKey("selectedStudent")!
		var oldStudentAssignmentCount: Int = 0
        let moc = self.managedObjectContext
        let student: Student = moc.getObjectFromStore("Student", predicateString: "name == %@", args: [selectedStudentName]) as! Student
		for subject in student.subjects!.allObjects as! [Subject] {
			var mps = subject.markingPeriods!.allObjects as! [MarkingPeriod]
			mps = mps.filter { !$0.empty!.boolValue }

			for mp in mps {
				oldStudentAssignmentCount += mp.assignments!.count
			}
		}

		let _ = UpdateService(student: student, completionHandler: { successful, error in
			if (!successful) {
				self.managedObjectContext.deleteObject(student)
				completionHandler(UIBackgroundFetchResult.Failed)
			} else {
				var newStudentAssignmentCount: Int = 0
				let updatedStudent = moc.objectWithID(student.objectID) as! Student
				for subject in updatedStudent.subjects!.allObjects as! [Subject] {
					var mps = subject.markingPeriods!.allObjects as! [MarkingPeriod]
					mps = mps.filter { !$0.empty!.boolValue }

					for mp in mps {
						newStudentAssignmentCount += mp.assignments!.count
					}

				}

				if (newStudentAssignmentCount == oldStudentAssignmentCount) {
					UIApplication.sharedApplication().cancelAllLocalNotifications()
					let newNotification = UILocalNotification()
					let now = NSDate()
					newNotification.fireDate = now
					newNotification.alertBody = student.name!.componentsSeparatedByString(" ")[0] + "'s Grades Have Been Updated"
					newNotification.soundName = UILocalNotificationDefaultSoundName
					UIApplication.sharedApplication().scheduleLocalNotification(newNotification)
					completionHandler(UIBackgroundFetchResult.NewData)
				} else {
					completionHandler(UIBackgroundFetchResult.NoData)
				}
			}
		})

	}

	// MARK: - Core Data Saving support

	func saveContext() {
		if managedObjectContext.hasChanges {
			do {
				try managedObjectContext.save()
			} catch {
				// Replace this implementation with code to handle the error appropriately.
				// abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
				let nserror = error as NSError
				NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
				abort()
			}
		}
	}

	func mocDidSaveNotification(notification: NSNotification) {
		let savedContext = notification.object as! NSManagedObjectContext

		if (managedObjectContext == savedContext) {
			return
		}

		if (managedObjectContext.persistentStoreCoordinator != savedContext.persistentStoreCoordinator) {
			return
		}

		dispatch_async(dispatch_get_main_queue(), {
			self.managedObjectContext.mergeChangesFromContextDidSaveNotification(notification)
		})
	}

	func deleteAllUsers(moc: NSManagedObjectContext) {
		let users = moc.getObjectsFromStore("User", predicateString: nil, args: nil) as! [User]
		for u in users {
			moc.deleteObject(u)
			// print("Deleted: " + u.username!)
		}

		let settings = NSUserDefaults.standardUserDefaults()
		settings.setObject(nil, forKey: "selectedStudent")

		moc.saveContext()
	}
}

