//
//  ProfileVC.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 7/30/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit
import Alamofire
fileprivate func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

class ProfileVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var profilePicture: UIImage?
    var subjects: [Subject]?
    var student: Student?
    var studentCount: Int {
        let count = Int(Student.mr_countOfEntities())
        return count
    }
    var selectedSubject: Subject?

    @IBOutlet var activityIndicator: UIActivityIndicatorView!

    @IBOutlet var tableview: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableview.delegate = self
        tableview.dataSource = self

        // Do any additional setup after loading the view.
        loadStudent()

        NotificationCenter.default.addObserver(self, selector: #selector(loadStudent), name: NSNotification.Name(rawValue: "loadStudent"), object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        if let student = student {
            subjects = student.subjects?.allObjects as? [Subject]
            subjects?.sort(by: {s1, s2 in return s1.name < s2.name})
            tableview.reloadData()
        }
    }

    func loadStudent() {
        student = Student.mr_findFirst(byAttribute: "name", withValue: UserDefaults.standard.string(forKey: "selectedStudent")!)
        if let student = student {
            subjects = student.subjects?.allObjects as? [Subject]
            subjects?.sort(by: {s1, s2 in return s1.name < s2.name})
        }
        startLoadingAnimation()
        getImage(student!.id!) { image in
            DispatchQueue.main.async {
                self.profilePicture = image
                self.stopLoadingAnimation()
                self.tableview.reloadData()
            }
        }
    }

    func getImage(_ studentID: String, completion: @escaping (UIImage?) -> Void) {
        Manager.sharedInstance.request("http://localhost/CommunityWebPortal/GetPic.cfm-id=" + self.student!.id! + ".jpeg").responseData(completionHandler: {response in
            if let data = response.data {
                completion(UIImage(data: data, scale: 1))
            } else {
                completion(nil)
            }
        })
    }

    func startLoadingAnimation() {
        activityIndicator.startAnimating()
        tableview.isHidden = true
    }

    func stopLoadingAnimation() {
        activityIndicator.stopAnimating()
        tableview.isHidden = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func calculateGPA(weighted: Bool) -> String? {
        var total: NSDecimalNumber = 0
        var totalCredits: NSDecimalNumber = 0

        guard let student = student, let subjects = Subject.mr_findAll(with: NSPredicate(format: "ANY markingPeriods.empty == false AND student == %@", argumentArray: [student])) as? [Subject] else {
            return nil
        }

        for subject in subjects {
            if let string = calculateAverageGrade(subject, roundToWholeNumber: false) {
                let grade = NSDecimalNumber(string: string)
                let weightedGrade: NSDecimalNumber

                if weighted {
                    weightedGrade = grade.multiplying(by: subject.weight)
                } else {
                    weightedGrade = grade
                }

                let creditWeightedGrade = weightedGrade.multiplying(by: subject.credits)
                total = total.adding(creditWeightedGrade)
                totalCredits = totalCredits.adding(subject.credits)
            }
        }

        guard totalCredits.compare(NSDecimalNumber(value: 0)) == .orderedDescending else {
            return nil
        }

        let numberFormatter = NumberFormatter()
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumIntegerDigits = 1
        numberFormatter.roundingMode = .halfUp
        numberFormatter.numberStyle = .decimal

        let gpa = total.dividing(by: totalCredits)
        return numberFormatter.string(from: gpa)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "GPA"
        } else if section == 2 {
            return "Course Averages"
        }

        return nil
    }

    // Hide the headers and footers when the switch profile section should be hidden. Also hide the header and footer for the first section

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 165 : UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 && studentCount == 1 {
            return 0.01
        } else if section == 0 && studentCount > 1 {
            return 10
        }
        return section == 0 && studentCount == 1 ? 0.01 : UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 {
            return "This is calculated using the weight and credits from each subject."
        }
        return nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return studentCount > 1 ? 1 : 0
        } else if section == 1 {
            return 2
        } else {
            guard let subjects = subjects else {
                return 0
            }
            return subjects.count
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "profileStudentCell") as! ProfileStudentCell
            if let student = student {
                cell.nameLabel.text = student.name
                cell.gradeLabel.text = "Grade " + student.grade!
                cell.schoolLabel.text = student.school

                cell.picture.layer.cornerRadius = 11
                cell.picture.clipsToBounds = true
                cell.picture.image = profilePicture
            }
            return cell
        }
        return nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.section == 0 {
            let cell = tableview.dequeueReusableCell(withIdentifier: "switchProfileCell")!
            return cell
        } else if indexPath.section == 1 {
            let cell = UITableViewCell(style: .value1, reuseIdentifier: "gpaCell")
            cell.selectionStyle = .none
            cell.detailTextLabel?.textColor = UIColor(red: 7, green: 89, blue: 128)
            cell.detailTextLabel?.text = "N/A"
            if indexPath.row == 0 {
                cell.textLabel?.text = "Unweighted"
                if let gpa = calculateGPA(weighted: false) {
                    cell.detailTextLabel?.text = gpa + "%"
                }
            } else {
                cell.textLabel?.text = "Weighted"
                if let gpa = calculateGPA(weighted: true) {
                    cell.detailTextLabel?.text = gpa + "%"
                }
            }

            return cell
        }

        let cell = tableview.dequeueReusableCell(withIdentifier: "profileSubjectCell") as! ProfileSubjectCell
        let subject = subjects![indexPath.row]
        cell.name.text = subject.name

        if let average = calculateAverageGrade(subject) {
            cell.percentGrade.text = average + "%"
        } else {
            if let ytd = dictionaryFromOtherGradesJSON(subject.otherGrades)?["YTD"] {
                cell.percentGrade.text = ytd + "%"
            } else {
                cell.percentGrade.text = "N/A"
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            performSegue(withIdentifier: "switchStudent", sender: self)
        } else if indexPath.section == 2 {
            selectedSubject = subjects![indexPath.row]
            performSegue(withIdentifier: "subjectInfo", sender: self)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "subjectInfo" {
            let subjectInfoVC = segue.destination as! SubjectInfoVC
            subjectInfoVC.subject = selectedSubject
        }
    }

}
