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
    var selectedSubject: Subject?
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!

    @IBOutlet var tableview: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableview.delegate = self
        tableview.dataSource = self

        // Do any additional setup after loading the view.
    }
    
    var subjectNames = ["Algebra 2/Trig", "Honors English 9", "Chemistry 3", "World Literature Basics", "SPANISH 4 HON", "Legendary Tropics of Java"]
    var subjectPercentages = ["97%", "88%", "76%", "92%", "100%", "83%"]
    
    override func viewDidAppear(animated: Bool) {
        
    }
    
    func getImage(studentID: String, completion: (UIImage?) -> Void) {
        Alamofire.request(.GET, "https://pamet-sapphire.k12system.com/CommunityWebPortal/GetPic.cfm?id=" + self.student!.id!).responseData(completionHandler: {response in
            if let data = response.data {
                completion(UIImage(data: data, scale: 1))
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
        return section == 1 ? "Course Averages" : nil
    }
    
    // Hide the headers and footers when the switch profile section should be hidden. Also hide the header and footer for the first section
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 165 : UITableViewAutomaticDimension
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return section == 0 && studentCount == 1 ? 0.01 : UITableViewAutomaticDimension
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : subjectNames.count
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("profileStudentCell") as! ProfileStudentCell
            
                cell.nameLabel.text = "Andrew"
                cell.gradeLabel.text = "Grade 10"
                cell.schoolLabel.text = "Methacton Highschool"
                
                cell.picture.layer.cornerRadius = 11
                cell.picture.clipsToBounds = true
            
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
        cell.name.text = subjectNames[indexPath.row]
        cell.percentGrade.text = subjectPercentages[indexPath.row]
        
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if indexPath.section == 0 {
            performSegueWithIdentifier("switchStudent", sender: self)
        } else {
            performSegueWithIdentifier("subjectInfo", sender: self)
        }
    }
    
        


    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "subjectInfo" {
            let subjectInfoVC = segue.destinationViewController as! SubjectInfoVC
        }
    }


}
