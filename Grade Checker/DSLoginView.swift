//
//  DSLoginView.swift
//
//
//  Created by Dhruv Sringari on 3/10/16.
//
//

import UIKit
import CoreData

class DSLoginView: UIViewController {
	@IBOutlet var loginButton: UIButton!
	@IBOutlet var usernameField: UITextField!
	@IBOutlet var passwordField: UITextField!
	@IBOutlet var pinField: UITextField!

	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		// TODO: Check for a user in the database and push to homescreen while updating it
        appDelegate.deleteAllUsers(self.appDelegate.managedObjectContext)
	}

	@IBAction func herebutton(sender: AnyObject) {
		// TODO: Add new account functionality
		print("nice u dont have an account")
	}

	@IBAction func login(sender: AnyObject) {

		// create a new user in the database
		// FIXME: DO NOT INSERT THE USER HERE WAIT TILL WE ARE VALIDATED
		let user: User = NSEntityDescription.insertNewObjectForEntityForName("User", inManagedObjectContext: self.appDelegate.managedObjectContext) as! User
		user.username = usernameField.text!
		user.password = passwordField.text!
		user.pin = pinField.text!

		appDelegate.saveContext()

		// This is the Indicator that will show while the app retrieves all the required data
		let activityAlert = UIAlertController(title: "Logging In\n", message: nil, preferredStyle: .Alert)

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
		let _ = LoginService(userToBeLoggedIn: user, completionHandler:  { successful, error, legitamateUser in

			if (successful) {

				let _ = UpdateService(legitamateUser: user, completionHandler:  { successful, error in // FIXME: From here everything is outdated, make sure to ask for what student they want to display

					// TEST STUFF
					// fetch the user
					let updatedUser = self.appDelegate.managedObjectContext.objectWithID(user.objectID) as! User

					print("")
					print("Nice Grades! " + updatedUser.username!)
					print("")

					// Sort Alphabetically
					let sortedSubjects = updatedUser.subjects!.allObjects.sort { ($0 as! Subject).name! < ($1 as! Subject).name! } as! [Subject]

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
								}  as! [Assignment]

								for a in sortedAssignments {
									let score = a.totalPoints! + "/" + a.possiblePoints!
									let s = "\t\t\t" + a.name! + "\t Score: " + score
									print(s)
								}
							}
						}
					}
                    
                    // This section of code prevents an empty marking period from being displayed
                    
                    let subjects = updatedUser.subjects!.allObjects as! [Subject]
                    var someSubject = subjects.randomObject!
                    
                    // Select a random subject and marking period
                    var someMarkingPeriod = (someSubject.markingPeriods!.allObjects as! [MarkingPeriod]).randomObject!
                    
                    
                    while(someMarkingPeriod.empty!.boolValue) {
                        someSubject = subjects.randomObject!
                        someMarkingPeriod = (someSubject.markingPeriods!.allObjects as! [MarkingPeriod]).randomObject!
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        activityAlert.dismissViewControllerAnimated(false, completion: {
                            
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
			} else {
				dispatch_async(dispatch_get_main_queue(), {
					activityAlert.dismissViewControllerAnimated(false) {
						let alert = UIAlertController(title: error!.localizedDescription, message: error!.localizedFailureReason, preferredStyle: .Alert)
						alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
                        self.presentViewController(alert, animated: false, completion: {
                            let moc = self.appDelegate.managedObjectContext
                            self.appDelegate.deleteAllUsers(moc)
                            moc.saveContext()
                        })
					}
				})
			}
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
