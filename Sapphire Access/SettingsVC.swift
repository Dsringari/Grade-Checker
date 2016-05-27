//
//  SettingsVC.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 5/25/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit
import StaticDataTableViewController
import MagicalRecord
import CoreData
import LocalAuthentication

protocol SettingsVCDelegate {
    func changeSelectedStudentName(name: String) -> Void
}

class SettingsVC: StaticDataTableViewController, SettingsVCDelegate {

    @IBOutlet var touchIDCell: UITableViewCell!
	@IBOutlet var touchIDSwitch: UISwitch!
	@IBOutlet var logoutCell: UITableViewCell!
	@IBOutlet var selectedStudentNameLabel: UILabel!

	let settings = NSUserDefaults.standardUserDefaults()
	lazy var touchIDCapable: Bool = {
		let able = LAContext().canEvaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, error: nil)
		return able
	}()

	override func viewDidLoad() {
		super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self

		if let selectedStudentName = settings.stringForKey("selectedStudent") {
			selectedStudentNameLabel?.text = selectedStudentName
		}

		touchIDSwitch.on = settings.boolForKey("useTouchID")
        
        if !touchIDCapable {
            cell(touchIDCell, setHidden: true)
        }
        
        reloadDataAnimated(false)
	}
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
       if indexPath.section == 3 {
            logout()
        }
    }
    
    func logout() {
        User.MR_deleteAllMatchingPredicate(NSPredicate(value: true))
        NSManagedObjectContext.MR_defaultContext().MR_saveToPersistentStoreAndWait()
        
        NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "selectedStudent")
        self.tabBarController!.navigationController!.popToRootViewControllerAnimated(true)
        NSNotificationCenter.defaultCenter().postNotificationName("tabBarDismissed", object: nil)
    }
    
    func changeSelectedStudentName(name: String) {
        selectedStudentNameLabel.text = name
    }

}
