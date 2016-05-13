//
//  DSLoginView.swift
//
//
//  Created by Dhruv Sringari on 3/10/16.
//
//

import UIKit
import CoreData
import MagicalRecord
import Spring
import LocalAuthentication

class DSLoginView: UIViewController {

	@IBOutlet var usernameField: UITextField!
	@IBOutlet var passwordField: UITextField!
	@IBOutlet var pinField: UITextField!
	@IBOutlet var loginButton: SpringButton!
	@IBOutlet var forgotPasswordButton: UIButton!

	@IBOutlet var keyboardConstraint: NSLayoutConstraint!
	var kbHeight: CGFloat?
	var setConstant: CGFloat?

	var hasUser: Bool = false

	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var validatedUser: User!
	var selectedStudentIndex: Int = 0

	// This is the Indicator that will show while the app retrieves all the required data
	var activityIndicator: UIActivityIndicatorView!
	// This is the indicator for an old user
	let activityAlert = UIAlertController(title: "Logging In\n", message: nil, preferredStyle: .Alert)

	override func viewDidLoad() {
		super.viewDidLoad()

		// If the user taps outside the textfields close the keyboard
		let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
		view.addGestureRecognizer(tap)

		/* Change the placeholder text color
		 let lighterBlueColor = UIColor(colorLiteralRed: 86 / 255, green: 100 / 255, blue: 116 / 255, alpha: 1.0)
		 let attributedUsernamePlaceholder = NSAttributedString(string: "Username", attributes: [NSForegroundColorAttributeName: lighterBlueColor])
		 let attributedPasswordPlaceholder = NSAttributedString(string: "Password", attributes: [NSForegroundColorAttributeName: lighterBlueColor])
		 let attributedPinPlaceholder = NSAttributedString(string: "Pin", attributes: [NSForegroundColorAttributeName: lighterBlueColor])
		 usernameField.attributedPlaceholder = attributedUsernamePlaceholder
		 passwordField.attributedPlaceholder = attributedPasswordPlaceholder
		 pinField.attributedPlaceholder = attributedPinPlaceholder
		 */

		// Change Title Color
		// self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor(colorLiteralRed: 44/255, green: 62/255, blue: 80/255, alpha: 1)]

		// Center Text
		usernameField.contentVerticalAlignment = .Center
		passwordField.contentVerticalAlignment = .Center
		pinField.contentVerticalAlignment = .Center
	}

	override func viewDidAppear(animated: Bool) {
		// Setup Button Activity Indicator
		let indicator = UIActivityIndicatorView()
		indicator.translatesAutoresizingMaskIntoConstraints = false
		indicator.color = UIColor.blackColor()
		activityAlert.view.addSubview(indicator)

		let views = ["pending": activityAlert.view, "indicator": indicator]
		var constraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[indicator]-(10)-|", options: NSLayoutFormatOptions.AlignAllCenterX, metrics: nil, views: views)
		constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|[indicator]|", options: NSLayoutFormatOptions.AlignAllCenterX, metrics: nil, views: views)
		activityAlert.view.addConstraints(constraints)

		indicator.userInteractionEnabled = false
		activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
		activityIndicator.center = CGPointMake(loginButton.frame.size.width / 2, loginButton.frame.size.height / 2)
		activityIndicator.hidden = true
		loginButton.addSubview(activityIndicator)

		// Check If we have a user already

		if let user = User.MR_findFirst() {
			hasUser = true
			self.startLoading()
			let settings = NSUserDefaults.standardUserDefaults()
			let useTouchID = settings.boolForKey("useTouchID")
			if (useTouchID) {
				var error: NSError?
				if LAContext().canEvaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, error: &error) {
					loginWithTouchID(user)
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
					User.MR_deleteAllMatchingPredicate(NSPredicate(value: true))
					MagicalRecord.saveWithBlockAndWait { _ in }
					self.stopLoading()
					let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
					alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
					self.presentViewController(alert, animated: true, completion: nil)
				}
			} else {
				loginUser(user)
			}
		} else {
			hasUser = false
		}

	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		registerForKeyboardNotifications()
	}

	override func viewWillDisappear(animated: Bool) {
		deregisterFromKeyboardNotifications()
	}

	func registerForKeyboardNotifications()
	{
		// Adding notifies on keyboard appearing
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWasShown), name: UIKeyboardWillShowNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillBeHidden), name: UIKeyboardWillHideNotification, object: nil)
	}

	func deregisterFromKeyboardNotifications()
	{
		// Removing notifies on keyboard appearing
		NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
	}

	func keyboardWasShown(notification: NSNotification) {
		if let kbFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] {
			let keyboardAnimationDuration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! NSTimeInterval
            let keyboardFrame = kbFrame.CGRectValue
            kbHeight = keyboardFrame.height

			setConstant = keyboardConstraint.constant
			keyboardConstraint.constant = kbHeight! + 8

			UIView.animateWithDuration(keyboardAnimationDuration, animations: {
				self.view.layoutIfNeeded()
			})
		}

	}

	func keyboardWillBeHidden(notification: NSNotification)
	{
		if let constant = setConstant {
			let animationDuration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! NSTimeInterval
			keyboardConstraint.constant = constant
			UIView.animateWithDuration(animationDuration, animations: {
				self.view.layoutIfNeeded()
			})

		}

	}

	// - MARK: Functions

	func loginWithTouchID(user: User) {
		let context: LAContext = LAContext()
		let localizedReasonString = "Login with Touch ID"
		context.evaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, localizedReason: localizedReasonString, reply: { success, error in
			if (success) {
				self.loginUser(user)
			} else {
				User.MR_deleteAllMatchingPredicate(NSPredicate(value: true))

				if (error!.code == LAError.AuthenticationFailed.rawValue) {
					let failed = UIAlertController(title: "Failed to Login", message: "Your fingerprint did not match. Signing out.", preferredStyle: .Alert)
					let Ok = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
					failed.addAction(Ok)
					dispatch_async(dispatch_get_main_queue(), {
						self.presentViewController(failed, animated: true, completion: nil)
						self.stopLoading()
					})

					return
				}

				dispatch_async(dispatch_get_main_queue(), {
					self.stopLoading()
				})
			}
		})
	}

	// Ask if the user wants to use touch id every time they log in with a new account
	@IBAction func login(sender: AnyObject) {

		// Reset Activity Indicator Pos incase button moved
		activityIndicator.center = CGPointMake(loginButton.frame.size.width / 2, loginButton.frame.size.height / 2)

		let user: User = User.MR_createEntity()!
		user.username = usernameField.text!
		user.password = passwordField.text!
		user.pin = pinField.text!
		startLoading()
		loginUser(user)
	}

	func loginUser(user: User) {
		// Try to Login
		let _ = LoginService(loginUserWithID: user.objectID, completionHandler: { successful, error in

			if (successful) {
				dispatch_async(dispatch_get_main_queue(), {
					self.stopLoading()
                    self.performSegueWithIdentifier("selectStudent", sender: self)
				})
			} else {
				// If we failed
				dispatch_async(dispatch_get_main_queue(), {
					self.stopLoading()
					self.shakeLoginButton({
						user.MR_deleteEntity()
						var err = error
						if (error!.code == NSURLErrorTimedOut) {
							err = badConnectionError
						}
						let alert = UIAlertController(title: err!.localizedDescription, message: err!.localizedFailureReason, preferredStyle: .Alert)
						alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
						self.presentViewController(alert, animated: true, completion: {
							// delete the invalid user
							User.MR_deleteAllMatchingPredicate(NSPredicate(value: true))
							NSManagedObjectContext.MR_defaultContext().MR_saveToPersistentStoreAndWait()
						})
					})
				})
			}
		})
	}

	func startLoading() {
		loginButton.titleLabel!.layer.opacity = 0
		loginButton.userInteractionEnabled = false
		activityIndicator.hidden = false
		activityIndicator.startAnimating()
	}

	func stopLoading() {

		self.activityIndicator.stopAnimating()
		self.activityIndicator.hidden = true
		self.loginButton.titleLabel!.layer.opacity = 1
		loginButton.userInteractionEnabled = true
	}

	func shakeLoginButton(completion: () -> Void) {

		loginButton.animation = "shake"
		loginButton.duration = 1
		// loginButton.curve = "spring"
		loginButton.animateNext(completion)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	// In a storyboard-based application, you will often want to do a little preparation before navigation
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		
	}
}
