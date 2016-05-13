//
//  GradesVC.swift
//  Grade Checker
//
//  Created by Dhruv Sringari on 4/24/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit
import MagicalRecord
import CoreData

class GradesVC: UIViewController, UITableViewDelegate, UITableViewDataSource, SettingsVCDelegate {
	@IBOutlet var activityIndicator: UIActivityIndicatorView!
	@IBOutlet var activityView: UIView!
	@IBOutlet var tableview: UITableView!
	@IBOutlet var refreshButton: UIBarButtonItem!

	var student: Student!
	var subjects: [Subject]! = []
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var isRefreshing = false
	lazy var refreshControl: UIRefreshControl = {
		let refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: #selector(pullToRefresh), forControlEvents: .ValueChanged)
        refreshControl.tintColor = UIColor.whiteColor()
		return refreshControl
	}()

	var selectedSubject: Subject!

	override func viewDidLoad() {
		super.viewDidLoad()
		tableview.delegate = self
		tableview.dataSource = self
		tableview.addSubview(refreshControl)
        
        if let student = Student.MR_findFirstByAttribute("name", withValue: NSUserDefaults.standardUserDefaults().stringForKey("selectedStudent")!) {
            self.student = student
        }
        
		loadStudent()
	}
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(refreshTableView), name: UIApplicationDidBecomeActiveNotification, object: UIApplication.sharedApplication())
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func refreshTableView() {
        let settings = NSUserDefaults.standardUserDefaults()
        if settings.boolForKey("updatedInBackground") {
            settings.setBool(false, forKey: "updatedInBackground")
            NSManagedObjectContext.MR_defaultContext().refreshObject(student, mergeChanges: false)
            self.tableview.reloadData()
        }
    }

	func reloadData() {
		let selectedStudentName = NSUserDefaults.standardUserDefaults().stringForKey("selectedStudent")!
		let student = Student.MR_findFirstWithPredicate(NSPredicate(format: "name == %@", argumentArray: [selectedStudentName]))
		self.student = student
		loadStudent()
	}

	func loadStudent() {
		self.navigationItem.title = student.name!.componentsSeparatedByString(" ")[0] + "'s Grades" // Get the first name and set it as the title
		startLoading()
        isRefreshing = true
		let _ = UpdateService(studentID: student.objectID, completionHandler: { successful, error in
			if (successful) {
				dispatch_async(dispatch_get_main_queue(), {
					NSManagedObjectContext.MR_defaultContext().refreshObject(self.student, mergeChanges: false)
					self.tableview.reloadData()
					self.updateRefreshControl()
					self.stopLoading()
					let notificationSettings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
					UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
                    self.isRefreshing = false
				})
			} else {
				dispatch_async(dispatch_get_main_queue(), {
					self.stopLoading()
					var err = error
					if (error!.code == NSURLErrorTimedOut) {
						err = badConnectionError
					}
					let alert = UIAlertController(title: err!.localizedDescription, message: err!.localizedFailureReason, preferredStyle: .Alert)
					alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                    self.isRefreshing = false
				})
			}
		})
	}

	@IBAction func refresh(sender: AnyObject) {
		if !isRefreshing {
			refreshButton.enabled = false
            isRefreshing = true
            refreshControl.beginRefreshing()
            tableview.userInteractionEnabled = false
            tableview.setContentOffset(CGPointMake(0, -refreshControl.frame.size.height), animated: true)
            let _ = UpdateService(studentID: student.objectID, completionHandler: { successful, error in
				if (successful) {
					dispatch_async(dispatch_get_main_queue(), {
						// Refresh the ui's student object
						NSManagedObjectContext.MR_defaultContext().refreshObject(self.student, mergeChanges: false)

						self.tableview.reloadData()
						self.updateRefreshControl()
                        
                        self.refreshControl.endRefreshing()
						self.refreshButton.enabled = true
                        self.isRefreshing = false
                        self.tableview.userInteractionEnabled = true
					})
				} else {
					dispatch_async(dispatch_get_main_queue(), {
                        self.refreshControl.endRefreshing()
                        self.refreshButton.enabled = true
                        self.isRefreshing = false
						var err = error
						if (error!.code == NSURLErrorTimedOut) {
							err = badConnectionError
						}
						let alert = UIAlertController(title: err!.localizedDescription, message: err!.localizedFailureReason, preferredStyle: .Alert)
						alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
                        self.presentViewController(alert, animated: true, completion: nil)
                        self.tableview.userInteractionEnabled = false
					})
				}
			})
		}
	}

	func pullToRefresh() {
		if !isRefreshing {
            isRefreshing = true
            refreshButton.enabled = false
            tableview.userInteractionEnabled = false
			let _ = UpdateService(studentID: student.objectID, completionHandler: { successful, error in
				if (successful) {
					dispatch_async(dispatch_get_main_queue(), {
						// Refresh the ui's student object
						NSManagedObjectContext.MR_defaultContext().refreshObject(self.student, mergeChanges: false)
						self.tableview.reloadData()
						self.updateRefreshControl()
						self.refreshControl.endRefreshing()
                        self.isRefreshing = false
                        self.refreshButton.enabled = true
                        self.tableview.userInteractionEnabled = true
					})
				} else {
					dispatch_async(dispatch_get_main_queue(), {
						self.refreshControl.endRefreshing()
                        self.isRefreshing = false
                        self.refreshButton.enabled = true
						var err = error
						if (error!.code == NSURLErrorTimedOut) {
							err = badConnectionError
						}
						let alert = UIAlertController(title: err!.localizedDescription, message: err!.localizedFailureReason, preferredStyle: .Alert)
						alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
                        self.presentViewController(alert, animated: true, completion: nil)
                        self.tableview.userInteractionEnabled = true
					})
				}
			})
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if (student.subjects!.count == 0) {
			return 0
		}
		subjects = student.subjects!.allObjects as! [Subject]

		// Remove invalid subjects
		for subject in subjects {
			var mps = subject.markingPeriods!.allObjects as! [MarkingPeriod]
			mps = mps.filter { !$0.empty!.boolValue } // filter marking periods with no assignments

//			for mp in mps {
//				print(mp.subject!.name! + " " + mp.number!)
//			}

			if mps.count == 0 { // Don't show subject if all the marking periods are empty
				subjects.removeObject(subject)
				continue
			}

			mps.sortInPlace { Int($0.number!) > Int($1.number!) } // sort marking periods by descending number
			let recentMP = mps[0]
			let percentgradeString = recentMP.percentGrade!.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "1234567890.").invertedSet).joinWithSeparator("")

			if (percentgradeString == "") { // Don't show subject if the most recent marking period with assignments has zero percent grade or strange grading
				subjects.removeObject(subject)
			}
		}

		// Sort by Most Recently Updated
        subjects.sortInPlace({ (s1: Subject, s2: Subject) -> Bool in
            let s1MostRecentDate: NSDate
            let s2MostRecentDate: NSDate
            
            if let date = s1.lastUpdated {
                s1MostRecentDate = date
            } else {
                s1MostRecentDate = s1.mostRecentAssignment!.dateCreated!
            }
            
            if let date = s2.lastUpdated {
                s2MostRecentDate = date
            } else {
                s2MostRecentDate = s2.mostRecentAssignment!.dateCreated!
            }
            
            if (s1MostRecentDate.compare(s2MostRecentDate) == NSComparisonResult.OrderedSame) {
                return s1.name < s2.name
            }
            
            return s1MostRecentDate.compare(s2MostRecentDate) == NSComparisonResult.OrderedDescending
            
        })
		return subjects.count
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("subjectCell", forIndexPath: indexPath) as! SubjectTableViewCell

		let subject: Subject = subjects[indexPath.row]

		cell.subjectNameLabel.text = subject.name

		var markingPeriods: [MarkingPeriod] = subjects[indexPath.row].markingPeriods!.allObjects as! [MarkingPeriod]

		// sort marking periods by descending number and ignore empty marking periods
		markingPeriods = markingPeriods.filter { !$0.empty!.boolValue }.sort { Int($0.number!) > Int($1.number!) }

		if (markingPeriods.count == 0) {

		}
		let recentMP = markingPeriods[0]

		// Remove %
		let percentgradeString = recentMP.percentGrade!.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "1234567890.").invertedSet).joinWithSeparator("")

		// Round the percent to the nearest whole number
		let numberFormatter = NSNumberFormatter()
		let percentGradeDouble = numberFormatter.numberFromString(percentgradeString)!.doubleValue
		let roundedPercentGrade: Int = Int(round(percentGradeDouble))

		//cell.letterGradeLabel.text = self.percentToLetterGrade(roundedPercentGrade)
		cell.percentGradeLabel.text = String(roundedPercentGrade) + "%"
        
        if let date = subject.lastUpdated {
            cell.lastUpdatedLabel.text = "Last Updated: " + relativeDateStringForDate(date)
        } else {
            cell.lastUpdatedLabel.text = "Last Updated: " + relativeDateStringForDate(subject.mostRecentAssignment!.dateCreated!)
        }
        


		// cell.backgroundColor = lightB
		return cell
	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		selectedSubject = subjects[indexPath.row]
		performSegueWithIdentifier("subjectView", sender: nil)
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
	}

	func updateRefreshControl() {
		// set the refresh control's title
		let formatter: NSDateFormatter = NSDateFormatter()
		formatter.dateFormat = "MMM d, h:mm a"
		let title = "Last Update: " + formatter.stringFromDate(NSDate())
		let attributedTitle = NSAttributedString(string: title, attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])
		self.refreshControl.attributedTitle = attributedTitle
	}

	func percentToLetterGrade(percentGrade: Int) -> String {
		switch percentGrade {
		case 0 ... 59:
			return "F"
		case 60 ... 69:
			return "D"
		case 70 ... 79:
			return "C"
		case 80 ... 89:
			return "B"
		case 90 ... 100:
			return "A"
		default:
			return "A"
		}
	}

	func startLoading() {
		activityIndicator.startAnimating()
		activityView.hidden = false
		refreshButton.enabled = false
	}

	func stopLoading() {
		activityIndicator.stopAnimating()
		activityView.hidden = true
		refreshButton.enabled = true
	}

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if (segue.identifier == "subjectView") {
			let sV = segue.destinationViewController as! DetailVC
			sV.subject = selectedSubject
			self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
		}
	}
}
