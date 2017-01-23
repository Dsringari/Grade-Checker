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
    var average: String = "N/A"
    var calculatedAverage: String = "N/A"
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
        }
        
        if let average = calculateAverageGrade(subject, roundToWholeNumber: false) {
            calculatedAverage = average + "%"
        }
        
        // ORDER IS VERY IMPORTANT HERE
        
        for mp in markingPeriods {
            if Int(mp.number)! <= 2 {
                cells.append(CellType.markingPeriod(number: mp.number, grade: mp.percentGrade! + "%"))
            }
        }
        
        if let mt = otherInfo?["MT"] {
            cells.append(CellType.other(name: "Mid-Term", grade: mt))
        }
        
        for mp in markingPeriods {
            if Int(mp.number)! > 2 {
                cells.append(CellType.markingPeriod(number: mp.number, grade: mp.percentGrade! + "%"))
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
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Averages"
        } else {
            return "Grades"
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return "The official average is the YTD. The calculated average is calculated by weighting each marking period as 20% of the final grade. The final exam and midterm make up the last 20%."
        } else {
            return "You can see the midterm and final averages here, when they are available."
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return cells.count == 0 ? 1 : 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        }
        return cells.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.detailTextLabel?.textColor = UIColor(red: 7, green: 89, blue: 128)
            cell.selectionStyle = .none
            if indexPath.row == 0 {
                cell.textLabel?.text = "Official"
                cell.detailTextLabel?.text = average
            } else {
                cell.textLabel?.text = "Calculated"
                cell.detailTextLabel?.text = calculatedAverage
            }
            return cell
        }
        
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        let cellInfo = cells[indexPath.row]
        
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
        guard indexPath.section == 1 else {return}
        
        if case let CellType.markingPeriod(number, _) = cells[indexPath.row] {
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
