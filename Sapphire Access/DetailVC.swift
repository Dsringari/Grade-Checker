//
//  DetailVC.swift
//  Grade Checker
//
//  Created by Dhruv Sringari on 4/24/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit
import MagicalRecord
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


class DetailVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var sortingSegmentedControl: UISegmentedControl!
    @IBOutlet var percentageButton: UIButton!
    @IBOutlet var pointsButton: UIButton!
    @IBOutlet var toolbarHeight: NSLayoutConstraint!
    @IBOutlet var toolbar: UIView!
    @IBOutlet var sortingSegmentTop: NSLayoutConstraint!
    @IBOutlet var filterButton: UIBarButtonItem!
    
    var navHairLine: UIImageView!
    var subject: Subject!
    var markingPeriods: [MarkingPeriod]!
    var categories: [String] = []
    var selectedMPIndex: Int = 0
    var gradeViewType: GradeViewType = .point
    var sortMethod: Sorting = .recent
    var assignmentsToSetOld: [Assignment] = []
    var viewType: ViewType = .allMarkingPeriods
    
    
    enum ViewType {
        case allMarkingPeriods
        case oneMarkingPeriod(markingPeriodNumber: String)
    }
    
    enum GradeViewType {
        case point
        case percentage
    }
    
    enum Sorting {
        case recent
        case category
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 44
       
        
        // Find the hairline so we can hide it
        for view in self.navigationController!.navigationBar.subviews {
            for aView in view.subviews {
                if (aView.isKind(of: UIImageView.self) &&  aView.bounds.size.width == self.navigationController!.navigationBar.frame.size.width && aView.bounds.size.height < 2) {
                    aView.removeFromSuperview()
                }
            }
        }
        // Remove toolbar's border
        self.navigationController!.toolbar.clipsToBounds = true
        
        let mps = subject.markingPeriods!.allObjects as! [MarkingPeriod]
        markingPeriods = mps.filter{!$0.empty!.boolValue}.sorted{Int($0.number!) < Int($1.number!)} // Only want non empty marking periods
        
        if case let ViewType.oneMarkingPeriod(number) = viewType {
            self.title = "Marking Period \(number)"
            
            if let mp = markingPeriods.filter({$0.number == number}).first {
                let index = markingPeriods.index(of: mp)!
                selectedMPIndex = index
            }
            sortingSegmentTop.constant = 8
            segmentedControl.isHidden = true
            navigationItem.rightBarButtonItems?.removeObject(filterButton)
            
            self.view.layoutIfNeeded()
        } else {
            self.title = subject.name
            selectedMPIndex = markingPeriods.count - 1
            segmentedControl.removeAllSegments()
            for index in 0..<markingPeriods.count {
                segmentedControl.insertSegment(withTitle: "MP " + markingPeriods[index].number!, at: index, animated: false)
            }
            segmentedControl.selectedSegmentIndex = selectedMPIndex
            
            segmentedControl.sizeToFit()
        }
        
        calculateCategories(markingPeriodIndex: selectedMPIndex)
        percentageButton.setTitle(markingPeriods[selectedMPIndex].percentGrade, for: UIControlState())
        pointsButton.setTitle(markingPeriods[selectedMPIndex].totalPoints! + "/" + markingPeriods[selectedMPIndex].possiblePoints!, for: UIControlState())
        
        NotificationCenter.default.addObserver(self, selector: #selector(dismissSelf), name: NSNotification.Name(rawValue: "loadStudent"), object: nil)
        
    }
    
    func dismissSelf() {
        navigationController?.popViewController(animated: false)
    }
    
    func setShownUpdatesOld() {
        for a in assignmentsToSetOld {
            a.newUpdate = NSNumber(value: false as Bool)
        }
        NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait()

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        setShownUpdatesOld()
    }
    
    @IBAction func showPoints() {
        gradeViewType = .point
        pointsButton.setBackgroundImage(UIImage(named: "SelectedViewTypeBackground"), for: UIControlState())
        percentageButton.setBackgroundImage(nil, for: UIControlState())
        tableView.reloadData()
    }
    
    @IBAction func showPercentage() {
        gradeViewType = .percentage
        percentageButton.setBackgroundImage(UIImage(named: "SelectedViewTypeBackground"), for: UIControlState())
        pointsButton.setBackgroundImage(nil, for: UIControlState())
        tableView.reloadData()
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func segmentedControlChanged(_ sender: AnyObject) {
        selectedMPIndex = segmentedControl.selectedSegmentIndex
        calculateCategories(markingPeriodIndex: selectedMPIndex)
        percentageButton.setTitle(markingPeriods[selectedMPIndex].percentGrade, for: UIControlState())
        pointsButton.setTitle(markingPeriods[selectedMPIndex].totalPoints! + "/" + markingPeriods[selectedMPIndex].possiblePoints!, for: UIControlState())
        setShownUpdatesOld()
        self.tableView.reloadData()
    }
    
    
    @IBAction func showHideFilterOptions(_ sender: AnyObject) {
        showOrHideOptions()
    }
    
    func showOrHideOptions(_ delay: Double = 0) {
        if toolbarHeight.constant == 44 {
            self.toolbarHeight.constant = 80
        } else {
            self.toolbarHeight.constant = 44
        }
        
        UIView.animate(withDuration: 0.5, delay: delay, usingSpringWithDamping: 0.66, initialSpringVelocity: 1, options: [], animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    @IBAction func sortingMethodChanged(_ sender: AnyObject) {
        if sortingSegmentedControl.selectedSegmentIndex == 0 {
            sortMethod = .recent
        } else {
            sortMethod = .category
        }
        
        if case ViewType.allMarkingPeriods = viewType {
            showOrHideOptions(0.33)
        }
        self.tableView.reloadData()
    }
    
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sortMethod == .recent ? 1 : categories.count
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.contentView.backgroundColor = UIColor.groupTableViewBackground
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if sortMethod == .category {
            let header = UITableViewHeaderFooterView(frame: CGRect(x: 0,y: 0,width: tableView.frame.size.width,height: 10))
        
            let totalLabel: UILabel = UILabel()
            let totals = totalScore(categories[section])
        
            if (gradeViewType == .point) {
                totalLabel.text = totals.totalPoints + "/" + totals.possiblePoints
            } else {
                totalLabel.text = percentage(totals.totalPoints, possiblePoints: totals.possiblePoints)
            }
            
            totalLabel.textColor = UIColor.lightGray

        
            totalLabel.translatesAutoresizingMaskIntoConstraints = false
            header.addSubview(totalLabel)
        
            NSLayoutConstraint(item: totalLabel, attribute: .trailing, relatedBy: .equal, toItem: header, attribute: .trailingMargin, multiplier: 1, constant: 8).isActive = true
            NSLayoutConstraint(item: totalLabel, attribute: .centerY, relatedBy: .equal, toItem: header, attribute: .centerY, multiplier: 1, constant: 0).isActive = true
            return header
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sortMethod == .recent ? "Assignments" : categories[section].capitalized
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if sortMethod == .recent {
            let assignments: [Assignment] = markingPeriods[selectedMPIndex].assignments!.allObjects as! [Assignment]
            return assignments.count
        } else {
            let category = categories[section]
            var assignments = markingPeriods[selectedMPIndex].assignments!.allObjects as! [Assignment]
            assignments = assignments.filter{return $0.category == category}
            return assignments.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "assignmentCell", for: indexPath) as! AssignmentTableViewCell
        let mp = markingPeriods[selectedMPIndex]
        
        var assignments: [Assignment]
        if sortMethod == .recent {
            assignments = mp.assignments!.allObjects as! [Assignment]
        } else {
            let category = categories[(indexPath as NSIndexPath).section]
            assignments = mp.assignments!.allObjects as! [Assignment]
            assignments = assignments.filter{return $0.category == category}
        }
        
        // sort by date
        assignments.sort{ $0.dateCreated!.compare($1.dateCreated! as Date) == ComparisonResult.orderedDescending }
        cell.assignmentNameLabel.text = assignments[(indexPath as NSIndexPath).row].name
        
        if (gradeViewType == .point) {
            cell.pointsGradeLabel.text = assignments[(indexPath as NSIndexPath).row].totalPoints! + "/" + assignments[(indexPath as NSIndexPath).row].possiblePoints!
        } else {
            cell.pointsGradeLabel.text = percentage(assignments[(indexPath as NSIndexPath).row].totalPoints!, possiblePoints: assignments[(indexPath as NSIndexPath).row].possiblePoints!)
        }
        
        if assignments[(indexPath as NSIndexPath).row].newUpdate.boolValue {
            cell.badge.image = UIImage(named: "Recently Updated")!
            if assignmentsToSetOld.index(of: assignments[(indexPath as NSIndexPath).row]) == nil {
                assignmentsToSetOld.append(assignments[(indexPath as NSIndexPath).row])
            }
        } else {
            cell.badge.image = nil
        }

        
        return cell
    }
    
    func percentage(_ totalPoints: String, possiblePoints: String) -> String {
        let totalPointsNumber = NSDecimalNumber(string: totalPoints)
        let possiblePointsNumber = NSDecimalNumber(string: possiblePoints)
        
        let numberFormatter = NumberFormatter()
        numberFormatter.minimumFractionDigits = 1
        numberFormatter.maximumFractionDigits = 1
        numberFormatter.minimumIntegerDigits = 1
        numberFormatter.roundingMode = .halfUp
        numberFormatter.numberStyle = .decimal
        
        guard !totalPointsNumber.doubleValue.isNaN else {
            return "0.0%"
        }
        
        guard possiblePointsNumber.compare(0) != .orderedSame && !possiblePointsNumber.doubleValue.isNaN && !totalPointsNumber.doubleValue.isNaN else {
            return "N/A"
        }
        
        let percentage = totalPointsNumber.dividing(by: possiblePointsNumber).multiplying(by: 100)
        return numberFormatter.string(from: percentage)! + "%"
        
    }
    
    
    func calculateCategories(markingPeriodIndex num: Int) {
        let mp = markingPeriods[num]
        
        let assignments = mp.assignments!.allObjects as! [Assignment]
        
        var categories: [String] = []
        for a in assignments {
            if let category = a.category , categories.index(of: category) == nil {
                categories.append(category)
            }
        }
        
        categories.sort{$0 > $1}
        self.categories = categories
    }
    
    func totalScore(_ category: String) -> (totalPoints: String, possiblePoints: String) {
        var assignments = markingPeriods[selectedMPIndex].assignments!.allObjects as! [Assignment]
        assignments = assignments.filter{$0.category == category}
        
        var total: NSDecimalNumber = 0
        var possible: NSDecimalNumber = 0
        for a in assignments {
            
            let totalPoints = NSDecimalNumber(string: a.totalPoints)
            guard totalPoints.doubleValue.isNaN != true else {
                possible = possible.adding(NSDecimalNumber(string: a.possiblePoints))
                continue
            }
            
            total = total.adding(NSDecimalNumber(string: a.totalPoints))
            possible = possible.adding(NSDecimalNumber(string: a.possiblePoints))
        }
        
        return (total.stringValue, possible.stringValue)
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
