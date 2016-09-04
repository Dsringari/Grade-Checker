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
        
        self.title = subject.name
        
        markingPeriods = subject.markingPeriods!.allObjects as! [MarkingPeriod]
        markingPeriods = markingPeriods.filter{!$0.empty!.boolValue}
        markingPeriods.sortInPlace{$0.number < $1.number}
        
        let otherInfo = dictionaryFromOtherGradesJSON(subject.otherGrades)
        
        if let ytd = otherInfo?["YTD"] {
            average = ytd + "%"
            print("Calculated Average: \(calculateAverageGrade(subject, roundToWholeNumber: false)!)")
        } else {
            if let average = calculateAverageGrade(subject, roundToWholeNumber: false) {
                self.average = average + "%"
            } else {
                self.average = "N/A"
            }
        }
        
        // ORDER IS VERY IMPORTANT HERE
        
        for mp in markingPeriods {
            if Int(mp.number!)! <= 2 {
                cells.append(CellType.MarkingPeriod(number: mp.number!, grade: mp.percentGrade!))
            }
        }
        
        if let mt = otherInfo?["MT"] {
            cells.append(CellType.Other(name: "Mid-Term", grade: mt))
        }
        
        for mp in markingPeriods {
            if Int(mp.number!)! > 2 {
                cells.append(CellType.MarkingPeriod(number: mp.number!, grade: mp.percentGrade!))
            }
        }
        
        if let fe = otherInfo?["FE"] {
            cells.append(CellType.Other(name: "Final Exam", grade: fe))
        }
        

        
        
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
