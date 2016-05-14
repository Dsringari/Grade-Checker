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

protocol SettingsVCDelegate {
	func reloadData() -> Void
}

class SettingsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
	@IBOutlet var tableview: UITableView!
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var touchIDCell: TouchIDSelectionCell!
	var logoutButton: UIButton!

	var students: [Student]!
	var selectedStudentIndex: Int!
	let settings = NSUserDefaults.standardUserDefaults()

	var delegate: SettingsVCDelegate!

	override func viewDidLoad() {
		super.viewDidLoad()
		self.tableview.delegate = self
		self.tableview.dataSource = self
		let nv = self.tabBarController!.viewControllers![0] as! UINavigationController
		delegate = nv.viewControllers.first! as! GradesVC

		students = Student.MR_findAll() as! [Student]

		students.sortInPlace { $0.grade! > $1.grade! } // Sort By Grade

		if let selectedStudent = settings.stringForKey("selectedStudent") {
			let student = students.filter { $0.name! == selectedStudent }[0]
			selectedStudentIndex = students.indexOf(student)
		}

		/*
		 if (students.count == 1) {
            tableview.allowsSelection = false
		 }
		 */
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if section == 0 {
			return "Selected Student"
		} else if section == 1 {
			return "Account"
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
		return 3
	}

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if (section == 0) {
			return students.count
        } else if section == 1 {
            return 2
        }

		return 1
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
                touchIDCell.selectionStyle = .None
                touchIDCell.touchIDSwitch.addTarget(self, action: #selector(changeTouchIDValue), forControlEvents: .ValueChanged)
                return touchIDCell
            } else {
                let logoutCell = tableView.dequeueReusableCellWithIdentifier("logOutCell", forIndexPath: indexPath) as! LogOutCell
                logoutButton = logoutCell.logoutButton
                logoutButton.addTarget(self, action: #selector(logout), forControlEvents: .TouchUpInside)
                return logoutCell
            }
        }

		let aboutCell = tableView.dequeueReusableCellWithIdentifier("aboutCell", forIndexPath: indexPath)
		return aboutCell
	}

	func logout() {
		User.MR_deleteAllMatchingPredicate(NSPredicate(value: true))
		NSManagedObjectContext.MR_defaultContext().MR_saveToPersistentStoreAndWait()
		
        self.view.window?.rootViewController?.dismissViewControllerAnimated(true, completion: nil)
        let loginViewController = self.storyboard!.instantiateViewControllerWithIdentifier("loginVC")
        UIApplication.sharedApplication().keyWindow?.rootViewController = loginViewController
    }

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if (indexPath.section == 0) {
            if (selectedStudentIndex != indexPath.row) {
                selectedStudentIndex = indexPath.row
                settings.setObject(students[selectedStudentIndex].name!, forKey: "selectedStudent")
                self.tableview.reloadData()
                delegate.reloadData()
            }
		}
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
	}

	func changeTouchIDValue() {
		settings.setBool(touchIDCell.touchIDSwitch.on, forKey: "useTouchID")
	}
}
