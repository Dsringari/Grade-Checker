//
//  SettingsVC.swift
//  Grade Checker
//
//  Created by Dhruv Sringari on 4/27/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit

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

		if (students.count == 1) {
			tableview.allowsSelection = false
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if section == 0 {
			return "Selected Student"
		}

		return "Touch ID"
	}
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if (section == 1) {
            return 50
        }
        return 0
    }

	func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {

		if (section == 1) {
			// Setup View
			let footerView = UIView(frame: CGRectMake(0, 0, tableView.frame.width, 50))
			let titleColor = UIColor(colorLiteralRed: 1, green: 1, blue: 1, alpha: 0.45) // Slightly Opaque
			// Setup Button
			logoutButton = UIButton(type: .Custom)
			logoutButton.setTitle("SIGN OUT", forState: .Normal)
			logoutButton.titleLabel!.font = UIFont.systemFontOfSize(21)
			logoutButton.addTarget(self, action: #selector(logout), forControlEvents: .TouchUpInside)
			logoutButton.setTitleColor(titleColor, forState: .Normal)
			logoutButton.setTitleColor(UIColor(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.45), forState: .Highlighted) // Make slighlty Darker
			logoutButton.backgroundColor = UIColor(colorLiteralRed: 22 / 255, green: 160 / 255, blue: 132 / 255, alpha: 1)
			logoutButton.frame = footerView.frame

			footerView.addSubview(logoutButton)
			return footerView
		}
		return nil
	}

	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 2
	}

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if (section == 0) {
			return students.count
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
		}
		touchIDCell = tableView.dequeueReusableCellWithIdentifier("touchIDCell", forIndexPath: indexPath) as! TouchIDSelectionCell
		touchIDCell.touchIDSwitch.on = settings.boolForKey("useTouchID")
		touchIDCell.selectionStyle = .None
		touchIDCell.touchIDSwitch.addTarget(self, action: #selector(changeTouchIDValue), forControlEvents: .ValueChanged)
		return touchIDCell
	}

	func logout() {
        

		self.tabBarController!.dismissViewControllerAnimated(true, completion: nil)
	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if (indexPath.section == 0) {
			selectedStudentIndex = indexPath.row
			settings.setObject(students[selectedStudentIndex].name!, forKey: "selectedStudent")
			self.tableview.reloadData()
			delegate.reloadData()
		}
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
	}

	func changeTouchIDValue() {
		settings.setBool(touchIDCell.touchIDSwitch.on, forKey: "useTouchID")
	}
}
