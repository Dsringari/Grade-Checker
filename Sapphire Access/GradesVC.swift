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
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}



enum Sorting: Int {
    case recent
    case alphabetical
    case numericalGrade
}



class GradesVC: UIViewController, UITableViewDelegate, UITableViewDataSource, GADBannerViewDelegate {
	@IBOutlet var activityIndicator: UIActivityIndicatorView!
	@IBOutlet var popUpView: UIView!
    @IBOutlet var popUpViewText: UILabel!
    @IBOutlet var popUpViewButton: UIButton!
	@IBOutlet var adView: GADBannerView!
	@IBOutlet var tableViewBottomConstraint: NSLayoutConstraint!
    
    enum Badge {
        case updated
        case mock
        case both
    }
    
    enum PopUpViewType {
        case loading
        case noInternet
        case noGrades
    }
   
    
	var settingsCompletionHandler: (() -> Void)!

	// Create an instance of a UITableViewController. This will host the tableview in order to solve uirefreshcontrol bugs
	fileprivate let tableViewController = UITableViewController()
	@IBOutlet var tableview: UITableView!

	var student: Student!
	var subjects: [Subject]?
	var badges: [Int: Badge] = [:]
	let appDelegate = UIApplication.shared.delegate as! AppDelegate
	lazy var refreshControl: UIRefreshControl = {
		let refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
		refreshControl.tintColor = UIColor.lightGray
		return refreshControl
	}()
    
    var sortMethod: Sorting = .recent

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
        
        setupAdmob()
		
        hidePopUpView()
        
        checkSortingMethod()
        
        loadStudent()
		
        popUpViewButton.addTarget(self, action: #selector(loadStudent), for: .touchUpInside)
        popUpViewButton.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadStudent), name: NSNotification.Name(rawValue: "loadStudent"), object: nil)
	}
    
    func setupAdmob() {
        // Setup Admob
        adView.adSize = kGADAdSizeSmartBannerPortrait
        adView.adUnitID = "ca-app-pub-9355707484240783/4024228355"
        adView.rootViewController = self
        adView.delegate = self
        let request = GADRequest()
        request.testDevices = ["f0b003932cbcc49284626d4b1cd3a5f5"];
        adView.load(request)
    }
    
    override func viewWillDisappear(_ animated: Bool){
        super.viewDidAppear(animated)
        
        if self.navigationController!.viewControllers.contains(self) == false  //any other hierarchy compare if it contains self or not
        {
            // the view has been removed from the navigation stack or hierarchy, back is probably the cause
            // this will be slow with a large stack however.
            
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    func checkSortingMethod() {
        let sortingNumber = UserDefaults.standard.integer(forKey: "sortMethod")
        sortMethod = Sorting(rawValue: sortingNumber)!
    }
    
    override func viewDidAppear(_ animated: Bool) {
        checkSortingMethod()
        subjects = student.subjects?.allObjects as? [Subject]
        tableview.reloadData()
    }

	func adViewDidReceiveAd(_ bannerView: GADBannerView!) {
        self.tableViewBottomConstraint.constant = 50
        self.view.addSubview(self.adView)
        
        if #available(iOS 9.0, *) {
            self.adView.bottomAnchor.constraint(equalTo: self.bottomLayoutGuide.topAnchor)
        } else {
            // Fallback on earlier versions
            NSLayoutConstraint.constraints(withVisualFormat: "V:|[adView]|", options: [], metrics: nil, views: ["adView": self.adView])
        }
        
        NSLayoutConstraint.constraints(withVisualFormat: "|-0-[adView]-0-|", options: [], metrics: nil, views: ["adView": self.adView])
        
		UIView.animate(withDuration: 0.5, animations: {
			self.view.layoutIfNeeded()
		})
	}

	func adView(_ bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
		print(error)
	}

    func loadStudent() {
        let selectedStudentName = UserDefaults.standard.string(forKey: "selectedStudent")!
        guard let student = Student.mr_findFirst(with: NSPredicate(format: "name == %@", argumentArray: [selectedStudentName])) else {
            return
        }
        self.student = student
		subjects = nil
		// Get the first name and set it as the title. We do this here so that the name will update when the student changes in the settings
		self.navigationItem.title = student.name!.components(separatedBy: " ")[0] + "'s Grades"
		startLoading()
		if let service = UpdateService(studentID: student.objectID) {
			service.updateStudentInformation({ successful, error in
                DispatchQueue.main.async(execute: {
                    if (successful) {
                        NSManagedObjectContext.mr_default().refresh(self.student, mergeChanges: false)
                        self.hidePopUpView()
                        self.tableview.reloadData()
                        self.updateRefreshControl()
                        self.stopLoading()
                        let notificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
                        UIApplication.shared.registerUserNotificationSettings(notificationSettings)
                        UIApplication.shared.registerForRemoteNotifications()
					
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
					DispatchQueue.main.async(execute: {
						// Refresh the ui's student object
                        self.hidePopUpView()
						NSManagedObjectContext.mr_default().refresh(self.student, mergeChanges: false)
						self.tableview.reloadData()
						self.refreshControl.endRefreshing()
						self.updateRefreshControl()
					})
				} else {
					DispatchQueue.main.async(execute: {
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

	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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

			mps.sort { Int($0.number!) > Int($1.number!) } // sort marking periods by descending number
            
            /*
             
            let recentMP = mps[0]
			let percentgradeString = recentMP.percentGrade!.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "1234567890.").invertedSet).joinWithSeparator("")

			if (percentgradeString == "") { // Don't show subject if the most recent marking period with assignments has zero percent grade or strange grading
				subjects!.removeObject(subject)
			} 
             */
		}
        
        switch sortMethod {
        case .recent:
            subjects!.sort(by: { (s1: Subject, s2: Subject) -> Bool in
                
                guard s1.mostRecentDate != nil || s2.mostRecentDate != nil else {
                    if s1.mostRecentDate == nil && s2.mostRecentDate == nil {
                        return s1.name < s2.name
                    }
                    
                    if s1.mostRecentDate == nil {
                        return true
                    }
                    
                    return false
                }
                
                if (s1.mostRecentDate!.compare(s2.mostRecentDate! as Date) == ComparisonResult.orderedSame) {
                    return s1.name < s2.name
                }
                
                return s1.mostRecentDate!.compare(s2.mostRecentDate! as Date) == ComparisonResult.orderedDescending
            })
        case .alphabetical:
            subjects!.sort{$0.name < $1.name}
        case .numericalGrade:
            subjects!.sort{ (s1: Subject, s2: Subject) -> Bool in
                
                var mps1 = s1.markingPeriods?.allObjects as! [MarkingPeriod]
                mps1 = mps1.filter{!$0.empty!.boolValue}
                mps1.sort{$0.number > $1.number}
                var mps2 = s2.markingPeriods?.allObjects as! [MarkingPeriod]
                mps2 = mps2.filter{!$0.empty!.boolValue}
                mps2.sort{$0.number > $1.number}
                
                let mostRecentGrade1 = NSDecimalNumber(string: mps1[0].percentGrade)
                let mostRecentGrade2 = NSDecimalNumber(string: mps2[0].percentGrade)
                return mostRecentGrade1.compare(mostRecentGrade2) == .orderedDescending
            }
        }
        
        // Set which subjects have badges
        let updatedSubjects = Subject.mr_findAll(with: NSPredicate(format: "SUBQUERY(markingPeriods, $m, ANY $m.assignments.newUpdate == %@).@count != 0", argumentArray: [true])) as! [Subject]
        for subject in updatedSubjects {
            if let index = subjects?.index(of: subject) {
                badges[index] = .updated
            }
        }
		return subjects!.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		let cell = tableView.dequeueReusableCell(withIdentifier: "subjectCell", for: indexPath) as! SubjectTableViewCell

		if let subject = subjects?[(indexPath as NSIndexPath).row] {
			cell.subjectNameLabel.text = subject.name

			var markingPeriods: [MarkingPeriod] = subjects![(indexPath as NSIndexPath).row].markingPeriods!.allObjects as! [MarkingPeriod]

			// sort marking periods by descending number and ignore empty marking periods
			markingPeriods = markingPeriods.filter { !$0.empty!.boolValue }.sorted { Int($0.number!) > Int($1.number!) }
            
			let recentMP = markingPeriods[0]

			// Remove %
			let percentgradeString = recentMP.percentGrade!.components(separatedBy: CharacterSet(charactersIn: "1234567890.").inverted).joined(separator: "")

			// Round the percent to the nearest whole number
			let numberFormatter = NumberFormatter()
			let percentGradeDouble = numberFormatter.number(from: percentgradeString)!.doubleValue
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
            
            if let badge = badges[(indexPath as NSIndexPath).row] {
                switch badge {
                case .updated:
                    cell.badge.isHidden = false
                    cell.badge.image = UIImage(named: "Recently Updated")!
                default:
                    cell.badge.isHidden = true
                }
            } else {
                cell.badge.isHidden = true
            }


			return cell

		}

		return UITableViewCell()
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		selectedSubject = subjects![(indexPath as NSIndexPath).row]
		performSegue(withIdentifier: "subjectView", sender: nil)
		tableView.deselectRow(at: indexPath, animated: true)
	}

	func updateRefreshControl() {
		// set the refresh control's title
		let formatter: DateFormatter = DateFormatter()
		formatter.dateFormat = "h:mm a"
		let title = "Updated at \(formatter.string(from: Date()))"
		let attributedTitle = NSAttributedString(string: title, attributes: [NSForegroundColorAttributeName: UIColor.lightGray])
		self.refreshControl.attributedTitle = attributedTitle
	}

	func percentToLetterGrade(_ percentGrade: Int) -> String {
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
        if !popUpView.isHidden {
            hidePopUpView()
            showPopUpView(.loading)
            activityIndicator.startAnimating()
        } else {
            refreshControl.beginRefreshing()
            self.tableview.setContentOffset(CGPoint(x: 0, y: tableview.contentOffset.y - refreshControl.frame.size.height), animated: true)
        }
	}

	func stopLoading() {
		refreshControl.endRefreshing()
        hidePopUpView()
        activityIndicator.stopAnimating()
	}
    
    func showPopUpView(_ type: PopUpViewType) {
        
        tableview.isUserInteractionEnabled=false
        switch type {
        case .loading:
            popUpViewButton.isHidden = true
            popUpViewText.isHidden = true
            break
        case .noInternet:
            popUpViewButton.isHidden = false
            popUpViewText.isHidden = false
            popUpViewButton.adjustsImageWhenHighlighted = true
            popUpViewButton.setImage(UIImage(named: "Internet Icon"), for: UIControlState())
            popUpViewText.text = "We could not connect to the internet. Tap to retry."
            break
        case .noGrades:
            popUpViewButton.isHidden = false
            popUpViewText.isHidden = false
            popUpViewButton.adjustsImageWhenHighlighted = true
            popUpViewButton.setImage(UIImage(named: "Triangle Logo"), for: UIControlState())
            popUpViewText.text = "No courses were found in Sapphire. Tap to retry."
            break
        }
        
        popUpView.isHidden = false
        UIView.animate(withDuration: 0.3, animations: {
            self.popUpView.alpha = 1
        })
    }
    
    func hidePopUpView() {
        tableview.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.3, animations: {
            self.popUpView.alpha = 0
        })
        popUpView.isHidden = true
        popUpViewButton.isHidden = true
        popUpViewText.isHidden = true
    }
    
    

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if (segue.identifier == "subjectView") {
			let sV = segue.destination as! DetailVC
			sV.subject = selectedSubject
			self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
		}
	}
}
