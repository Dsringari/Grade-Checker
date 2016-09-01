//
//  SwitchStudentVC.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 9/1/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit

class SwitchStudentVC: UITableViewController {
    
    var students: [Student] = []
    var selectedStudentName: String? = NSUserDefaults.standardUserDefaults().stringForKey("selectedStudent")

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let students = Student.MR_findAll() {
            self.students = students as! [Student]
            self.students = self.students.sort{$0.grade < $1.grade}
        }

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return students.count
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if selectedStudentName != students[indexPath.row].name {
            NSUserDefaults.standardUserDefaults().setObject(students[indexPath.row].name, forKey: "selectedStudent")
            selectedStudentName = students[indexPath.row].name
            tableView.reloadData()
            NSNotificationCenter.defaultCenter().postNotificationName("loadStudent", object: nil)
            navigationController?.tabBarController?.selectedIndex = 0
            navigationController?.popViewControllerAnimated(false)
            
            
        }
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        cell.textLabel?.text = students[indexPath.row].name
        
        if let selectedStudentName = selectedStudentName where selectedStudentName == cell.textLabel?.text {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }

        // Configure the cell...

        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
