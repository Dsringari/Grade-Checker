//
//  AppearanceVC.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 9/2/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit

class AppearanceOptionsVC: UITableViewController {

    var sortMethod: Sorting = .recent

    override func viewDidLoad() {
        super.viewDidLoad()

        let sortingNumber = UserDefaults.standard.integer(forKey: "sortMethod")
        if let sort = Sorting(rawValue: sortingNumber) {
            sortMethod = sort
        } else {
            sortMethod = .recent
            UserDefaults.standard.set(Sorting.recent.rawValue, forKey: "sortMethod")
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 3
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == sortMethod.rawValue {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if (indexPath.row != sortMethod.rawValue) {
            sortMethod = Sorting(rawValue: indexPath.row)!
            UserDefaults.standard.set(sortMethod.rawValue, forKey: "sortMethod")
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
