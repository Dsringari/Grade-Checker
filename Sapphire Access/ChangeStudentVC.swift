//
//  ChangeStudentVC.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 5/25/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit

class ChangeStudentVC: UITableViewController {

	var students: [Student]?
	var selectedStudentName: String?
	var selectedStudentIndex: Int?

	var delegate: GradesVCDelegate!
    var settingsDelegate: SettingsVCDelegate!

	override func viewDidLoad() {
		super.viewDidLoad()

		// Uncomment the following line to preserve selection between presentations
		// self.clearsSelectionOnViewWillAppear = false

		// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
		// self.navigationItem.rightBarButtonItem = self.editButtonItem()

		let nv = tabBarController!.viewControllers![0] as! UINavigationController
		delegate = nv.viewControllers.first! as! GradesVC
        
        let nv2 = tabBarController!.viewControllers![3] as! UINavigationController
        settingsDelegate = nv2.viewControllers.first! as! SettingsVC

		students = Student.MR_findAll() as? [Student]
		students?.sortInPlace({ (s1: Student, s2: Student) in s1.grade! < s2.grade! })

		guard let students = self.students, let name = NSUserDefaults.standardUserDefaults().stringForKey("selectedStudent") else { return }
		let student = students.filter { $0.name! == name }[0]
		selectedStudentIndex = students.indexOf(student)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	// MARK: - Table view data source

	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if let count = students?.count {
			return count
		}

		return 0
	}

	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return "Students"
	}

	override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		return "Select a student to view their grades."
	}

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("studentCell", forIndexPath: indexPath) as! StudentCell
		cell.accessoryType = .None

		// Configure the cell...
		if let index = selectedStudentIndex {
			if indexPath.row == index {
				cell.accessoryType = .Checkmark
			}
		}

		if let students = students {
			cell.nameLabel.text = students[indexPath.row].name
		}

		return cell
	}

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		guard let selectedIndex = self.selectedStudentIndex, let students = self.students else { tableView.deselectRowAtIndexPath(indexPath, animated: true); return }

		if selectedIndex != indexPath.row {
			selectedStudentIndex = indexPath.row
			NSUserDefaults.standardUserDefaults().setObject(students[selectedStudentIndex!].name, forKey: "selectedStudent")
            settingsDelegate.changeSelectedStudentName(students[selectedStudentIndex!].name!)
			tableView.reloadData()
			view.userInteractionEnabled = false
			
            let dimView = UIView(frame: self.view.frame)
            dimView.backgroundColor = UIColor.blackColor()
            dimView.alpha = 0.6
            dimView.autoresizingMask = tableView.autoresizingMask
            view.layoutIfNeeded()
			UIView.animateWithDuration(0.5, animations: {
                self.view.addSubview(dimView)
			})
			delegate.reloadData({
				self.view.userInteractionEnabled = true
				UIView.animateWithDuration(0.5, animations: {
					dimView.removeFromSuperview()
                })
			})
		}

		tableView.deselectRowAtIndexPath(indexPath, animated: true)

	}
	/*
	 // MARK: - Navigation

	 // In a storyboard-based application, you will often want to do a little preparation before navigation
	 override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
	 // Get the new view controller using segue.destinationViewController.
	 // Pass the selected object to the new view controller.
	 }
	 */

}
