//
//  LockVC.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 5/20/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit
import LocalAuthentication

protocol LockDelegate {
    func logout()
}

class LockVC: UIViewController {

	@IBOutlet var continueButton: UIButton!
	@IBOutlet var activityIndicator: UIActivityIndicatorView!

	var user: User!
    var lockDelegate: LockDelegate!

	override func viewDidLoad() {
		super.viewDidLoad()

		if let user = User.mr_findFirst(), let student = Student.mr_findFirst(byAttribute: "name", withValue: UserDefaults.standard.string(forKey: "selectedStudent")!) {
			self.user = user
			self.continueButton.setTitle("Continue as " + student.name!, for: UIControlState())
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func login() {
		// Try to Login
		self.activityIndicator.startAnimating()
		_ = LoginService(loginUserWithID: user.objectID, completionHandler: { successful, error in
			DispatchQueue.main.async(execute: {

				self.activityIndicator.stopAnimating()

				if (successful) {
                    self.dismiss(animated: true, completion: nil)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "loadStudent"), object: nil)
				} else {
                    var err = error
                    if (error!.code == NSURLErrorTimedOut) {
                        err = badConnectionError
                    }
                    let alert = UIAlertController(title: err!.localizedDescription, message: err!.localizedRecoverySuggestion, preferredStyle: .alert)
                    if err == badLoginError {
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { _ in
                            self.logout()
                        }))
                    } else {
                        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
                    }
                    self.present(alert, animated: true, completion: nil)

				}

			})
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

                    DispatchQueue.main.async(execute: {
                        self.continueButton.isEnabled = true
                        if (success) {
                            self.login()
                        } else if let error = error as NSError? {
                            if (error.code == LAError.Code.authenticationFailed.rawValue) {
                                let failed = UIAlertController(title: "Failed to Login", message: "Your fingerprint did not match. Signing out.", preferredStyle: .alert)
                                let Ok = UIAlertAction(title: "Ok", style: .cancel, handler: { _ in
                                    self.logout()
                                })
                                failed.addAction(Ok)
                                DispatchQueue.main.async(execute: {
                                    self.present(failed, animated: true, completion: nil)
                                })
                            } else if error.code == LAError.Code.userFallback.rawValue {
                                self.logout()
                            }
                        }
                    })
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
                    self.logout()
                    self.continueButton.isEnabled = true
                }))
                self.present(alert, animated: true, completion: nil)
            }
        } else {
            login()
        }

    }

    func logout() {
        self.dismiss(animated: false) {
            self.lockDelegate.logout()
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
