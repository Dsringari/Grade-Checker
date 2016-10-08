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

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return section == 0 ? 3 : 1
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if (indexPath as NSIndexPath).section == 1 && (indexPath as NSIndexPath).row == 0 {
            logout()
        }
    }
    
    func logout() {
        User.mr_deleteAll(matching: NSPredicate(value: true))
        NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait()
        UserDefaults.standard.set(nil, forKey: "selectedStudent")
        
        _ = navigationController?.tabBarController?.navigationController?.popToRootViewController(animated: true)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "tabBarDismissed"), object: nil)
        
        
        
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
