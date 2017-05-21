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

	@IBOutlet var continueButton: UIButton!
	@IBOutlet var activityIndicator: UIActivityIndicatorView!
	var containerVC: ContainerVC!

	var user: User!

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.

		containerVC = navigationController!.parent as! ContainerVC

		NotificationCenter.default.addObserver(self, selector: #selector(didDismissTabBar), name: NSNotification.Name(rawValue: "tabBarDismissed"), object: nil)
		refresh()
	}

	func didDismissTabBar() {
		NotificationCenter.default.removeObserver(self)
		let settings = UserDefaults.standard
		if (settings.string(forKey: "selectedStudent") == nil) {
			backToLogin()
		}

	}

	func refresh() {
		let settings = UserDefaults.standard
		if let name = settings.string(forKey: "selectedStudent") {
			if let student = Student.mr_findFirst(byAttribute: "name", withValue: name) {
				user = student.user
				continueButton.setTitle("Continue as " + student.name!, for: UIControlState())
			} else {
				backToLogin()
			}

		} else {
			backToLogin()
		}
	}

	func login() {
		// Try to Login
		self.activityIndicator.startAnimating()
		let _ = LoginService(loginUserWithID: user.objectID, completionHandler: { successful, error in
			DispatchQueue.main.async {
				self.activityIndicator.stopAnimating()
				if (successful) {

					self.performSegue(withIdentifier: "returnHome", sender: self)

				} else {
					// If we failed

					var err = error
					if (error!.code == NSURLErrorTimedOut) {
						err = badConnectionError
					}
					let alert = UIAlertController(title: err!.localizedDescription, message: err!.localizedRecoverySuggestion, preferredStyle: .alert)
					if err == badLoginError {
						alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { _ in
							self.backToLogin()
							}))
					} else {
						alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
					}
					self.present(alert, animated: true, completion: nil)

				}
			}
		})
	}

	@IBAction func continuePressed(_ sender: AnyObject) {
		let settings = UserDefaults.standard

		if settings.bool(forKey: "useTouchID") {
			continueButton.isEnabled = false
			var error: NSError?
			if LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
				let context: LAContext = LAContext()
				let localizedReasonString = "Login with Touch ID"
				context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: localizedReasonString, reply: { success, error in

					DispatchQueue.main.async {
                        self.continueButton.isEnabled = true
                        if (success) {
							self.login()
						} else if let error = error as NSError? {
							if (error.code == LAError.Code.authenticationFailed.rawValue) {
								let failed = UIAlertController(title: "Failed to Login", message: "Your fingerprint did not match. Signing out.", preferredStyle: .alert)
								let Ok = UIAlertAction(title: "Ok", style: .cancel, handler: { _ in
									self.backToLogin()
								})
								failed.addAction(Ok)
								
                                self.present(failed, animated: true, completion: nil)
								

								return
                            } else if error.code == LAError.Code.userFallback.rawValue {
                                self.backToLogin()
                            }
						}
					}
				})
			} else {
				var title: String!
				var message: String!
				switch error!.code {
				case LAError.Code.touchIDNotEnrolled.rawValue:
					title = "Touch ID Not Enabled"
					message = "Setup Touch ID in your settings"
				case LAError.Code.passcodeNotSet.rawValue:
					title = "Passcode Not Set"
					message = "Setup a Passcode to use Touch ID"
				default:
					title = "Touch ID Not Availabe"
					message = "We couldn't access Touch ID"
				}
				let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { _ in
					self.backToLogin()
					self.continueButton.isEnabled = true
					}))
				self.present(alert, animated: true, completion: nil)
			}
		} else {
			login()
		}

	}

	func backToLogin() {
		DispatchQueue.main.async(execute: {
			User.mr_deleteAll(matching: NSPredicate(value: true))
			NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait()
			self.containerVC.toLogin()
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
