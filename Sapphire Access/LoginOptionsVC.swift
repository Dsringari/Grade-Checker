//
//  LoginOptionsVC.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 9/3/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit
import LocalAuthentication
import StaticDataTableViewController

class LoginOptionsVC: UITableViewController {
    
    lazy var hasTouchID: Bool = {
        return LAContext().canEvaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, error: nil)
    }()

    @IBOutlet var touchIDSwitch: UISwitch!
    override func viewDidLoad() {
        super.viewDidLoad()
        touchIDSwitch.enabled = hasTouchID
        touchIDSwitch.on = NSUserDefaults.standardUserDefaults().boolForKey("useTouchID")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func updatePreferences(sender: AnyObject) {
        if touchIDSwitch.on {
            LAContext().evaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, localizedReason: "Touch ID to Verify") { successful, error in
                dispatch_async(dispatch_get_main_queue()) {
                    if successful {
                        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "useTouchID")
                    } else {
                        self.touchIDSwitch.setOn(false, animated: true)
                        if (error!.code == LAError.AuthenticationFailed.rawValue) {
                            let failed = UIAlertController(title: "Failed to Login", message: "Your fingerprint did not match.", preferredStyle: .Alert)
                            let OK = UIAlertAction(title: "OK", style: .Cancel, handler:nil)
                            failed.addAction(OK)
                            self.presentViewController(failed, animated: true, completion: nil)
                        }
                    }
                }
            }
        } else {
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "useTouchID")
        }
        
    }

}
