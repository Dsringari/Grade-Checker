//
//  SubjectInfoVC.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 9/3/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit
import MagicalRecord
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


class SubjectInfoVC: UITableViewController  {
    
    var subject: Subject!
    var average: String = "N/A"
    var calculatedAverage: String = "N/A"
    var markingPeriods: [MarkingPeriod] = []
    var selectedMPNumber: String = "1"
    var cells : [CellType] = []
    
    var accessoryView: UIView = {
        let keyboardDoneButtonView = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        keyboardDoneButtonView.items = [doneButton]
        return keyboardDoneButtonView
    }()
    
    
    enum CellType {
        case markingPeriod(number: String, grade: String)
        case other(name: String, grade: String)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
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
        } else if section == 1 {
            return "Grades"
        } else {
            return "Settings"
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return "The official average is the YTD, which is updated at the end of the marking period. The calculated average is determined by weighing each marking period as 20% of your final grade. The final exam and midterm make up the last 20%."
        } else if section == 1 {
            return "When midterm and final exam grades are posted, you can see them here."
        } else {
            return "This is used to calculate your GPA for the year."
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return cells.count == 0 ? 1 : 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else if section == 1 {
            return cells.count

        } else {
            return 2
        }
    }
    
    func creditsChanged(_ textField: UITextField) {
        if verify(text: textField.text) {
            subject.credits = NSDecimalNumber(string: textField.text)
            NSManagedObjectContext.mr_default().mr_save({ context in
                if let subject = self.subject.mr_(in: context) {
                    subject.credits = NSDecimalNumber(string: textField.text)
                }
            })
        } else {
            textField.text = subject.credits.stringValue
        }
    }
    
    func weightChanged(_ textField: UITextField) {
        if verify(text: textField.text) {
            NSManagedObjectContext.mr_default().mr_save({ context in
                if let subject = self.subject.mr_(in: context) {
                    subject.weight = NSDecimalNumber(string: textField.text)
                }
            })
        } else {
            textField.text = subject.weight.stringValue
        }
    }
    
    func verify(text: String?) -> Bool {
        if let text = text, text != "" {
            if let decimal = Decimal(string: text) {
                return decimal >= 0
            }
        }
        return false
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
        } else if indexPath.section == 2 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "subjectOptionCell", for: indexPath) as! SubjectOptionCell
            cell.textField.inputAccessoryView = accessoryView
            if indexPath.row == 0 {
                cell.name.text = "Credits"
                cell.textField.text = subject.credits.stringValue
                cell.textField.addTarget(self, action: #selector(creditsChanged(_:)), for: .editingDidEnd)
            } else {
                cell.name.text = "Weight"
                cell.textField.text = subject.weight.stringValue
                cell.textField.addTarget(self, action: #selector(weightChanged(_:)), for: .editingDidEnd)
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
