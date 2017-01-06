//
//  ProfileVC.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 7/30/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit
import Alamofire
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
            subjects?.sort(by: {s1, s2 in return s1.name! < s2.name})
            tableview.reloadData()
        }
    }
    
    func loadStudent() {
        student = Student.mr_findFirst(byAttribute: "name", withValue: UserDefaults.standard.string(forKey: "selectedStudent")!)
        if let student = student {
            subjects = student.subjects?.allObjects as? [Subject]
            subjects?.sort(by: {s1, s2 in return s1.name! < s2.name})
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
        Manager.sharedInstance.request("https://pamet-sapphire.k12system.com/CommunityWebPortal/GetPic.cfm?id=" + self.student!.id!).responseData(completionHandler: {response in
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 1 ? "Course Averages" : nil
    }
    
    // Hide the headers and footers when the switch profile section should be hidden. Also hide the header and footer for the first section
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 165 : UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == 0 && studentCount == 1 ? 0.01 : UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return studentCount > 1 ? 1 : 0
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
        }
        
        let cell = tableview.dequeueReusableCell(withIdentifier: "profileSubjectCell") as! ProfileSubjectCell
        let subject = subjects![indexPath.row]
        cell.name.text = subject.name
        
        if let ytd = dictionaryFromOtherGradesJSON(subject.otherGrades)?["YTD"] {
            cell.percentGrade.text = ytd + "%"
        } else {
            if let average = calculateAverageGrade(subject) {
                cell.percentGrade.text = average + "%"
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
        } else {
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
