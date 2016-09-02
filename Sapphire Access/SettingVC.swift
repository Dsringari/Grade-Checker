//
//  SettingVC.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 9/2/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit
import StaticDataTableViewController
import CoreData

class SettingVC: StaticDataTableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return section == 0 ? 3 : 1
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if indexPath.section == 1 && indexPath.row == 0 {
            logout()
        }
    }
    
    func logout() {
        User.MR_deleteAllMatchingPredicate(NSPredicate(value: true))
        NSManagedObjectContext.MR_defaultContext().MR_saveToPersistentStoreAndWait()
        NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "selectedStudent")
        
        navigationController?.tabBarController?.navigationController?.popToRootViewControllerAnimated(true)
        NSNotificationCenter.defaultCenter().postNotificationName("tabBarDismissed", object: nil)
        
        
        
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
