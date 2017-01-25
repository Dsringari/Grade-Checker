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
    case numerical
}



class GradesVC: UIViewController, UITableViewDelegate, UITableViewDataSource, GADBannerViewDelegate, LockDelegate, NSFetchedResultsControllerDelegate {
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

	// Create an instance of a UITableViewController. This will host the tableView in order to solve uirefreshcontrol bugs
	fileprivate let tableViewController = UITableViewController()
	@IBOutlet var tableView: UITableView!

	var student: Student!
    var selectedSubject: Subject!
	var badges: [Int: Badge] = [:]
	let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
	lazy var refreshControl: UIRefreshControl = {
		let refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
		refreshControl.tintColor = UIColor.lightGray
		return refreshControl
	}()
    
    var fetchedResultsController: NSFetchedResultsController<Subject>!
    
    var sortMethod: Sorting {
        let sortingNumber = UserDefaults.standard.integer(forKey: "sortMethod")
        if let sort = Sorting(rawValue: sortingNumber) {
            return sort
        } else {
            UserDefaults.standard.set(Sorting.recent.rawValue, forKey: "sortMethod")
            return .recent
        }
    }
    
	override func viewDidLoad() {
		super.viewDidLoad()

		// Setup Tableview
		tableView.delegate = self
		tableView.dataSource = self
		// Setup RefreshControl
		addChildViewController(tableViewController)
		tableViewController.tableView = tableView
		tableViewController.refreshControl = refreshControl
		updateRefreshControl()
        
        setupAdmob()
		
        hidePopUpView()
        
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
    
    override func viewDidAppear(_ animated: Bool) {
        updateFetchResultsController()
        tableView.reloadData()
    }
    
    func loadStudent() {
        let selectedStudentName = UserDefaults.standard.string(forKey: "selectedStudent")!
        guard let student = Student.mr_findFirst(with: NSPredicate(format: "name == %@", argumentArray: [selectedStudentName])) else {
            print("Failed to find student.")
            return
        }
        self.student = student
		// Get the first name and set it as the title. We do this here so that the name will update when the student changes in the settings
		self.navigationItem.title = student.name!.components(separatedBy: " ")[0] + "'s Grades"
        
        fetchedResultsController = createFetchResultsController()
        do {
            try self.fetchedResultsController.performFetch()
            self.tableView.reloadData()
        } catch(let error) {
            print(error)
        }
        
		startLoading()
		if let service = UpdateService(studentID: student.objectID) {
			service.updateStudentInformation({ successful, error in
                DispatchQueue.main.async(execute: {
                    if (successful) {
                        self.hidePopUpView()
                        self.updateRefreshControl()
                        self.stopLoading()
                        self.tutorial()
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
                        self.hidePopUpView()
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
    
    func createFetchResultsController() -> NSFetchedResultsController<Subject> {
        let fetchRequest = NSFetchRequest<Subject>(entityName: "Subject")
        
        fetchRequest.sortDescriptors = sortDescriptors()
        
        fetchRequest.predicate = NSPredicate(format: "ANY markingPeriods.empty == false AND student == %@", argumentArray: [student])
        let frc = NSFetchedResultsController<Subject>(fetchRequest: fetchRequest, managedObjectContext: NSManagedObjectContext.mr_default(), sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        return frc
    }
    
    func sortDescriptors() -> [NSSortDescriptor] {
        let nameSort = NSSortDescriptor(key: "name", ascending: true)
        switch sortMethod {
        case .recent:
            let recentSort = NSSortDescriptor(key: "lastUpdated", ascending: false)
            return [recentSort, nameSort]
        case .alphabetical:
            return [nameSort]
        case .numerical:
            let gradeSort = NSSortDescriptor(key: "mostRecentGrade", ascending: false, selector: #selector(NSString.localizedStandardCompare(_:)))
            return [gradeSort, nameSort]
        }
    }
    
    func updateFetchResultsController() {
        fetchedResultsController.fetchRequest.sortDescriptors = sortDescriptors()
        do {
            try fetchedResultsController.performFetch()
            self.tableView.reloadData()
        } catch (let error) {
            print(error)
        }
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
            tableView.setContentOffset(CGPoint(x: 0, y: tableView.contentOffset.y - refreshControl.frame.size.height), animated: true)
        }
    }
    
    func stopLoading() {
        refreshControl.endRefreshing()
        hidePopUpView()
        activityIndicator.stopAnimating()
    }
    
    func showPopUpView(_ type: PopUpViewType) {
        
        tableView.isUserInteractionEnabled=false
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
        tableView.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.3, animations: {
            self.popUpView.alpha = 0
        })
        popUpView.isHidden = true
        popUpViewButton.isHidden = true
        popUpViewText.isHidden = true
    }
    
    func logout() {
        User.mr_deleteAll(matching: NSPredicate(value: true))
        NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait()
        UserDefaults.standard.set(nil, forKey: "selectedStudent")
        _ = navigationController?.tabBarController?.navigationController?.popToRootViewController(animated: false)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "tabBarDismissed"), object: nil)
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "subjectView") {
            let sV = segue.destination as! DetailVC
            sV.subject = selectedSubject
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        } else if segue.identifier == "lock" {
            let lockVC = segue.destination as! LockVC
            lockVC.lockDelegate = self
        }
    }
    
    func tutorial() {
        let alert = UIAlertController(title: "New Features in 1.2  🎉", message: "We added real-time GPA calculation to your profile! Be sure to update the weight and credits for each subject under course averages.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        if let storedVersion = UserDefaults.standard.string(forKey: "currVersion") {
            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
            if storedVersion != version {
                present(alert, animated: true, completion: nil)
                UserDefaults.standard.set(version, forKey: "currVersion")
            }
        } else {
            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
            UserDefaults.standard.set(version, forKey: "currVersion")
            present(alert, animated: true, completion: nil)
        }
    }

    
    // MARK: - Table view data source


	func numberOfSections(in tableView: UITableView) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections.count
        }
        return 0
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
		badges.removeAll()
        if let subjects = fetchedResultsController.fetchedObjects {
            let subjects = subjects as NSArray
            for (index,subject) in subjects.enumerated() {
                let predicate = NSPredicate(format: "SUBQUERY(markingPeriods, $m, ANY $m.assignments.newUpdate == %@).@count != 0", argumentArray: [true])
                if predicate.evaluate(with: subject) {
                    badges[index] = .updated
                }
            }
            return subjects.count
        }
        
        return 0
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		let cell = tableView.dequeueReusableCell(withIdentifier: "subjectCell", for: indexPath)
        configureCell(cell, indexPath: indexPath)
		return cell
	}
    
    func configureCell(_ cell: UITableViewCell, indexPath: IndexPath) {
        let cell = cell as! SubjectTableViewCell
        let subject = fetchedResultsController.object(at: indexPath)
        cell.subjectNameLabel.text = subject.name
        
        // Round the percent to the nearest whole number
        if let grade = subject.mostRecentGrade {
            let numberFormatter = NumberFormatter()
            let percentGradeDouble = numberFormatter.number(from: grade)!.doubleValue
            let roundedPercentGrade: Int = Int(round(percentGradeDouble))
            cell.percentGradeLabel.text = String(roundedPercentGrade) + "%"
        } else {
            cell.percentGradeLabel.text = "N/A"
        }
        
        let dateString: String
        if let date = subject.lastUpdated {
            dateString = relativeDateStringForDate(date)
        } else {
            dateString = "N/A"
        }
        
        cell.lastUpdatedLabel.text = "Last Updated: " + dateString
        
        if let badge = badges[indexPath.row] {
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
    }

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		selectedSubject = fetchedResultsController.object(at: indexPath)
		performSegue(withIdentifier: "subjectView", sender: nil)
		tableView.deselectRow(at: indexPath, animated: true)
	}
    
    // MARK: - Fetched Results Controller Delegate
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch(type) {
        case .insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with:UITableViewRowAnimation.fade)
            }
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
            }
        case .update:
            if let indexPath = indexPath {
                if let cell = tableView.cellForRow(at: indexPath) {
                    configureCell(cell, indexPath: indexPath)
                }
            }
        case .move:
            if let indexPath = indexPath {
                if let newIndexPath = newIndexPath {
                    tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
                    tableView.insertRows(at: [newIndexPath], with: UITableViewRowAnimation.fade)
                }
            }
        }
        
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch(type) {
        case .insert:
            tableView.insertSections(NSIndexSet(index: sectionIndex) as IndexSet, with: UITableViewRowAnimation.fade)
        case .delete:
            tableView.deleteSections(NSIndexSet(index: sectionIndex) as IndexSet, with: UITableViewRowAnimation.fade)
        default:
            break
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    // MARK: - Adview delegate
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
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
    
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        print(error)
    }



}
