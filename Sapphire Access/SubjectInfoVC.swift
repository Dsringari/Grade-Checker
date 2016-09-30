//
//  SubjectInfoVC.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 9/3/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit
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


class SubjectInfoVC: UITableViewController {
    
    var subject: Subject!
    var average: String = ""
    var markingPeriods: [MarkingPeriod] = []
    var selectedMPNumber: String = "1"
    var cells : [CellType] = []
    
    
    enum CellType {
        case markingPeriod(number: String, grade: String)
        case other(name: String, grade: String)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = subject.name
        
        markingPeriods = subject.markingPeriods!.allObjects as! [MarkingPeriod]
        markingPeriods = markingPeriods.filter{!$0.empty!.boolValue}
        markingPeriods.sort{$0.number < $1.number}
        
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
                cells.append(CellType.markingPeriod(number: mp.number!, grade: mp.percentGrade!))
            }
        }
        
        if let mt = otherInfo?["MT"] {
            cells.append(CellType.other(name: "Mid-Term", grade: mt))
        }
        
        for mp in markingPeriods {
            if Int(mp.number!)! > 2 {
                cells.append(CellType.markingPeriod(number: mp.number!, grade: mp.percentGrade!))
            }
        }
        
        if let fe = otherInfo?["FE"] {
            cells.append(CellType.other(name: "Final Exam", grade: fe))
        }
        

        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return cells.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath as NSIndexPath).section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "averageCell") as! AverageCell
            cell.averageLabel.text = "Average: " + average
            cell.selectionStyle = .none
            return cell
        }
        
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        let cellInfo = cells[(indexPath as NSIndexPath).row]
        
        switch cellInfo {
        case let .markingPeriod(number, grade):
            cell.textLabel?.text = "Marking Period \(number)"
            cell.detailTextLabel?.text = grade
            cell.detailTextLabel?.textColor = UIColor(red: 7, green: 89, blue: 128)
            cell.accessoryType = .disclosureIndicator
        case let .other(name, grade):
            cell.textLabel?.text = name
            cell.detailTextLabel?.text = grade + "%"
            cell.detailTextLabel?.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint(item: cell.detailTextLabel!, attribute: .trailing, relatedBy: .equal, toItem: cell.contentView, attribute: .trailingMargin, multiplier: 1, constant: -20).isActive = true
            NSLayoutConstraint(item: cell.detailTextLabel!, attribute: .centerY, relatedBy: .equal, toItem: cell.contentView, attribute: .centerY, multiplier: 1, constant: 0).isActive = true
            cell.contentView.layoutIfNeeded()
            cell.selectionStyle = .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard (indexPath as NSIndexPath).section == 1 else {return}
        
        if case let CellType.markingPeriod(number, _) = cells[(indexPath as NSIndexPath).row] {
            selectedMPNumber = number
            performSegue(withIdentifier: "showMP", sender: self)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showMP" {
            let detailVC = segue.destination as! DetailVC
            detailVC.subject = subject
            detailVC.viewType = DetailVC.ViewType.oneMarkingPeriod(markingPeriodNumber: selectedMPNumber)
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        }
    }
}
