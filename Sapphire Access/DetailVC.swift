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
    var gradeViewType: GradeViewType = .Point
    var sortMethod: Sorting = .Recent
    var assignmentsToSetOld: [Assignment] = []
    var viewType: ViewType = .AllMarkingPeriods
    
    
    enum ViewType {
        case AllMarkingPeriods
        case OneMarkingPeriod(markingPeriodNumber: String)
    }
    
    enum GradeViewType {
        case Point
        case Percentage
    }
    
    enum Sorting {
        case Recent
        case Category
    }
    
    var assignmentNames: [String] = []
    var assignmentPoints: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 44
       
        
        // Find the hairline so we can hide it
        for view in self.navigationController!.navigationBar.subviews {
            for aView in view.subviews {
                if (aView.isKindOfClass(UIImageView) &&  aView.bounds.size.width == self.navigationController!.navigationBar.frame.size.width && aView.bounds.size.height < 2) {
                    aView.removeFromSuperview()
                }
            }
        }
        // Remove toolbar's border
        self.navigationController!.toolbar.clipsToBounds = true
        self.title = "Algebra 2/Trig"
        self.segmentedControl.selectedSegmentIndex = 3
        self.pointsButton.setTitle("330/336", forState: .Normal)
        self.percentageButton.setTitle("96.46%", forState: .Normal)
        
        assignmentNames = ["Chapter 15 Quiz","Chapter 14 Test","Homework 2","Homework 1","Chapter 13 Test","Chapter 11 Test","Extra Packet","Worksheet #5"]
        assignmentPoints = ["42/50","38/40","5/5","4/5","95/100","93/100","90/100","5/5","9/10"]
        
        
        self.tabBarController?.tabBar.items![1].badgeValue = "A"
       
        
    }
    
    func dismissSelf() {
        navigationController?.popViewControllerAnimated(false)
    }
    
    func setShownUpdatesOld() {
        for a in assignmentsToSetOld {
            a.newUpdate = NSNumber(bool: false)
        }
        NSManagedObjectContext.MR_defaultContext().MR_saveToPersistentStoreAndWait()

    }
    
    override func viewWillDisappear(animated: Bool) {
        setShownUpdatesOld()
    }
    
    @IBAction func showPoints() {
        gradeViewType = .Point
        pointsButton.setBackgroundImage(UIImage(named: "SelectedViewTypeBackground"), forState: .Normal)
        percentageButton.setBackgroundImage(nil, forState: .Normal)
        tableView.reloadData()
    }
    
    @IBAction func showPercentage() {
        gradeViewType = .Percentage
        percentageButton.setBackgroundImage(UIImage(named: "SelectedViewTypeBackground"), forState: .Normal)
        pointsButton.setBackgroundImage(nil, forState: .Normal)
        tableView.reloadData()
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    @IBAction func showHideFilterOptions(sender: AnyObject) {
        showOrHideOptions()
    }
    
    func showOrHideOptions(delay: Double = 0) {
        if toolbarHeight.constant == 44 {
            self.toolbarHeight.constant = 80
        } else {
            self.toolbarHeight.constant = 44
        }
        
        UIView.animateWithDuration(0.5, delay: delay, usingSpringWithDamping: 0.66, initialSpringVelocity: 1, options: [], animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    @IBAction func sortingMethodChanged(sender: AnyObject) {
        if sortingSegmentedControl.selectedSegmentIndex == 0 {
            sortMethod = .Recent
        } else {
            sortMethod = .Category
        }
        
        if case ViewType.AllMarkingPeriods = viewType {
            showOrHideOptions(0.33)
        }
        self.tableView.reloadData()
    }
    
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sortMethod == .Recent ? 1 : categories.count
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.contentView.backgroundColor = UIColor.groupTableViewBackgroundColor()
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sortMethod == .Recent ? "Assignments" : categories[section].capitalizedString
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assignmentNames.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("assignmentCell", forIndexPath: indexPath) as! AssignmentTableViewCell
        cell.assignmentNameLabel.text = assignmentNames[indexPath.row]
        cell.pointsGradeLabel.text = assignmentPoints[indexPath.row]
        
        if indexPath.row != 0 || indexPath.row != 1 {
            cell.badge.hidden =  true
        }
        
        return cell
    }
    
    func percentage(totalPoints: String, possiblePoints: String) -> String {
        let totalPointsNumber = NSDecimalNumber(string: totalPoints)
        let possiblePointsNumber = NSDecimalNumber(string: possiblePoints)
        
        let numberFormatter = NSNumberFormatter()
        numberFormatter.minimumFractionDigits = 1
        numberFormatter.maximumFractionDigits = 1
        numberFormatter.minimumIntegerDigits = 1
        numberFormatter.roundingMode = .RoundHalfUp
        numberFormatter.numberStyle = .DecimalStyle
        
        guard possiblePointsNumber.compare(0) != .OrderedSame else {
            return "N/A"
        }
        
        let percentage = totalPointsNumber.decimalNumberByDividingBy(possiblePointsNumber).decimalNumberByMultiplyingBy(100)
        return numberFormatter.stringFromNumber(percentage)! + "%"
        
    }
    
    
    func calculateCategories(markingPeriodIndex num: Int) {
        let mp = markingPeriods[num]
        
        let assignments = mp.assignments!.allObjects as! [Assignment]
        
        var categories: [String] = []
        for a in assignments {
            if let category = a.category where categories.indexOf(category) == nil {
                categories.append(category)
            }
        }
        
        categories.sortInPlace{$0 > $1}
        self.categories = categories
    }
    
    func totalScore(category: String) -> (totalPoints: String, possiblePoints: String) {
        var assignments = markingPeriods[selectedMPIndex].assignments!.allObjects as! [Assignment]
        assignments = assignments.filter{$0.category == category}
        
        var total: NSDecimalNumber = 0
        var possible: NSDecimalNumber = 0
        for a in assignments {
            
            let totalPoints = NSDecimalNumber(string: a.totalPoints)
            guard totalPoints.doubleValue.isNaN != true else {
                possible = possible.decimalNumberByAdding(NSDecimalNumber(string: a.possiblePoints))
                continue
            }
            
            total = total.decimalNumberByAdding(NSDecimalNumber(string: a.totalPoints))
            possible = possible.decimalNumberByAdding(NSDecimalNumber(string: a.possiblePoints))
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
