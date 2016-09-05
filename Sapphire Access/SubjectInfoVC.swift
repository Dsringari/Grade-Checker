//
//  SubjectInfoVC.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 9/3/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit

class SubjectInfoVC: UITableViewController {
    
    var subject: Subject!
    var average: String = ""
    var markingPeriods: [MarkingPeriod] = []
    var selectedMPNumber: String = "1"
    var cells : [CellType] = []
    
    
    enum CellType {
        case MarkingPeriod(number: String, grade: String)
        case Other(name: String, grade: String)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Algebra 2/Trig"
        
        
        average = "97%"
        
        // ORDER IS VERY IMPORTANT HERE
        
        cells.append(CellType.MarkingPeriod(number: "1", grade: "95%"))
        cells.append(CellType.MarkingPeriod(number: "2", grade: "98%"))
        cells.append(CellType.Other(name: "Mid-Term", grade: "97"))
        cells.append(CellType.MarkingPeriod(number: "3", grade: "99%"))
        cells.append(CellType.MarkingPeriod(number: "4", grade: "94%"))
        cells.append(CellType.Other(name: "Final Exam", grade: "95"))
        

        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return cells.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("averageCell") as! AverageCell
            cell.averageLabel.text = "Average: " + average
            cell.selectionStyle = .None
            return cell
        }
        
        let cell = UITableViewCell(style: .Value1, reuseIdentifier: nil)
        let cellInfo = cells[indexPath.row]
        
        switch cellInfo {
        case let .MarkingPeriod(number, grade):
            cell.textLabel?.text = "Marking Period \(number)"
            cell.detailTextLabel?.text = grade
            cell.detailTextLabel?.textColor = UIColor(red: 7, green: 89, blue: 128)
            cell.accessoryType = .DisclosureIndicator
        case let .Other(name, grade):
            cell.textLabel?.text = name
            cell.detailTextLabel?.text = grade + "%"
            cell.detailTextLabel?.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint(item: cell.detailTextLabel!, attribute: .Trailing, relatedBy: .Equal, toItem: cell.contentView, attribute: .TrailingMargin, multiplier: 1, constant: -20).active = true
            NSLayoutConstraint(item: cell.detailTextLabel!, attribute: .CenterY, relatedBy: .Equal, toItem: cell.contentView, attribute: .CenterY, multiplier: 1, constant: 0).active = true
            cell.contentView.layoutIfNeeded()
            cell.selectionStyle = .None
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        guard indexPath.section == 1 else {return}
        
        if case let CellType.MarkingPeriod(number, _) = cells[indexPath.row] {
            selectedMPNumber = number
            performSegueWithIdentifier("showMP", sender: self)
        }
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showMP" {
            let detailVC = segue.destinationViewController as! DetailVC
            detailVC.subject = subject
            detailVC.viewType = DetailVC.ViewType.OneMarkingPeriod(markingPeriodNumber: selectedMPNumber)
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        }
    }
}
