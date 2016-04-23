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

class DSLoginView: UITableViewController, SelectStudentVCDelegate {
	@IBOutlet var loginButton: UIButton!
	@IBOutlet var usernameField: UITextField!
	@IBOutlet var passwordField: UITextField!
	@IBOutlet var pinField: UITextField!
   
    

	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var validatedUser: User!
    var selectedStudentIndex: Int = 0
    
    // This is the Indicator that will show while the app retrieves all the required data
    let activityAlert = UIAlertController(title: "Logging In\n", message: nil, preferredStyle: .Alert)

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		// TODO: Check for a user in the database and push to homescreen while updating it
        
       // if let user = self.appDelegate.managedObjectContext.getObjectFromStore("User", predicateString: nil, args: []) {
        //    loginUser(user as! User)
        //}
        
		appDelegate.deleteAllUsers(self.appDelegate.managedObjectContext)
        // If the user taps outside the textfields close the keyboard
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        
        // add the spinning indicator to the loading alert
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
        
        // Change the layout margins for the table view
        self.tableView.layoutMargins = UIEdgeInsetsZero
        self.tableView.delegate = self
        
        // Change the placeholder text color
        let lighterBlueColor = UIColor(colorLiteralRed: 86/255, green: 100/255, blue: 116/255, alpha: 1.0)
        let attributedUsernamePlaceholder = NSAttributedString(string: "Username", attributes: [NSForegroundColorAttributeName: lighterBlueColor])
        let attributedPasswordPlaceholder = NSAttributedString(string: "Password", attributes: [NSForegroundColorAttributeName: lighterBlueColor])
        let attributedPinPlaceholder = NSAttributedString(string: "Pin", attributes: [NSForegroundColorAttributeName: lighterBlueColor])
        usernameField.attributedPlaceholder = attributedUsernamePlaceholder
        passwordField.attributedPlaceholder = attributedPasswordPlaceholder
        pinField.attributedPlaceholder = attributedPinPlaceholder

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //registerKeyboardNotifications()
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
    
    
    func loginUser(user: User) {
        // Start the Loading Animation
        self.presentViewController(activityAlert, animated: true, completion: nil)
        // Try to Login
        let _ = LoginService(userToBeLoggedIn: user, completionHandler: { successful, error, legitamateUser in
            
            if (successful) {
                // Go to Respective Pages
                let moc = self.appDelegate.managedObjectContext
                self.validatedUser = moc.objectWithID(legitamateUser!.objectID) as! User
                dispatch_async(dispatch_get_main_queue(), {
                    self.activityAlert.dismissViewControllerAnimated(false, completion:  {
                        if (self.validatedUser.students!.allObjects.count > 1) {
                            self.performSegueWithIdentifier("selectStudent", sender: nil)
                        } else {
                            self.performSegueWithIdentifier("pushToHomeScreen", sender: nil)
                        }
                    })
                })
                
            } else {
                // If we failed
                dispatch_async(dispatch_get_main_queue(), {
                    let moc = self.appDelegate.managedObjectContext
                    moc.deleteObject(moc.objectWithID(user.objectID))
                    self.activityAlert.dismissViewControllerAnimated(true) {
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
                    }
                })
            }
        })
    }
    
    @IBAction func login(sender: AnyObject) {
        let user: User = NSEntityDescription.insertNewObjectForEntityForName("User", inManagedObjectContext: self.appDelegate.managedObjectContext) as! User
        user.username = usernameField.text!
        user.password = passwordField.text!
        user.pin = pinField.text!
        
        loginUser(user)

    }
    
    
    // - MARK: Functions

	@IBAction func herebutton(sender: AnyObject) {
		// TODO: Add new account functionality
		print("nice u dont have an account")
	}

	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	
	 // MARK: - Navigation
    
    // Set the selected Student
    func selectStudent(index: Int) {
        self.dismissViewControllerAnimated(true, completion: {
            self.selectedStudentIndex = index
            self.performSegueWithIdentifier("pushToHomeScreen", sender: nil)
        })
    }

	 // In a storyboard-based application, you will often want to do a little preparation before navigation
	 override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "pushToHomeScreen" {
            let nVC = segue.destinationViewController as! UINavigationController
            let dVC = nVC.viewControllers.first as! DSGradesView
            dVC.student = (validatedUser.students!.allObjects[selectedStudentIndex] as! Student)
        } else if segue.identifier == "selectStudent" {
            let dVC = segue.destinationViewController as! SelectStudentVC
            dVC.students = (validatedUser.students!.allObjects as! [Student])
            dVC.delegate = self
        }
	 }
	 
}
