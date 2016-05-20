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
import GoogleMobileAds

protocol GradesVCDelegate {
    func logout() -> Void
    func reloadData(completionHandler: () -> Void)
}

class GradesVC: UIViewController, UITableViewDelegate, UITableViewDataSource, GADBannerViewDelegate, GradesVCDelegate {
	@IBOutlet var activityIndicator: UIActivityIndicatorView!
	@IBOutlet var activityView: UIView!
	@IBOutlet var tableview: UITableView!
	@IBOutlet var refreshButton: UIBarButtonItem!
	@IBOutlet var adView: GADBannerView!
	@IBOutlet var tableViewBottomConstraint: NSLayoutConstraint!

	var settingsCompletionHandler: (() -> Void)!

	var student: Student!
	var subjects: [Subject]?
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

		adView.adSize = kGADAdSizeSmartBannerPortrait
		adView.adUnitID = "ca-app-pub-9355707484240783/4024228355"
		adView.rootViewController = self
		adView.delegate = self
		adView.loadRequest(GADRequest())

		if let student = Student.MR_findFirstByAttribute("name", withValue: NSUserDefaults.standardUserDefaults().stringForKey("selectedStudent")!) {
			self.student = student
			loadStudent()
		}

	}
    
    func logout() {
        User.MR_deleteAllMatchingPredicate(NSPredicate(value: true))
        NSManagedObjectContext.MR_defaultContext().MR_saveToPersistentStoreAndWait()
        
        NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "selectedStudent")
        self.tabBarController!.navigationController!.popToRootViewControllerAnimated(false)
        NSNotificationCenter.defaultCenter().postNotificationName("tabBarDismissed", object: nil)
    }

	func adViewDidReceiveAd(bannerView: GADBannerView!) {
		tableViewBottomConstraint.constant = 50
		UIView.animateWithDuration(0.5, animations: {
			self.view.addSubview(self.adView)

			if #available(iOS 9.0, *) {
				self.adView.bottomAnchor.constraintEqualToAnchor(self.bottomLayoutGuide.topAnchor)
			} else {
				// Fallback on earlier versions
				NSLayoutConstraint.constraintsWithVisualFormat("V:|[adView]|", options: [], metrics: nil, views: ["adView": self.adView])
			}

			NSLayoutConstraint.constraintsWithVisualFormat("|-0-[adView]-0-|", options: [], metrics: nil, views: ["adView": self.adView])
			self.view.layoutIfNeeded()
		})
	}

	func adView(bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
		print(error)
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

	func reloadData(completionHandler: () -> Void) {
		settingsCompletionHandler = completionHandler
		let selectedStudentName = NSUserDefaults.standardUserDefaults().stringForKey("selectedStudent")!
		let student = Student.MR_findFirstWithPredicate(NSPredicate(format: "name == %@", argumentArray: [selectedStudentName]))
		self.student = student
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(callSettingsCompletionHandler), name: "doneReloading", object: nil)
		loadStudent()
	}

	func callSettingsCompletionHandler() {
		settingsCompletionHandler()
	}

	func loadStudent() {
        subjects = nil
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
					NSNotificationCenter.defaultCenter().postNotificationName("doneReloading", object: nil)
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
					NSNotificationCenter.defaultCenter().postNotificationName("doneReloading", object: nil)
				})
			}
		})
	}

	@IBAction func refresh(sender: AnyObject) {
        
         if !isRefreshing {
            subjects = nil
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
            subjects = nil
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
		guard let sMOs = student.subjects?.allObjects as? [Subject] else {
			return 0
		}

		subjects = sMOs

		// Remove invalid subjects
		for subject in subjects! {
			var mps = subject.markingPeriods!.allObjects as! [MarkingPeriod]
			mps = mps.filter { !$0.empty!.boolValue } // filter marking periods with no assignments

//			for mp in mps {
//				print(mp.subject!.name! + " " + mp.number!)
//			}

			if mps.count == 0 { // Don't show subject if all the marking periods are empty
				subjects!.removeObject(subject)
				continue
			}

			mps.sortInPlace { Int($0.number!) > Int($1.number!) } // sort marking periods by descending number
			let recentMP = mps[0]
			let percentgradeString = recentMP.percentGrade!.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "1234567890.").invertedSet).joinWithSeparator("")

			if (percentgradeString == "") { // Don't show subject if the most recent marking period with assignments has zero percent grade or strange grading
				subjects!.removeObject(subject)
			}
		}

		// Sort by Most Recently Updated
		subjects!.sortInPlace({ (s1: Subject, s2: Subject) -> Bool in

			guard s1.mostRecentDate != nil || s2.mostRecentDate != nil else {
				if s1.mostRecentDate == nil && s2.mostRecentDate == nil {
					return s1.name < s2.name
				}

				if s1.mostRecentDate == nil {
					return true
				}

				return false
			}

			if (s1.mostRecentDate!.compare(s2.mostRecentDate!) == NSComparisonResult.OrderedSame) {
				return s1.name < s2.name
			}

			return s1.mostRecentDate!.compare(s2.mostRecentDate!) == NSComparisonResult.OrderedDescending

		})
		return subjects!.count
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		if (!isRefreshing) {
			let cell = tableView.dequeueReusableCellWithIdentifier("subjectCell", forIndexPath: indexPath) as! SubjectTableViewCell

            if let subject = subjects?[indexPath.row] {
				cell.subjectNameLabel.text = subject.name

				var markingPeriods: [MarkingPeriod] = subjects![indexPath.row].markingPeriods!.allObjects as! [MarkingPeriod]

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

				// cell.letterGradeLabel.text = self.percentToLetterGrade(roundedPercentGrade)
				cell.percentGradeLabel.text = String(roundedPercentGrade) + "%"

				let dateString: String
				if let date = subject.mostRecentDate {
					dateString = relativeDateStringForDate(date)
				} else {
					dateString = "N/A"
				}

				cell.lastUpdatedLabel.text = "Last Updated: " + dateString

				// cell.backgroundColor = lightB
				return cell

			}
            
            return UITableViewCell()

		}
		return UITableViewCell()
	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		selectedSubject = subjects![indexPath.row]
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
        } else if segue.identifier == "lock" {
            let lockVC = segue.destinationViewController as! LockVC
            lockVC.delegate = self
        }
	}
}
