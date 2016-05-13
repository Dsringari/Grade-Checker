//
//  SelectStudentVC.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 5/12/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit

class SelectStudentVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

	@IBOutlet var tableView: UITableView!
	var touchIDSwitch: UISwitch!
	var students: [Student]!
	var selectedIndex: Int?

    @IBOutlet var continueButton: UIButton!
	override func viewDidLoad() {
		super.viewDidLoad()
		students = Student.MR_findAll() as! [Student]

		if (students.count == 1) {
			selectedIndex = 0
		}

		students.sortInPlace({ (s1, s2) -> Bool in

			if let g1 = s1.grade, g2 = s2.grade {
				return g1 > g2
			} else if (s1.grade == nil) {
				return true
			} else {
				return false
			}

		})

		if let name = NSUserDefaults.standardUserDefaults().stringForKey("selectedStudent") {
			if let student = students.filter({ $0.name == name }).first {
				selectedIndex = students.indexOf(student)
			}
		}

		tableView.delegate = self
		tableView.dataSource = self

		tableView.cellLayoutMarginsFollowReadableWidth = false
        willDisableContinueButton()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 2
	}

	func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 22
	}

	func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let headerView = UIView(frame: CGRectMake(0, 0, self.view.frame.size.width, 22))
		headerView.backgroundColor = UIColor(colorLiteralRed: 16 / 255, green: 148 / 255, blue: 211 / 255, alpha: 1)

		let label = UILabel(frame: CGRectMake(15, 0, self.view.frame.size.width - 15, 22))
		label.textColor = UIColor.whiteColor()
		label.font = UIFont.systemFontOfSize(13)
		label.autoresizingMask = .FlexibleWidth

		if section == 0 {
			label.text = "SELECT A STUDENT"
		} else {
			label.text = "TOUCH ID"
		}

		headerView.addSubview(label)
		return headerView
	}

	func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		if section == 0 {
			return UITableViewAutomaticDimension + 75
		}
		return 22
	}

	func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		if section == 0 {
			let footerView = UIView(frame: CGRectMake(0, 0, self.view.frame.size.width, 100))
			footerView.backgroundColor = UIColor(colorLiteralRed: 16 / 255, green: 148 / 255, blue: 211 / 255, alpha: 1)

			let label = UILabel(frame: CGRectMake(30, 0, self.view.frame.size.width - 30, 40))
			label.textColor = UIColor.whiteColor()
			label.font = UIFont.systemFontOfSize(13)
			label.numberOfLines = 0
			label.text = "Select a student to view their grades. You can change this later in settings."

			footerView.addSubview(label)
			return footerView
		}

		let footerView = UIView(frame: CGRectMake(0, 0, self.view.frame.size.width, 22))
		footerView.backgroundColor = UIColor(colorLiteralRed: 16 / 255, green: 148 / 255, blue: 211 / 255, alpha: 1)

		let label = UILabel(frame: CGRectMake(30, 0, self.view.frame.size.width - 30, 22))
		label.textColor = UIColor.whiteColor()
		label.font = UIFont.systemFontOfSize(13)
		label.autoresizingMask = .FlexibleWidth
		label.text = "Touch ID may be used for a more secure login."

		footerView.addSubview(label)
		return footerView

	}

	func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
		if let footerView = view as? UITableViewHeaderFooterView {
			footerView.tintColor = UIColor(colorLiteralRed: 16 / 255, green: 148 / 255, blue: 211 / 255, alpha: 1)
			footerView.textLabel?.textColor = UIColor.whiteColor()
		}
	}

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 0 {
			return students.count
		}

		return 1
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		if indexPath.section == 0 {
			let cell = UITableViewCell(style: .Default, reuseIdentifier: "selectStudentCell")
			cell.textLabel?.text = students[indexPath.row].name

			if (indexPath.row == selectedIndex) {
				cell.accessoryType = .Checkmark
			} else {
				cell.accessoryType = .None
			}
			cell.removeMargins()
			return cell
		}

		let cell = tableView.dequeueReusableCellWithIdentifier("touchIDCell", forIndexPath: indexPath) as! TouchIDSelectionCell
		cell.selectionStyle = .None
		touchIDSwitch = cell.touchIDSwitch
		return cell

	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if (indexPath.section == 0) {
			if let index = selectedIndex {
				tableView.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0))?.accessoryType = .None
			}
			tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = .Checkmark
			selectedIndex = indexPath.row
		}

		tableView.deselectRowAtIndexPath(indexPath, animated: true)
        willDisableContinueButton()
	}
    
    func willDisableContinueButton() {
        if (selectedIndex == nil) {
            continueButton.enabled = false
        } else {
            continueButton.enabled = true
        }
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

public class SegueFromLeft: UIStoryboardSegue {

	override public func perform() {
		let src = self.sourceViewController
		let dst = self.destinationViewController

		src.view.superview?.insertSubview(dst.view, aboveSubview: src.view)
		dst.view.transform = CGAffineTransformMakeTranslation(-src.view.frame.size.width, 0)

		UIView.animateWithDuration(0.25,
			delay: 0.0,
			options: UIViewAnimationOptions.CurveEaseInOut,
			animations: {
				dst.view.transform = CGAffineTransformMakeTranslation(0, 0)
			},
			completion: { finished in
				src.presentViewController(dst, animated: false, completion: nil)
			}
		)
	}

}
