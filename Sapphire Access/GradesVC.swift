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
	func studentChanged(completionHandler: () -> Void)
}

enum Badge {
	case Updated
	case Mock
	case Both
}

enum PopUpViewType {
    case loading
    case noInternet
    case noGrades
}

class GradesVC: UIViewController, UITableViewDelegate, UITableViewDataSource, GADBannerViewDelegate, GradesVCDelegate {
	@IBOutlet var activityIndicator: UIActivityIndicatorView!
	@IBOutlet var popUpView: UIView!
    @IBOutlet var popUpViewText: UILabel!
    @IBOutlet var popUpViewButton: UIButton!
	@IBOutlet var adView: GADBannerView!
	@IBOutlet var tableViewBottomConstraint: NSLayoutConstraint!

    
	var settingsCompletionHandler: (() -> Void)!

	// Create an instance of a UITableViewController. This will host the tableview in order to solve uirefreshcontrol bugs
	private let tableViewController = UITableViewController()
	@IBOutlet var tableview: UITableView!

	var student: Student!
	var subjects: [Subject]?
	var badges: [Int: Badge] = [:]
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	lazy var refreshControl: UIRefreshControl = {
		let refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: #selector(pullToRefresh), forControlEvents: .ValueChanged)
		refreshControl.tintColor = UIColor.lightGrayColor()
		return refreshControl
	}()

	var selectedSubject: Subject!

	override func viewDidLoad() {
		super.viewDidLoad()

		// Setup Tableview
		tableview.delegate = self
		tableview.dataSource = self
		// Setup RefreshControl
		self.addChildViewController(self.tableViewController)
		self.tableViewController.tableView = self.tableview
		self.tableViewController.refreshControl = self.refreshControl
		updateRefreshControl()
		// Setup Admob
		adView.adSize = kGADAdSizeSmartBannerPortrait
		adView.adUnitID = "ca-app-pub-9355707484240783/4024228355"
		adView.rootViewController = self
		adView.delegate = self
		let request = GADRequest()
		request.testDevices = ["9a231882e8eb1d8e2aa640a79a41bb2b"];
		adView.loadRequest(request)
		
		// Load the subjects
		if let student = Student.MR_findFirstByAttribute("name", withValue: NSUserDefaults.standardUserDefaults().stringForKey("selectedStudent")!) {
			self.student = student
			loadStudent()
		}
        
        popUpViewButton.addTarget(self, action: #selector(loadStudent), forControlEvents: .TouchUpInside)
        popUpViewButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit

	}

	func logout() {
		User.MR_deleteAllMatchingPredicate(NSPredicate(value: true))
		NSManagedObjectContext.MR_defaultContext().MR_saveToPersistentStoreAndWait()

		NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "selectedStudent")
		self.tabBarController!.navigationController!.popToRootViewControllerAnimated(false)
		NSNotificationCenter.defaultCenter().postNotificationName("tabBarDismissed", object: nil)
	}

	func adViewDidReceiveAd(bannerView: GADBannerView!) {
		UIView.animateWithDuration(0.5, animations: {
			self.tableViewBottomConstraint.constant = 50
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
			self.tableview.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
		}
	}

	func studentChanged(completionHandler: () -> Void) {
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
		// Get the first name and set it as the title. We do this here so that the name will update when the student changes in the settings
		self.navigationItem.title = student.name!.componentsSeparatedByString(" ")[0] + "'s Grades"
		startLoading()
		if let service = UpdateService(studentID: student.objectID) {
			service.updateStudentInformation({ successful, error in
                dispatch_async(dispatch_get_main_queue(), {
                    if (successful) {
                        NSManagedObjectContext.MR_defaultContext().refreshObject(self.student, mergeChanges: false)
                        self.tableview.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
                        self.updateRefreshControl()
                        self.stopLoading()
                        let notificationSettings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
                        UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
                        NSNotificationCenter.defaultCenter().postNotificationName("doneReloading", object: nil)
					
                    } else {
                        self.stopLoading()
                        if error! == noGradesError {
                            self.showPopUpView(.noGrades)
                        } else {
                            self.showPopUpView(.noInternet)
                        }
                    }
                })
			})
		}
	}

	func pullToRefresh() {
		if let service = UpdateService(studentID: student.objectID) {
			service.updateStudentInformation({ successful, error in
				if (successful) {
					dispatch_async(dispatch_get_main_queue(), {
						// Refresh the ui's student object
						NSManagedObjectContext.MR_defaultContext().refreshObject(self.student, mergeChanges: false)
						self.tableview.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
						self.refreshControl.endRefreshing()
						self.updateRefreshControl()
					})
				} else {
					dispatch_async(dispatch_get_main_queue(), {
						self.refreshControl.endRefreshing()
                        self.stopLoading()
                        if error! == noGradesError {
                            self.showPopUpView(.noGrades)
                        } else {
                            self.showPopUpView(.noInternet)
                        }
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
		badges.removeAll()

		// Remove invalid subjects
		for subject in subjects! {
			var mps = subject.markingPeriods!.allObjects as! [MarkingPeriod]
			mps = mps.filter { !$0.empty!.boolValue } // filter marking periods with no assignments

			if mps.count == 0 { // Don't show subject if all the marking periods are empty
				subjects!.removeObject(subject)
				continue
			}

			mps.sortInPlace { Int($0.number!) > Int($1.number!) } // sort marking periods by descending number
            
            /*
             
            let recentMP = mps[0]
			let percentgradeString = recentMP.percentGrade!.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "1234567890.").invertedSet).joinWithSeparator("")

			if (percentgradeString == "") { // Don't show subject if the most recent marking period with assignments has zero percent grade or strange grading
				subjects!.removeObject(subject)
			} 
             */
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

		// Set which subjects have badges
		let updatedSubjects = subjects!.filter({ (s: Subject) in
			if let markingPeriods = s.markingPeriods?.allObjects as? [MarkingPeriod] {
				var allAssignments: [Assignment] = []
				for mp in markingPeriods {
					if let assignments = mp.assignments?.allObjects as? [Assignment] {
						allAssignments.appendContentsOf(assignments)
					}
				}
				return !allAssignments.filter({ return $0.newUpdate.boolValue }).isEmpty
			}

			return false
		})

		for subject in updatedSubjects {
			badges[subjects!.indexOf(subject)!] = .Updated
		}

		return subjects!.count
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

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

			if let badge = badges[indexPath.row] {
				switch badge {
				case .Updated:
					cell.badge.image = UIImage(named: "Recently Updated")!
				default:
					cell.badge.hidden = true
				}
			} else {
				cell.badge.hidden = true
			}

			return cell

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
		formatter.dateFormat = "h:mm a"
		let title = "Updated at \(formatter.stringFromDate(NSDate()))"
		let attributedTitle = NSAttributedString(string: title, attributes: [NSForegroundColorAttributeName: UIColor.lightGrayColor()])
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
		showPopUpView(.loading)
	}

	func stopLoading() {
		activityIndicator.stopAnimating()
		hidePopUpView()
	}
    
    func showPopUpView(type: PopUpViewType) {
        
        tableview.userInteractionEnabled=false
        switch type {
        case .loading:
            popUpViewButton.hidden = true
            popUpViewText.hidden = true
            break
        case .noInternet:
            popUpViewButton.hidden = false
            popUpViewText.hidden = false
            popUpViewButton.adjustsImageWhenHighlighted = true
            popUpViewButton.setImage(UIImage(named: "Internet Icon"), forState: .Normal)
            popUpViewText.text = "We could not connect to the internet. Tap to retry."
            break
        case .noGrades:
            popUpViewButton.hidden = false
            popUpViewText.hidden = false
            popUpViewButton.adjustsImageWhenHighlighted = true
            popUpViewButton.setImage(UIImage(named: "Triangle Logo"), forState: .Normal)
            popUpViewText.text = "No courses were found in Sapphire. Tap to retry."
            break
        }
        
        popUpView.hidden = false
        UIView.animateWithDuration(0.3, animations: {
            self.popUpView.alpha = 1
        })
    }
    
    func hidePopUpView() {
        tableview.userInteractionEnabled = true
        UIView.animateWithDuration(0.3, animations: {
            self.popUpView.alpha = 0
        })
        popUpView.hidden = true
        popUpViewButton.hidden = true
        popUpViewText.hidden = true
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
