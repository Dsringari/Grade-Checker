//
//  DSLoginView.swift
//
//
//  Created by Dhruv Sringari on 3/10/16.
//
//

import UIKit
import CoreData
import Spring

class DSLoginView: UITableViewController {

	@IBOutlet var usernameField: UITextField!
	@IBOutlet var passwordField: UITextField!
	@IBOutlet var pinField: UITextField!
	var loginButton: SpringButton!

	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var validatedUser: User!
	var selectedStudentIndex: Int = 0

	// This is the Indicator that will show while the app retrieves all the required data
	var activityIndicator: UIActivityIndicatorView!

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		// TODO: Check for a user in the database and push to homescreen while updating it

		// if let user = self.appDelegate.managedObjectContext.getObjectFromStore("User", predicateString: nil, args: []) {
		// loginUser(user as! User)
		// }

		appDelegate.deleteAllUsers(self.appDelegate.managedObjectContext)
		// If the user taps outside the textfields close the keyboard
		let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
		view.addGestureRecognizer(tap)

		// Set Delegate for Cell Margins
		self.tableView.delegate = self
		// Cell Margin Change
		self.tableView.cellLayoutMarginsFollowReadableWidth = false

		// Change the placeholder text color
		let lighterBlueColor = UIColor(colorLiteralRed: 86 / 255, green: 100 / 255, blue: 116 / 255, alpha: 1.0)
		let attributedUsernamePlaceholder = NSAttributedString(string: "Username", attributes: [NSForegroundColorAttributeName: lighterBlueColor])
		let attributedPasswordPlaceholder = NSAttributedString(string: "Password", attributes: [NSForegroundColorAttributeName: lighterBlueColor])
		let attributedPinPlaceholder = NSAttributedString(string: "Pin", attributes: [NSForegroundColorAttributeName: lighterBlueColor])
		usernameField.attributedPlaceholder = attributedUsernamePlaceholder
		passwordField.attributedPlaceholder = attributedPasswordPlaceholder
		pinField.attributedPlaceholder = attributedPinPlaceholder

		// Center Text
		usernameField.contentVerticalAlignment = .Center
		passwordField.contentVerticalAlignment = .Center
		pinField.contentVerticalAlignment = .Center
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		// registerKeyboardNotifications()
	}

	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		// unregisterKeyboardNotifications()
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
		activityIndicator.center = CGPointMake(loginButton.frame.size.width / 2, loginButton.frame.size.height / 2)
		activityIndicator.hidden = true
		loginButton.addSubview(activityIndicator)

		footerView.addSubview(loginButton)
		return footerView
	}

	// - MARK: Functions

	func login(sender: AnyObject) {
		let user: User = NSEntityDescription.insertNewObjectForEntityForName("User", inManagedObjectContext: self.appDelegate.managedObjectContext) as! User
		user.username = usernameField.text!
		user.password = passwordField.text!
		user.pin = pinField.text!

		loginUser(user)
	}

	func loginUser(user: User) {
		// Start the Loading Animation
		startLoading()
		// Try to Login
		let _ = LoginService(userToBeLoggedIn: user, completionHandler: { successful, error, legitamateUser in

			if (successful) {
				// Go to Respective Pages
				let moc = self.appDelegate.managedObjectContext
				self.validatedUser = moc.objectWithID(legitamateUser!.objectID) as! User
				dispatch_async(dispatch_get_main_queue(), {
					self.stopLoading()
					if (self.validatedUser.students!.allObjects.count > 1) {
						let chooseStudentAlert = UIAlertController(title: "Students", message: "Pick a Student", preferredStyle: .ActionSheet)

						let students: [Student] = user.students!.allObjects as! [Student]
						var buttons: [UIAlertAction] = []
						for index in 0 ... (students.count - 1) {
							let button = UIAlertAction(title: students[index].name!, style: .Default, handler: { button in
								if let index = buttons.indexOf(button) {
									self.selectedStudentIndex = index
									self.performSegueWithIdentifier("home", sender: nil)
								}
							})
							buttons.append(button)
						}

						for b in buttons {
							chooseStudentAlert.addAction(b)
						}

						self.presentViewController(chooseStudentAlert, animated: true, completion: nil)
					} else {
						self.performSegueWithIdentifier("home", sender: nil)
					}
				})
			} else {
				// If we failed
				dispatch_async(dispatch_get_main_queue(), {
					self.stopLoading()
                    self.shakeLoginButton( {
                        let moc = self.appDelegate.managedObjectContext
                        moc.deleteObject(moc.objectWithID(user.objectID))
                        
                        var err = error
                        if (error!.code == NSURLErrorTimedOut) {
                            err = badConnectionError
                        }
                        let alert = UIAlertController(title: err!.localizedDescription, message: err!.localizedFailureReason, preferredStyle: .Alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
                        self.presentViewController(alert, animated: true, completion: {
                            let moc = self.appDelegate.managedObjectContext
                            self.appDelegate.deleteAllUsers(moc)
                            moc.saveContext()
                        })
                    })
					
				})
			}
		})
	}

	func startLoading() {
		loginButton.titleLabel!.layer.opacity = 0
		activityIndicator.hidden = false
		activityIndicator.startAnimating()
	}

	func stopLoading() {
		self.activityIndicator.stopAnimating()
		self.activityIndicator.hidden = true
		self.loginButton.titleLabel!.layer.opacity = 1
	}

	func shakeLoginButton(completion: () -> Void) {
        loginButton.animation = "shake"
        loginButton.duration = 1
        //loginButton.curve = "spring"
        loginButton.animateNext(completion)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	// In a storyboard-based application, you will often want to do a little preparation before navigation
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "home" {
			let tBC = segue.destinationViewController as! UITabBarController
            tBC.selectedIndex = 0
            let nVC = tBC.viewControllers![0] as! UINavigationController
            let gVC = nVC.viewControllers[0] as! GradesVC
            gVC.student = validatedUser.students!.allObjects[selectedStudentIndex] as! Student
		}
	}
}
