//
//  DetailVC.swift
//  Grade Checker
//
//  Created by Dhruv Sringari on 4/24/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit

class DetailVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var percentGradeLabel: UILabel!
    @IBOutlet var courseNameLabel: UILabel!
    @IBOutlet var pointsLabel: UILabel!
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var toolbar: UIView!
    var navHairLine: UIImageView!
    
    
    var subject: Subject!
    var markingPeriods: [MarkingPeriod]!
    var selectedMPIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        
        
        // Find the hairline so we can hide it
        for view in self.navigationController!.navigationBar.subviews {
            for aView in view.subviews {
                if (aView.isKindOfClass(UIImageView) &&  aView.bounds.size.width == self.navigationController!.navigationBar.frame.size.width && aView.bounds.size.height < 2) {
                    self.navHairLine = aView as! UIImageView
                }
            }
        }
        // Setup Segmented Control
        // Get all the Valid Marking Periods
        let mps = subject.markingPeriods!.allObjects as! [MarkingPeriod]
        markingPeriods = mps.filter{!$0.empty!.boolValue}.sort{Int($0.number!) > Int($1.number!)} // Only want non empty marking periods
        segmentedControl.removeAllSegments()
        for index in 0...markingPeriods.count-1 {
            segmentedControl.insertSegmentWithTitle("MP " + markingPeriods[index].number!, atIndex: index, animated: false)
        }
        segmentedControl.selectedSegmentIndex = selectedMPIndex
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        moveHairLineToToolbar(true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        moveHairLineToToolbar(false)
    }
    
    func moveHairLineToToolbar(appearing: Bool) {
        var hairLineFrame = self.navHairLine.frame
        if (appearing) {
            hairLineFrame.origin.y += self.toolbar.bounds.size.height
        } else {
            hairLineFrame.origin.y -= self.toolbar.bounds.size.height
        }
        self.navHairLine.frame = hairLineFrame
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func segmentedControlChanged(sender: AnyObject) {
        selectedMPIndex = segmentedControl.selectedSegmentIndex
        self.tableView.reloadData()
    }
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Assignments"
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let assignments: [Assignment] = markingPeriods[selectedMPIndex].assignments!.allObjects as! [Assignment]
        return assignments.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("assignmentCell", forIndexPath: indexPath) as! AssignmentTableViewCell
        let mp = markingPeriods[selectedMPIndex]
        var assignments: [Assignment] = mp.assignments!.allObjects as! [Assignment]
        // sort by date
        assignments.sortInPlace{ $0.date!.compare($1.date!) == NSComparisonResult.OrderedDescending }
        cell.assignmentNameLabel.text = assignments[indexPath.row].name
        cell.pointsGradeLabel.text = assignments[indexPath.row].totalPoints! + "/" + assignments[indexPath.row].possiblePoints!
        return cell
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
