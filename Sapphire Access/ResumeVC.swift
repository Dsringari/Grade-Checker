//
//  ResumeVC.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 5/13/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit
import LocalAuthentication
import MagicalRecord

class ResumeVC: UIViewController {

	var user: User!
	@IBOutlet var continueButton: UIButton!
	@IBOutlet var activityIndicator: UIActivityIndicatorView!

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.

		let settings = NSUserDefaults.standardUserDefaults()

		if let name = settings.stringForKey("selectedStudent") {
			if let student = Student.MR_findFirstByAttribute("name", withValue: name) {
				user = student.user
				continueButton.setTitle("Continue as " + student.name!, forState: .Normal)

				if settings.boolForKey("useTouchID") {
					continueButton.enabled = false
					var error: NSError?
					if LAContext().canEvaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, error: &error) {
						let context: LAContext = LAContext()
						let localizedReasonString = "Login with Touch ID"
						context.evaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, localizedReason: localizedReasonString, reply: { success, error in
							if (success) {
								self.login()
							} else {
								if (error!.code == LAError.AuthenticationFailed.rawValue) {
									let failed = UIAlertController(title: "Failed to Login", message: "Your fingerprint did not match. Signing out.", preferredStyle: .Alert)
									let Ok = UIAlertAction(title: "Ok", style: .Cancel, handler: { _ in
										self.backToLogin()
									})
									failed.addAction(Ok)
									dispatch_async(dispatch_get_main_queue(), {
										self.presentViewController(failed, animated: true, completion: nil)
									})

									return
								}

								self.backToLogin()
							}
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
							self.backToLogin()
							}))
						self.presentViewController(alert, animated: true, completion: nil)
					}
				}
			} else {
				backToLogin()
			}
		} else {
			backToLogin()
		}
	}

	func login() {
		// Try to Login
		activityIndicator.startAnimating()
		let _ = LoginService(loginUserWithID: user.objectID, completionHandler: { successful, error in
			self.activityIndicator.stopAnimating()
			if (successful) {
				dispatch_async(dispatch_get_main_queue(), {
					self.performSegueWithIdentifier("returnHome", sender: self)
				})
			} else {
				// If we failed
				dispatch_async(dispatch_get_main_queue(), {
					var err = error
					if (error!.code == NSURLErrorTimedOut) {
						err = badConnectionError
					}
					let alert = UIAlertController(title: err!.localizedDescription, message: err!.localizedFailureReason, preferredStyle: .Alert)
					alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: { _ in
						self.backToLogin()
						}))
					self.presentViewController(alert, animated: true, completion: nil)
				})
			}
		})
	}

	@IBAction func continuePressed(sender: AnyObject) {
		login()
	}

	func backToLogin() {
		User.MR_deleteAllMatchingPredicate(NSPredicate(value: true))
		NSManagedObjectContext.MR_defaultContext().MR_saveToPersistentStoreAndWait()
        self.view.window?.rootViewController?.dismissViewControllerAnimated(true, completion: {
            let loginViewController = self.storyboard!.instantiateViewControllerWithIdentifier("loginVC")
            UIApplication.sharedApplication().keyWindow?.rootViewController = loginViewController
        })
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
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
