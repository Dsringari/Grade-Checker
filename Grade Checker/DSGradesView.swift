//
//  DSGradesView.swift
//  Grade Checker
//
//  Created by Dhruv Sringari on 4/21/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit

class DSGradesView: UIViewController, UITableViewDelegate, UITableViewDataSource {
	@IBOutlet var tableView: UITableView!

	var student: Student!

	// This is the Indicator that will show while the app retrieves all the required data
	let activityAlert = UIAlertController(title: "Logging In\n", message: nil, preferredStyle: .Alert)
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    
    let lightB = UIColor(red: 57/255, green: 125/255, blue: 192/255, alpha: 1.0)
   

	override func viewDidLoad() {
		super.viewDidLoad()

		// add the spinning indicator to the loading alert
		let indicator = UIActivityIndicatorView()
		indicator.translatesAutoresizingMaskIntoConstraints = false
		indicator.color = UIColor.blackColor()
		activityAlert.view.addSubview(indicator)

		let views = ["pending": activityAlert.view, "indicator": indicator]
		var constraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[indicator]-(10)-|", options: NSLayoutFormatOptions.AlignAllCenterX, metrics: nil, views: views)
		constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|[indicator]|", options: NSLayoutFormatOptions.AlignAllCenterX, metrics: nil, views: views)
		activityAlert.view.addConstraints(constraints)

		indicator.userInteractionEnabled = false
		indicator.startAnimating()
	}
    
    override func viewDidAppear(animated: Bool) {
        self.presentViewController(activityAlert, animated: true, completion: nil)
        let _ = UpdateService(student: student, completionHandler: { succesful, error in
            if (succesful) {
                let moc = self.appDelegate.managedObjectContext
                let updatedStudent = moc.objectWithID(self.student.objectID) as! Student
                self.student = updatedStudent
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.tableView.reloadData()
                    self.activityAlert.dismissViewControllerAnimated(false, completion: nil)
                })
                
            } else {
                // TODO: Add proper error handling here
                print("something bad happened")
                abort()
            }
        })
    }

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	// MARK: - Table view data source

	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		// #warning Incomplete implementation, return the number of sections
		return 1
	}

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// #warning Incomplete implementation, return the number of rows
		return student.subjects!.count
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("subjectCell", forIndexPath: indexPath) as! SubjectTableViewCell

		// Configure the cell...
        var subjects = student.subjects!.allObjects as! [Subject]
        subjects.sortInPlace{$0.name! < $1.name!}
		cell.subjectNameLabel.text = subjects[indexPath.row].name
        
        // Get most recent marking period
        var markingPeriods: [MarkingPeriod] = subjects[indexPath.row].markingPeriods!.allObjects as! [MarkingPeriod]
        // remove empty marking periods
        for mp in markingPeriods {
            if mp.empty!.boolValue {
                markingPeriods.removeObject(mp)
            }
        }
        if markingPeriods.count == 0 {
            cell.letterGradeLabel.text = "N/A"
           // cell.numericGradeLabel.text = "0/0"
            return cell
        }
        // sort marking periods by descending number
        markingPeriods = markingPeriods.sort {Int($0.number!) > Int($1.number!)}
        let recentMP = markingPeriods[0]
        cell.letterGradeLabel.text = self.percentToLetterGrade(recentMP.percentGrade!)
       // cell.numericGradeLabel.text = recentMP.totalPoints! + "/" + recentMP.possiblePoints!
        
      //  cell.backgroundColor = lightB
		return cell
	}

	func percentToLetterGrade(string: String) -> String {
		// Remove %
		let gradeString = string.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "1234567890.").invertedSet).joinWithSeparator("")
		// If we have an empty marking period or strange grading
		if gradeString == "" {
			return ""
		}

		let numberFormatter = NSNumberFormatter()
		numberFormatter.roundingMode = .RoundHalfUp
		let percentGrade = numberFormatter.numberFromString(gradeString)!
		let percentGradeDouble = percentGrade.doubleValue

		switch percentGradeDouble {
		case 0 ... 59:
			return "F"
		case 60 ... 64:
			return "D-"
		case 65 ... 69:
			return "D+"
		case 70 ... 74:
			return "C-"
		case 75 ... 79:
			return "C+"
		case 80 ... 84:
			return "B-"
		case 85 ... 89:
			return "B+"
		case 90 ... 94:
			return "A-"
		case 95 ... 100:
			return "A+"
		default:
			return "A+"
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
