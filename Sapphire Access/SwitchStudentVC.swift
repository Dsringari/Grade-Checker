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
    var selectedStudentName: String? = UserDefaults.standard.string(forKey: "selectedStudent")

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let students = Student.mr_findAll() {
            self.students = students as! [Student]
            self.students = self.students.sorted{$0.grade! < $1.grade!}
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

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return students.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if selectedStudentName != students[(indexPath as NSIndexPath).row].name {
            UserDefaults.standard.set(students[(indexPath as NSIndexPath).row].name, forKey: "selectedStudent")
            selectedStudentName = students[(indexPath as NSIndexPath).row].name
            tableView.reloadData()
            NotificationCenter.default.post(name: Notification.Name("loadStudent"), object: nil)
            navigationController?.tabBarController?.selectedIndex = 0
            _ = navigationController?.popViewController(animated: false)
            
            
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        cell.textLabel?.text = students[(indexPath as NSIndexPath).row].name
        
        if let selectedStudentName = selectedStudentName , selectedStudentName == cell.textLabel?.text {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
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
