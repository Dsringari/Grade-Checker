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
import Firebase
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.

		// Set default preferences
        let appDefaults = ["useTouchID": false, "sortMethod": NSNumber(value: Sorting.recent.rawValue as Int)]
		UserDefaults.standard.register(defaults: appDefaults)
        
        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.gray], for: UIControlState())
        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor(red: 43, green: 130, blue: 201)], for: .selected)
        
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        
		// Start the Magic!
		MagicalRecord.setLoggingLevel(.warn)
		MagicalRecord.setShouldDeleteStoreOnModelMismatch(true)
        MagicalRecord.setupCoreDataStack()

		FirebaseApp.configure()

		return true
	}

	func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.


		var tabBarController: UITabBarController?
		if let containerVC = UIApplication.shared.keyWindow?.rootViewController as? ContainerVC {
			if let navigationController = containerVC.currentViewController as? UINavigationController {
				tabBarController = navigationController.visibleViewController as? UITabBarController
			}
		}
        
        if UserDefaults.standard.bool(forKey: "useTouchID") {
            if let mainTabBarController = tabBarController {
                mainTabBarController.selectedIndex = 0
                if let nVC = mainTabBarController.viewControllers?.first as? UINavigationController {
                    if let gradesVC = nVC.visibleViewController as? GradesVC {
                        gradesVC.performSegue(withIdentifier: "lock", sender: nil)
                    }
                }
            }
        }
        
        
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
		MagicalRecord.cleanUp()
	}
}

