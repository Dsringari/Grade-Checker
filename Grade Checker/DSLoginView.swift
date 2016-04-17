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

class DSLoginView: UIViewController {
	@IBOutlet var loginButton: UIButton!
	@IBOutlet var usernameField: UITextField!
	@IBOutlet var passwordField: UITextField!
	@IBOutlet var pinField: UITextField!
    @IBOutlet var scrollView: UIScrollView!

	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    // This is the Indicator that will show while the app retrieves all the required data
    let activityAlert = UIAlertController(title: "Logging In\n", message: nil, preferredStyle: .Alert)

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		// TODO: Check for a user in the database and push to homescreen while updating it
		appDelegate.deleteAllUsers(self.appDelegate.managedObjectContext)
        // If the user taps outside the textfields close the keyboard
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        // Change the placeholder text color
        let darkGrayColor = UIColor(red: 127.0/255, green: 140.0/255, blue: 141.0/255, alpha: 1.0)
        let usernamePlaceholder = NSAttributedString.init(string: "Username", attributes: [NSForegroundColorAttributeName: darkGrayColor])
        let passwordPlaceholder = NSAttributedString.init(string: "Password", attributes: [NSForegroundColorAttributeName: darkGrayColor])
        let pinPlaceholder = NSAttributedString.init(string: "Pin", attributes: [NSForegroundColorAttributeName: darkGrayColor])
        usernameField.attributedPlaceholder = usernamePlaceholder
        passwordField.attributedPlaceholder = passwordPlaceholder
        pinField.attributedPlaceholder = pinPlaceholder
        
    }
    
    // TODO: Fix scrolling to textview functions
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //registerKeyboardNotifications()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
       // unregisterKeyboardNotifications()
    }
    
    // - MARK: SETUP
    
    // Make sure we can always see all the text fields
    func registerKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardDidShow), name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillHide), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func unregisterKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func keyboardDidShow(notification: NSNotification) {
        let info = notification.userInfo!
        let keyPadFrame: CGRect = UIApplication.sharedApplication().keyWindow!.convertRect(info[UIKeyboardFrameEndUserInfoKey]!.CGRectValue(), fromView: self.view)
        let kbSize = keyPadFrame.size
        let activeRect = self.view.convertRect(pinField.frame, toView: pinField.superview)
        var rect = self.view.bounds
        rect.size.height -= kbSize.height
        
        var origin = activeRect.origin
        origin.y = scrollView.contentOffset.y
        if (!CGRectContainsPoint(rect, origin)) {
            let scrollPoint = CGPointMake(0.0, CGRectGetMaxX(activeRect)-rect.size.height)
            scrollView.setContentOffset(scrollPoint, animated: true)
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = UIEdgeInsetsZero
        scrollView.scrollIndicatorInsets = UIEdgeInsetsZero
    }
    
    // - MARK: Functions

	@IBAction func herebutton(sender: AnyObject) {
		// TODO: Add new account functionality
		print("nice u dont have an account")
	}

	@IBAction func login(sender: AnyObject) {
        scrollView.endEditing(true)
        

		// create a new user in the database
		// FIXME: DO NOT INSERT THE USER HERE WAIT TILL WE ARE VALIDATED
		let user: User = NSEntityDescription.insertNewObjectForEntityForName("User", inManagedObjectContext: self.appDelegate.managedObjectContext) as! User
		user.username = usernameField.text!
		user.password = passwordField.text!
		user.pin = pinField.text!

		appDelegate.saveContext()

		
		
        // add the spinning indicator
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

		self.presentViewController(activityAlert, animated: true, completion: nil)

		// This is the LoginService Completion Handler
		let _ = LoginService(userToBeLoggedIn: user, completionHandler: { successful, error, legitamateUser in

			if (successful) {
                
                if (legitamateUser!.students!.allObjects.count > 1) {
                    let chooseStudentAlert = UIAlertController(title: "Students", message: "Pick a Student", preferredStyle: .ActionSheet)
                    
                    let students: [Student] = user.students!.allObjects as! [Student]
                    var buttons: [UIAlertAction] = []
                    for index in 0 ... (students.count - 1) {
                        let button = UIAlertAction(title: students[index].name!, style: .Default, handler: { button in
                            if let index = buttons.indexOf(button) {
                                dispatch_async(dispatch_get_main_queue(), {
                                    self.presentViewController(self.activityAlert, animated: false, completion: nil)
                                    self.callUpdateService(students[index])
                                })
                                
                            }
                        })
                        buttons.append(button)
                    }
                    for b in buttons {
                        chooseStudentAlert.addAction(b)
                    }
                    dispatch_async(dispatch_get_main_queue(), {
                        self.activityAlert.dismissViewControllerAnimated(true, completion: {
                            self.presentViewController(chooseStudentAlert, animated: true, completion: nil)
                        })
                    })
                } else {
                    self.callUpdateService(legitamateUser!.students!.allObjects[0] as! Student)
                }

				
			} else {
				dispatch_async(dispatch_get_main_queue(), {
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
    
    // - MARK: HELPER FUNCTIONS
    func callUpdateService(student: Student) {
		let _ = UpdateService(student: student, completionHandler: { successful, error in
            // TODO: ADD ERROR HANDLING

			// TEST STUFF
			// fetch the user
			
			let student = self.appDelegate.managedObjectContext.objectWithID(student.objectID) as! Student

			print("")
			print("Nice Grades! " + student.name!)
			print("")

			// Sort Alphabetically
			let sortedSubjects = student.subjects!.allObjects.sort { ($0 as! Subject).name! < ($1 as! Subject).name! } as! [Subject]

			for s in sortedSubjects {
				print(s.name! + ":")

				// Sort by MP Number
				let sortedMarkingPeriods = s.markingPeriods!.allObjects.sort { ($0 as! MarkingPeriod).number! < ($1 as! MarkingPeriod).number! } as! [MarkingPeriod]

				// Alert String

				for mp in sortedMarkingPeriods {

					print("\tMarking Period: " + mp.number!)
					if (!mp.empty!.boolValue) {

						print("\t\t" + "(Percent Grade: " + mp.percentGrade! + "):")

						if (mp.number! == "4") {
						}

						// Sort by Date
						let sortedAssignments = mp.assignments!.allObjects.sort {
							let one = $0 as! Assignment
							let two = $1 as! Assignment

							return one.date!.compare(two.date!) == NSComparisonResult.OrderedDescending
						} as! [Assignment]

						for a in sortedAssignments {
							let score = a.totalPoints! + "/" + a.possiblePoints!
							let s = "\t\t\t" + a.name! + "\t Score: " + score
							print(s)
						}
					}
				}
			}

			// This section of code prevents an empty marking period from being displayed

			let subjects = student.subjects!.allObjects as! [Subject]
			var someSubject = subjects.randomObject!

			// Select a random subject and marking period
			var someMarkingPeriod = (someSubject.markingPeriods!.allObjects as! [MarkingPeriod]).randomObject!

			while (someMarkingPeriod.empty!.boolValue) {
				someSubject = subjects.randomObject!
				someMarkingPeriod = (someSubject.markingPeriods!.allObjects as! [MarkingPeriod]).randomObject!
			}

			dispatch_async(dispatch_get_main_queue(), {
				self.activityAlert.dismissViewControllerAnimated(true, completion: {

					let randomGradeAlert = UIAlertController(title: someSubject.name!, message: "MP " + someMarkingPeriod.number! + ": " + someMarkingPeriod.percentGrade!, preferredStyle: .Alert)
					let ok = UIAlertAction(title: "K?", style: .Default, handler: { alertAction in
						let moc = self.appDelegate.managedObjectContext
						self.appDelegate.deleteAllUsers(moc)
						moc.saveContext()
					})
					randomGradeAlert.addAction(ok)
					self.presentViewController(randomGradeAlert, animated: true, completion: nil)
				})
			})
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
