//
//  ProfileVC.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 7/30/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit
import Alamofire

class ProfileVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var profilePicture: UIImage?
    var subjects: [Subject]?
    var student: Student?
    var studentCount: Int {
        let count = Int(Student.MR_countOfEntities())
        return count
    }
    @IBOutlet var activityIndicator: UIActivityIndicatorView!

    @IBOutlet var tableview: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableview.delegate = self
        tableview.dataSource = self

        // Do any additional setup after loading the view.
        loadStudent()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(loadStudent), name: "loadStudent", object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        if let student = student {
            subjects = student.subjects?.allObjects as? [Subject]
            subjects?.sortInPlace({s1, s2 in return s1.name! < s2.name})
            tableview.reloadData()
        }
    }
    
    func loadStudent() {
        student = Student.MR_findFirstByAttribute("name", withValue: NSUserDefaults.standardUserDefaults().stringForKey("selectedStudent")!)
        if let student = student {
            subjects = student.subjects?.allObjects as? [Subject]
            subjects?.sortInPlace({s1, s2 in return s1.name! < s2.name})
        }
        startLoadingAnimation()
        getImage(student!.id!) { image in
            dispatch_async(dispatch_get_main_queue()) {
                self.profilePicture = image
                self.stopLoadingAnimation()
                self.tableview.reloadData()
            }
        }
    }
    
    func getImage(studentID: String, completion: (UIImage) -> Void) {
        Alamofire.request(.GET, "http://192.168.1.3/CommunityWebPortal/GetPic.cfm-id=" + self.student!.id! + ".jpeg").responseData(completionHandler: {response in // TODO: Change this back ty
            if let data = response.data {
                completion(UIImage(data: data, scale: 1)!)
            }
        })
    }
    
    func startLoadingAnimation() {
        activityIndicator.startAnimating()
        tableview.hidden = true
    }
    
    func stopLoadingAnimation() {
        activityIndicator.stopAnimating()
        tableview.hidden = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 1 ? "Courses" : nil
    }
    
    // Hide the headers and footers when the switch profile section should be hidden. Also hide the header and footer for the first section
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 165 : UITableViewAutomaticDimension
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == 0 && studentCount == 1 ? 0.01 : UITableViewAutomaticDimension
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return studentCount > 1 ? 1 : 0
        } else {
            guard let subjects = subjects else {
                return 0
            }
            return subjects.count
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("profileStudentCell") as! ProfileStudentCell
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
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableview.dequeueReusableCellWithIdentifier("switchProfileCell")!
            return cell
        }
        
        let cell = tableview.dequeueReusableCellWithIdentifier("profileSubjectCell") as! ProfileSubjectCell
        let subject = subjects![indexPath.row]
        cell.name.text = subject.name
        
        if let ytd = dictionaryFromOtherGradesJSON(subject.otherGrades)?["YTD"] {
            cell.percentGrade.text = ytd + "%"
        } else {
            cell.percentGrade.text = calculateAverageGrade(subject)
        }
        
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if indexPath.section == 0 {
            performSegueWithIdentifier("switchStudent", sender: self)
        } else {
            
        }
    }
    
    func calculateAverageGrade(subject: Subject) -> String? {
        guard let markingPeriods = subject.markingPeriods?.allObjects as? [MarkingPeriod] else {
            return nil
        }
        
        var total: NSDecimalNumber = 0
        var mpCount: NSDecimalNumber = 0
        for mp in markingPeriods {

            // Remove %
            guard let percentgradeString = mp.percentGrade?.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "1234567890.").invertedSet).joinWithSeparator("") else {
                break
            }
            
            total = total.decimalNumberByAdding(NSDecimalNumber(string: percentgradeString))
            mpCount = mpCount.decimalNumberByAdding(1)
        }
        
        if let mt = dictionaryFromOtherGradesJSON(subject.otherGrades)?["MT"] {
            mpCount = mpCount.decimalNumberByAdding(0.5)
            total = total.decimalNumberByAdding(NSDecimalNumber(string: mt))
        }
        
        if let fe = dictionaryFromOtherGradesJSON(subject.otherGrades)?["FE"] {
            mpCount = mpCount.decimalNumberByAdding(0.5)
            total = total.decimalNumberByAdding(NSDecimalNumber(string: fe))
        }
        
        if (mpCount.doubleValue == 0) {
            return nil
        }
        
        let average = total.decimalNumberByDividingBy(mpCount)
        return String(Int(round(average.doubleValue))) + "%"
    }
    
    
    func dictionaryFromOtherGradesJSON(string: String?) -> [String: String]? {
        guard let jsonData = string?.dataUsingEncoding(NSUTF8StringEncoding) else {
            return nil
        }
        
        do {
            return try NSJSONSerialization.JSONObjectWithData(jsonData, options: []) as? [String: String]
        } catch {
            return nil
        }
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
