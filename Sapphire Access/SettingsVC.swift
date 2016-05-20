//
//  SettingsVC.swift
//  Grade Checker
//
//  Created by Dhruv Sringari on 4/27/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit
import MagicalRecord
import CoreData
import LocalAuthentication

class SettingsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
	@IBOutlet var tableview: UITableView!
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var touchIDCell: TouchIDSelectionCell!
	var logoutButton: UIButton!

	var students: [Student]!
	var selectedStudentIndex: Int!
	let settings = NSUserDefaults.standardUserDefaults()
	lazy var hasTouchID: Bool = {
		return LAContext().canEvaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, error: nil)
	}()

	var shouldRefresh: Bool = true

	var delegate: GradesVCDelegate!

	override func viewDidLoad() {
		super.viewDidLoad()
        
		tableview.delegate = self
		tableview.dataSource = self
        tableview.rowHeight = 44
        
		let nv = tabBarController!.viewControllers![0] as! UINavigationController
		delegate = nv.viewControllers.first! as! GradesVC

		students = Student.MR_findAll() as! [Student]

		students.sortInPlace { $0.grade! > $1.grade! } // Sort By Grade

		if let selectedStudent = settings.stringForKey("selectedStudent") {
			let student = students.filter { $0.name! == selectedStudent }[0]
			selectedStudentIndex = students.indexOf(student)
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if section == 0 {
			return "Selected Student"
		} else if section == 1 {
			return "Sign In"
		}

		return nil
	}

	func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		if (section == 1) {
			return "Touch ID can be used for a more secure login."
		}

		return nil
	}

	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 4
	}

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if (section == 0) {
			return students.count
		}

		return 1
	}
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44
    }

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		if indexPath.section == 0 {
			let studentCell = tableView.dequeueReusableCellWithIdentifier("selectStudentCell", forIndexPath: indexPath) as! StudentSelectionCell
			studentCell.nameLabel.text = students[indexPath.row].name

			if (indexPath.row == selectedStudentIndex) {
				studentCell.accessoryType = .Checkmark
			} else {
				studentCell.accessoryType = .None
			}
			return studentCell
		} else if indexPath.section == 1 {
			if (indexPath.row == 0) {
				touchIDCell = tableView.dequeueReusableCellWithIdentifier("touchIDCell", forIndexPath: indexPath) as! TouchIDSelectionCell
				touchIDCell.touchIDSwitch.on = settings.boolForKey("useTouchID")
				touchIDCell.touchIDSwitch.enabled = hasTouchID
				touchIDCell.textLabel?.enabled = hasTouchID
				touchIDCell.selectionStyle = .None
				touchIDCell.touchIDSwitch.addTarget(self, action: #selector(changeTouchIDValue), forControlEvents: .ValueChanged)
				return touchIDCell
			}
		} else if indexPath.section == 2 {
			let aboutCell = tableView.dequeueReusableCellWithIdentifier("aboutCell", forIndexPath: indexPath)
			return aboutCell
		}

		let logoutCell = tableView.dequeueReusableCellWithIdentifier("logOutCell", forIndexPath: indexPath) as! LogOutCell
		logoutButton = logoutCell.logoutButton
		logoutButton.addTarget(self, action: #selector(logout), forControlEvents: .TouchUpInside)
		return logoutCell

	}

	func logout() {
		User.MR_deleteAllMatchingPredicate(NSPredicate(value: true))
		NSManagedObjectContext.MR_defaultContext().MR_saveToPersistentStoreAndWait()

		NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "selectedStudent")
		self.tabBarController!.navigationController!.popToRootViewControllerAnimated(true)
		NSNotificationCenter.defaultCenter().postNotificationName("tabBarDismissed", object: nil)

	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if (shouldRefresh) {
			if (indexPath.section == 0) {
				if (selectedStudentIndex != indexPath.row) {
					selectedStudentIndex = indexPath.row
					settings.setObject(students[selectedStudentIndex].name!, forKey: "selectedStudent")
					self.tableview.reloadData()
                    shouldRefresh = false
                    delegate.reloadData({
                        self.shouldRefresh = true
                    })
				}
			}
		}
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
	}

	func changeTouchIDValue() {
		if (touchIDCell.touchIDSwitch.on) {
			let context = LAContext()

			context.evaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, localizedReason: "Touch ID to Verify", reply: { (success: Bool, error: NSError?) in
				dispatch_async(dispatch_get_main_queue(), {

					if (success) {

						self.settings.setBool(true, forKey: "useTouchID")

					} else {

						self.settings.setBool(false, forKey: "useTouchID")
						self.touchIDCell.touchIDSwitch.setOn(false, animated: true)
						if (error!.code == LAError.AuthenticationFailed.rawValue) {

							let failed = UIAlertController(title: "Failed to Verify", message: "Your fingerprint did not match. Touch ID is disabled.", preferredStyle: .Alert)
							let Ok = UIAlertAction(title: "OK", style: .Default, handler: nil)
							failed.addAction(Ok)
							self.presentViewController(failed, animated: true, completion: nil)

							return
						}
					}
				})
			})

		} else {
			self.settings.setBool(false, forKey: "useTouchID")
		}
	}
}
