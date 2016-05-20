//
//  LockVC.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 5/20/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit
import LocalAuthentication

class LockVC: UIViewController {

	@IBOutlet var continueButton: UIButton!
	@IBOutlet var activityIndicator: UIActivityIndicatorView!

	var user: User!
    var delegate: GradesVCDelegate!
    

	override func viewDidLoad() {
		super.viewDidLoad()

		if let user = User.MR_findFirst(), let student = Student.MR_findFirstByAttribute("name", withValue: NSUserDefaults.standardUserDefaults().stringForKey("selectedStudent")!) {
			self.user = user
			self.continueButton.setTitle("Continue as " + student.name!, forState: .Normal)
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func login() {
		// Try to Login
		self.activityIndicator.startAnimating()
		let _ = LoginService(loginUserWithID: user.objectID, completionHandler: { successful, error in
			dispatch_async(dispatch_get_main_queue(), {
                
				self.activityIndicator.stopAnimating()
                
				if (successful) {
                    self.dismissViewControllerAnimated(true, completion: nil)
                    self.delegate.reloadData({})
				} else {
                    var err = error
                    if (error!.code == NSURLErrorTimedOut) {
                        err = badConnectionError
                    }
                    let alert = UIAlertController(title: err!.localizedDescription, message: err!.localizedFailureReason, preferredStyle: .Alert)
                    if err == badLoginError {
                        alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: { _ in
                            self.logout()
                        }))
                    } else {
                        alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
                    }
                    self.presentViewController(alert, animated: true, completion: nil)

				}
                
			})
		})
	}
    
    @IBAction func continuePressed(sender: AnyObject) {
        let settings = NSUserDefaults.standardUserDefaults()
        
        if settings.boolForKey("useTouchID") {
            continueButton.enabled = false
            var error: NSError?
            if LAContext().canEvaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, error: &error) {
                let context: LAContext = LAContext()
                let localizedReasonString = "Login with Touch ID"
                context.evaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, localizedReason: localizedReasonString, reply: { success, error in
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        if (success) {
                            
                            self.login()
                            self.continueButton.enabled = true
                        } else {
                            if (error!.code == LAError.AuthenticationFailed.rawValue) {
                                let failed = UIAlertController(title: "Failed to Login", message: "Your fingerprint did not match. Signing out.", preferredStyle: .Alert)
                                let Ok = UIAlertAction(title: "Ok", style: .Cancel, handler: { _ in
                                    self.dismissViewControllerAnimated(true, completion: {
                                        
                                    })
                                    self.continueButton.enabled = true
                                })
                                failed.addAction(Ok)
                                dispatch_async(dispatch_get_main_queue(), {
                                    self.presentViewController(failed, animated: true, completion: nil)
                                })
                                
                                return
                            }
                            
                            self.logout()
                        }
                    })
                })
            } else {
                var title: String!
                var message: String!
                switch error!.code {
                case LAError.TouchIDNotEnrolled.rawValue:
                    title = "Touch ID Not Enabled"
                    message = "Setup Touch ID in your settings"
                case LAError.PasscodeNotSet.rawValue:
                    title = "Passcode Not Set"
                    message = "Setup a Passcode to use Touch ID"
                default:
                    title = "Touch ID Not Availabe"
                    message = "We couldn't access Touch ID"
                }
                let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: { _ in
                    self.logout()
                    self.continueButton.enabled = true
                }))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        } else {
            login()
        }
        
    }
    
    func logout() {
        dismissViewControllerAnimated(true, completion: {
            self.delegate.logout()
        })
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
