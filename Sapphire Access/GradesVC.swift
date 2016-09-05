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


enum Sorting: Int {
    case Recent
    case Alphabetical
    case NumericalGrade
}



class GradesVC: UIViewController, UITableViewDelegate, UITableViewDataSource, GADBannerViewDelegate {
	@IBOutlet var activityIndicator: UIActivityIndicatorView!
	@IBOutlet var popUpView: UIView!
    @IBOutlet var popUpViewText: UILabel!
    @IBOutlet var popUpViewButton: UIButton!
	@IBOutlet var tableViewBottomConstraint: NSLayoutConstraint!
    
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
   
    
	var settingsCompletionHandler: (() -> Void)!

	// Create an instance of a UITableViewController. This will host the tableview in order to solve uirefreshcontrol bugs
	private let tableViewController = UITableViewController()
	@IBOutlet var tableview: UITableView!

	var student: Student!
	var badges: [Int: Badge] = [:]
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var subjectNames: [String] = []
    var subjectDates: [String] = []
    var subjectPercentages: [String] = []
    
    var sortMethod: Sorting = .Recent

	override func viewDidLoad() {
		super.viewDidLoad()

		// Setup Tableview
		tableview.delegate = self
		tableview.dataSource = self
		// Setup RefreshControl
		self.addChildViewController(self.tableViewController)
		self.tableViewController.tableView = self.tableview
		
        hidePopUpView()
        self.tabBarController?.tabBar.items![1].badgeValue = "A"
        
        getStuff()

		
        popUpViewButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        
	}
    
    func getStuff() {
        subjectNames = ["Algebra 2/Trig", "Honors English 9", "Chemistry 3", "World Literature Basics", "SPANISH 4 HON", "Legendary Tropics of Java"]
        subjectDates = ["9:56 AM", "Yesterday", "5 days ago", "24 days ago", "1 month ago", "4 months ago"]
        subjectPercentages = ["97%", "88%", "76%", "92%", "100%", "83%"]
    }
    
    

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return subjectNames.count
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

		let cell = tableView.dequeueReusableCellWithIdentifier("subjectCell", forIndexPath: indexPath) as! SubjectTableViewCell
        
        cell.subjectNameLabel.text = subjectNames[indexPath.row]
        cell.percentGradeLabel.text = subjectPercentages[indexPath.row]
        cell.lastUpdatedLabel.text = "Last Updated: \(subjectDates[indexPath.row])"
        
        if indexPath.row == 0 {
            cell.badge.image = UIImage(named: "Recently Updated")
            cell.badge.hidden = false
        } else {
            cell.badge.hidden = true
        }

		return UITableViewCell()
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
        if !popUpView.hidden {
            hidePopUpView()
            showPopUpView(.loading)
            activityIndicator.startAnimating()
        } else {
        }
	}

	func stopLoading() {
        hidePopUpView()
        activityIndicator.stopAnimating()
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
    
}
