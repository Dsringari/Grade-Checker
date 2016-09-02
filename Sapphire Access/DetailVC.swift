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
    @IBOutlet var toolbar: UIView!
    @IBOutlet var percentageButton: UIButton!
    @IBOutlet var pointsButton: UIButton!
    @IBOutlet var toolbarHeight: NSLayoutConstraint!
    
    var navHairLine: UIImageView!
    var subject: Subject!
    var markingPeriods: [MarkingPeriod]!
    var categories: [String] = []
    var selectedMPIndex: Int!
    var gradeViewType: GradeViewType = .Point
    var sortMethod: Sorting = .Recent
    var assignmentsToSetOld: [Assignment] = []
    
    enum GradeViewType {
        case Point
        case Percentage
    }
    
    enum Sorting {
        case Recent
        case Category
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 44
        self.title = subject.name
       
        
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
        
        // Setup Segmented Control
        // Get all the Valid Marking Periods
        let mps = subject.markingPeriods!.allObjects as! [MarkingPeriod]
        markingPeriods = mps.filter{!$0.empty!.boolValue}.sort{Int($0.number!) < Int($1.number!)} // Only want non empty marking periods
        segmentedControl.removeAllSegments()
        for index in 0..<markingPeriods.count {
            segmentedControl.insertSegmentWithTitle("MP " + markingPeriods[index].number!, atIndex: index, animated: false)
        }
        selectedMPIndex = markingPeriods.count - 1
        segmentedControl.selectedSegmentIndex = selectedMPIndex
        segmentedControl.sizeToFit()
        calculateCategories(markingPeriodIndex: selectedMPIndex)
        percentageButton.setTitle(markingPeriods[selectedMPIndex].percentGrade, forState: .Normal)
        pointsButton.setTitle(markingPeriods[selectedMPIndex].totalPoints! + "/" + markingPeriods[selectedMPIndex].possiblePoints!, forState: .Normal)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(dismissSelf), name: "loadStudent", object: nil)
        
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
    
    
    @IBAction func segmentedControlChanged(sender: AnyObject) {
        selectedMPIndex = segmentedControl.selectedSegmentIndex
        calculateCategories(markingPeriodIndex: selectedMPIndex)
        percentageButton.setTitle(markingPeriods[selectedMPIndex].percentGrade, forState: .Normal)
        pointsButton.setTitle(markingPeriods[selectedMPIndex].totalPoints! + "/" + markingPeriods[selectedMPIndex].possiblePoints!, forState: .Normal)
        setShownUpdatesOld()
        self.tableView.reloadData()
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
        showOrHideOptions(0.33)
        self.tableView.reloadData()
    }
    
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sortMethod == .Recent ? 1 : categories.count
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.contentView.backgroundColor = UIColor.groupTableViewBackgroundColor()
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if sortMethod == .Category {
            let header = UITableViewHeaderFooterView(frame: CGRectMake(0,0,tableView.frame.size.width,10))
        
            let totalLabel: UILabel = UILabel()
            let totals = totalScore(categories[section])
        
            if (gradeViewType == .Point) {
                totalLabel.text = totals.totalPoints + "/" + totals.possiblePoints
            } else {
                totalLabel.text = percentage(totals.totalPoints, possiblePoints: totals.possiblePoints)
            }
            
            totalLabel.textColor = UIColor.lightGrayColor()

        
            totalLabel.translatesAutoresizingMaskIntoConstraints = false
            header.addSubview(totalLabel)
        
            NSLayoutConstraint(item: totalLabel, attribute: .Trailing, relatedBy: .Equal, toItem: header, attribute: .TrailingMargin, multiplier: 1, constant: 8).active = true
            NSLayoutConstraint(item: totalLabel, attribute: .CenterY, relatedBy: .Equal, toItem: header, attribute: .CenterY, multiplier: 1, constant: 0).active = true
            return header
        }
        
        return nil
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sortMethod == .Recent ? "Assignments" : categories[section].capitalizedString
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if sortMethod == .Recent {
            let assignments: [Assignment] = markingPeriods[selectedMPIndex].assignments!.allObjects as! [Assignment]
            return assignments.count
        } else {
            let category = categories[section]
            var assignments = markingPeriods[selectedMPIndex].assignments!.allObjects as! [Assignment]
            assignments = assignments.filter{return $0.category == category}
            return assignments.count
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44
    }
    
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("assignmentCell", forIndexPath: indexPath) as! AssignmentTableViewCell
        let mp = markingPeriods[selectedMPIndex]
        
        var assignments: [Assignment]
        if sortMethod == .Recent {
            assignments = mp.assignments!.allObjects as! [Assignment]
        } else {
            let category = categories[indexPath.section]
            assignments = mp.assignments!.allObjects as! [Assignment]
            assignments = assignments.filter{return $0.category == category}
        }
        
        // sort by date
        assignments.sortInPlace{ $0.dateCreated!.compare($1.dateCreated!) == NSComparisonResult.OrderedDescending }
        cell.assignmentNameLabel.text = assignments[indexPath.row].name
        
        if (gradeViewType == .Point) {
            cell.pointsGradeLabel.text = assignments[indexPath.row].totalPoints! + "/" + assignments[indexPath.row].possiblePoints!
        } else {
            cell.pointsGradeLabel.text = percentage(assignments[indexPath.row].totalPoints!, possiblePoints: assignments[indexPath.row].possiblePoints!)
        }
        
        if assignments[indexPath.row].newUpdate.boolValue {
            cell.badge.image = UIImage(named: "Recently Updated")!
            if assignmentsToSetOld.indexOf(assignments[indexPath.row]) == nil {
                assignmentsToSetOld.append(assignments[indexPath.row])
            }
        } else {
            cell.badge.image = nil
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
