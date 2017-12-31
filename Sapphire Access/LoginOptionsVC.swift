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
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }()

    @IBOutlet var touchIDSwitch: UISwitch!
    override func viewDidLoad() {
        super.viewDidLoad()
        touchIDSwitch.isEnabled = hasTouchID
        touchIDSwitch.isOn = UserDefaults.standard.bool(forKey: "useTouchID")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func updatePreferences(_ sender: AnyObject) {
        if touchIDSwitch.isOn {
            let context = LAContext()
            context.localizedFallbackTitle = ""
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Touch ID to Verify") { successful, error in
                DispatchQueue.main.async {
                    if successful {
                        UserDefaults.standard.set(true, forKey: "useTouchID")
                    } else if let error = error as NSError? {
                        self.touchIDSwitch.setOn(false, animated: true)
                        if (error.code == LAError.Code.authenticationFailed.rawValue) {
                            let failed = UIAlertController(title: "Failed to Verify", message: "Your fingerprint did not match.", preferredStyle: .alert)
                            let OK = UIAlertAction(title: "OK", style: .cancel, handler:nil)
                            failed.addAction(OK)
                            self.present(failed, animated: true, completion: nil)
                        }
                    }
                }
            }
        } else {
            UserDefaults.standard.set(false, forKey: "useTouchID")
        }

    }

}
