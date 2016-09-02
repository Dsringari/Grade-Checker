//
//  AppearanceVC.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 9/2/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit

class AppearanceVC: UITableViewController {
    
    var sortMethod: Sorting = .Recent

    override func viewDidLoad() {
        super.viewDidLoad()

        let sortingNumber = NSUserDefaults.standardUserDefaults().integerForKey("sortMethod")
        sortMethod = Sorting(rawValue: sortingNumber)!

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 3
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == sortMethod.rawValue {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if (indexPath.row != sortMethod.rawValue) {
            sortMethod = Sorting(rawValue: indexPath.row)!
            NSUserDefaults.standardUserDefaults().setInteger(sortMethod.rawValue, forKey: "sortMethod")
            tableView.reloadData()
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
