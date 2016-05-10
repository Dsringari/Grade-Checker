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

class DSLoginView: UITableViewController {

	@IBOutlet var usernameField: UITextField!
	@IBOutlet var passwordField: UITextField!
	@IBOutlet var pinField: UITextField!
	var hasUser: Bool = false
	var loginButton: SpringButton!

	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var validatedUser: User!
	var selectedStudentIndex: Int = 0

	// This is the Indicator that will show while the app retrieves all the required data
	var activityIndicator: UIActivityIndicatorView!
	// This is the indicator for an old user
	let activityAlert = UIAlertController(title: "Logging In\n", message: nil, preferredStyle: .Alert)

	override func viewDidLoad() {
		super.viewDidLoad()

		// Setup the old user loading indicator
		let indicator = UIActivityIndicatorView()
		indicator.translatesAutoresizingMaskIntoConstraints = false
		indicator.color = UIColor.blackColor()
		activityAlert.view.addSubview(indicator)

		let views = ["pending": activityAlert.view, "indicator": indicator]
		var constraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[indicator]-(10)-|", options: NSLayoutFormatOptions.AlignAllCenterX, metrics: nil, views: views)
		constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|[indicator]|", options: NSLayoutFormatOptions.AlignAllCenterX, metrics: nil, views: views)
		activityAlert.view.addConstraints(constraints)

		indicator.userInteractionEnabled = false
		indicator.startAnimating()

		// If the user taps outside the textfields close the keyboard
		let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
		view.addGestureRecognizer(tap)

		// Set Delegate for Cell Margins
		self.tableView.delegate = self
		// Cell Margin Change
		self.tableView.cellLayoutMarginsFollowReadableWidth = false

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
        //self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor(colorLiteralRed: 44/255, green: 62/255, blue: 80/255, alpha: 1)]

		// Center Text
		usernameField.contentVerticalAlignment = .Center
		passwordField.contentVerticalAlignment = .Center
		pinField.contentVerticalAlignment = .Center
	}
    
    override func viewDidAppear(animated: Bool) {
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
                    MagicalRecord.saveWithBlockAndWait{_ in}
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

	// - MARK: SETUP

	// Change Cell Margins
	override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		// Remove seperator inset
		cell.separatorInset = UIEdgeInsetsZero

		// Prevent Cell from inheriting the table view's margin settings
		cell.preservesSuperviewLayoutMargins = false

		// Set Cell layout margins explicitly
		cell.layoutMargins = UIEdgeInsetsZero
	}

	override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 50
	}

	// Add the login button to the footer view
	override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {

		// Setup View
		let footerView = UIView(frame: CGRectMake(0, 0, tableView.frame.width, 50))
		let titleColor = UIColor(colorLiteralRed: 1, green: 1, blue: 1, alpha: 0.45) // Slightly Opaque
		// Setup Button
		loginButton = SpringButton(type: .Custom)
		loginButton.setTitle("LOG IN", forState: .Normal)
		loginButton.titleLabel!.font = UIFont.systemFontOfSize(21)
		loginButton.addTarget(self, action: #selector(login), forControlEvents: .TouchUpInside)
		loginButton.setTitleColor(titleColor, forState: .Normal)
		loginButton.setTitleColor(UIColor(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.45), forState: .Highlighted) // Make slighlty Darker
		loginButton.backgroundColor = UIColor(colorLiteralRed: 22 / 255, green: 160 / 255, blue: 132 / 255, alpha: 1)
		loginButton.frame = footerView.frame
		// Add Hidden Activity Indicator
		activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
		activityIndicator.color = titleColor
		activityIndicator.center = CGPointMake(loginButton.frame.size.width / 2, loginButton.frame.size.height / 2)
		activityIndicator.hidden = true
		loginButton.addSubview(activityIndicator)

		footerView.addSubview(loginButton)
		return footerView
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
				}
			}
		})
	}

	// Ask if the user wants to use touch id every time they log in with a new account
	func login(sender: AnyObject) {
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
				// Go to Respective Pages
				self.validatedUser = NSManagedObjectContext.MR_defaultContext().objectWithID(user.objectID) as! User
				dispatch_async(dispatch_get_main_queue(), {
					self.stopLoading()
					if (self.validatedUser.students!.allObjects.count > 1) {
						let chooseStudentAlert = UIAlertController(title: "Students", message: "Pick a Student", preferredStyle: .ActionSheet)

						let students: [Student] = user.students!.allObjects as! [Student]
						var buttons: [UIAlertAction] = []
                        let settings = NSUserDefaults.standardUserDefaults()
						for index in 0 ... (students.count - 1) {
							let button = UIAlertAction(title: students[index].name!, style: .Default, handler: { button in
								if let index = buttons.indexOf(button) {
									self.selectedStudentIndex = index
                                    
                                    if (LAContext().canEvaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, error: nil) && !self.hasUser) {
                                        let alert = UIAlertController(title: "Touch ID Login Available", message: "Would you like to use Touch ID to Login?", preferredStyle: .Alert)
                                        let yes = UIAlertAction(title: "Yes", style: .Default, handler: { alertAction in
                                            settings.setBool(true, forKey: "useTouchID")
                                            self.performSegueWithIdentifier("home", sender: nil)
                                        })
                                        let no = UIAlertAction(title: "No", style: .Cancel, handler: { alertAction in
                                            settings.setBool(false, forKey: "useTouchID")
                                            self.performSegueWithIdentifier("home", sender: nil)
                                        })
                                        alert.addAction(yes)
                                        alert.addAction(no)
                                        
                                        self.presentViewController(alert, animated: true, completion: nil)
                                    } else {
                                        self.performSegueWithIdentifier("home", sender: nil)
                                    }
                                    
                                    
                                    settings.setObject(students[self.selectedStudentIndex].name!, forKey: "selectedStudent")

								}
							})
							buttons.append(button)
						}

						for b in buttons {
							chooseStudentAlert.addAction(b)
						}
                        
                        if (self.hasUser) {
                            let student = (self.validatedUser.students!.allObjects as! [Student]).filter{$0.name! == settings.stringForKey("selectedStudent")}[0]
                            self.selectedStudentIndex = (self.validatedUser.students!.allObjects as! [Student]).indexOf(student)!
                            self.performSegueWithIdentifier("home", sender: nil)
                        } else {
                            self.presentViewController(chooseStudentAlert, animated: true, completion: nil)
                        }
					} else {
                        let settings = NSUserDefaults.standardUserDefaults()
                        if (LAContext().canEvaluatePolicy(.DeviceOwnerAuthenticationWithBiometrics, error: nil) && !self.hasUser) {
                            let alert = UIAlertController(title: "Touch ID Login Available", message: "Would you like to use Touch ID to Login?", preferredStyle: .Alert)
                            let yes = UIAlertAction(title: "Yes", style: .Default, handler: { alertAction in
                                settings.setBool(true, forKey: "useTouchID")
                                self.performSegueWithIdentifier("home", sender: nil)
                            })
                            let no = UIAlertAction(title: "No", style: .Cancel, handler: { alertAction in
                                settings.setBool(false, forKey: "useTouchID")
                                self.performSegueWithIdentifier("home", sender: nil)
                            })
                            alert.addAction(yes)
                            alert.addAction(no)
                            
                            self.presentViewController(alert, animated: true, completion: nil)
                        } else {
                            self.performSegueWithIdentifier("home", sender: nil)
                        }
                        
                        settings.setObject((self.validatedUser.students!.allObjects[self.selectedStudentIndex] as! Student).name!, forKey: "selectedStudent")
					}
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
		if segue.identifier == "home" {
            NSManagedObjectContext.MR_defaultContext().MR_saveToPersistentStoreAndWait()
            let tBC = segue.destinationViewController as! UITabBarController
			tBC.selectedIndex = 0
			let nVC = tBC.viewControllers![0] as! UINavigationController
			let gVC = nVC.viewControllers[0] as! GradesVC
			gVC.student = validatedUser.students!.allObjects[selectedStudentIndex] as! Student
		}
	}
}
