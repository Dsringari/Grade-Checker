//
//  AppDelegate.swift
//  Grade Checker
//
//  Created by Dhruv Sringari on 3/8/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit
import CoreData
import MagicalRecord

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
        
        MagicalRecord.setupAutoMigratingCoreDataStack()
		return true
	}

	func application(application: UIApplication, willFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		let settings = NSUserDefaults.standardUserDefaults()
		if (settings.stringForKey("selectedStudent") != nil) {
			UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(NSTimeInterval(300)) // 5 min
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
        MagicalRecord.cleanUp()
	}

	

	func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
		let settings = NSUserDefaults.standardUserDefaults()
		let selectedStudentName = settings.stringForKey("selectedStudent")!
		let oldStudentAssignmentCount: Int = Assignment.MR_numberOfEntities().integerValue
        let student: Student = Student.MR_findFirstByAttribute("name", withValue: selectedStudentName)!
        print(student.name!)

		let _ = UpdateService(studentID: student.objectID, completionHandler: { successful, error in
			if (!successful) {
				student.MR_deleteEntity()
				completionHandler(UIBackgroundFetchResult.Failed)
			} else {
				let newStudentAssignmentCount: Int = Assignment.MR_numberOfEntities().integerValue
                
                let updatedAssignments = Assignment.MR_findAllWithPredicate(NSPredicate(format: "hadChanges == %@", argumentArray: [true])) as! [Assignment]


				if (newStudentAssignmentCount != oldStudentAssignmentCount || !updatedAssignments.isEmpty) {
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

	// TODO: Be able to delete all users
}

