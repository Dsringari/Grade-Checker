//
//  ProfileVC.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 7/30/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit

class ProfileVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var profilePictureView: UIImageView!
    var subjects: [Subject]?
    var student: Student?

    @IBOutlet var tableview: UITableView!
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var gradeLabel: UILabel!
    @IBOutlet var schoolLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableview.delegate = self
        tableview.dataSource = self
        profilePictureView.layer.cornerRadius = 11
        profilePictureView.clipsToBounds = true

        // Do any additional setup after loading the view.
        loadStudent()
        
    }
    
    func loadStudent() {
        student = Student.MR_findFirstByAttribute("name", withValue: NSUserDefaults.standardUserDefaults().stringForKey("selectedStudent")!)
        if let student = student {
            nameLabel.text = student.name
            gradeLabel.text = "Grade " + student.grade!
            schoolLabel.text = student.school
            subjects = student.subjects?.allObjects as? [Subject]
            subjects?.sortInPlace({s1, s2 in return s1.name! < s2.name})
        }
        
        tableview.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "" : "Courses"
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            guard let subjects = subjects else {
                return 0
            }
            return subjects.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableview.dequeueReusableCellWithIdentifier("switchProfileCell")!
            return cell
        }
        
        let cell = tableview.dequeueReusableCellWithIdentifier("profileSubjectCell") as! ProfileSubjectCell
        let subject = subjects![indexPath.row]
        cell.name.text = subject.name
        if var markingPeriods = subject.markingPeriods?.allObjects as? [MarkingPeriod] {
            markingPeriods.sortInPlace({mp1, mp2 in return mp1.number! > mp2.number!})
            if let mp = markingPeriods.first {
                cell.percentGrade.text = mp.percentGrade
            }
        }
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
