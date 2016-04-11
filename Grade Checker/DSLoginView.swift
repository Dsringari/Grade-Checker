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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // TODO: Check for a user in the database and push to homescreen while updating it
        
    }

    @IBAction func herebutton(sender: AnyObject) {
        // TODO: Add new account functionality
        print("nice u dont have an account")
    }
    
    @IBAction func login(sender: AnyObject) {
        // TESTING REMOVE FOR RELEASE
        let nMoc = DataController().managedObjectContext
        let fetchRequest = NSFetchRequest()
        let entityDescription = NSEntityDescription.entityForName("User", inManagedObjectContext: nMoc)
        fetchRequest.entity = entityDescription
        
        do {
            let nUser = try nMoc.executeFetchRequest(fetchRequest)
            for user in nUser {
                let us = user as! User
                nMoc.deleteObject(us)
            }
            try nMoc.save()
        } catch {
            print(error)
            abort()
        }
        
        // create a new user in the database
        // FIXME: DO NOT INSERT THE USER HERE WAIT TILL WE ARE VALIDATED
        var user: User = NSEntityDescription.insertNewObjectForEntityForName("User", inManagedObjectContext: nMoc) as! User
        user.username = usernameField.text!
        user.password = passwordField.text!
        user.pin = pinField.text!
        
        do {
            try nMoc.save()
        } catch {
            fatalError("Failed to save MOC")
        }
        
        // This is the Indicator that will show while the app retrieves all the required data
        let activityAlert = UIAlertController(title: "Logging In\n", message: nil, preferredStyle: .Alert)
        
        let indicator = UIActivityIndicatorView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = UIColor.blackColor()
        activityAlert.view.addSubview(indicator)
        
        let views = ["pending" : activityAlert.view, "indicator" : indicator]
        var constraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[indicator]-(10)-|", options: NSLayoutFormatOptions.AlignAllCenterX, metrics: nil, views: views)
        constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|[indicator]|", options: NSLayoutFormatOptions.AlignAllCenterX, metrics: nil, views: views)
        activityAlert.view.addConstraints(constraints)
        
        indicator.userInteractionEnabled = false
        indicator.startAnimating()
        
        self.presentViewController(activityAlert, animated: true, completion: nil)
        
        // This is the LoginService Completion Handler
        let _ = LoginService(userToBeLoggedIn: user) { successful, error, legitamateUser in
            
            if (successful) {
                dispatch_async(dispatch_get_main_queue(), {
                    user = legitamateUser!
                    activityAlert.dismissViewControllerAnimated(false, completion: nil)
                    let alert = UIAlertController(title: "Hello, " + user.username!, message: "It Works", preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
                    self.presentViewController(alert, animated: false, completion: nil)
                    
                    let _ = UpdateService(legitamateUser: legitamateUser!) { successful, error in
                        if (successful) {
                            
                            // TEST STUFF
                            // refetch the user
                            let newMoc = DataController().managedObjectContext
                            let fetchRequest = NSFetchRequest()
                            let entityDescription = NSEntityDescription.entityForName("User", inManagedObjectContext: newMoc)
                            fetchRequest.entity = entityDescription
                            
                            do {
                                let nUsers = try nMoc.executeFetchRequest(fetchRequest)
                                if (nUsers.count > 1) {
                                    print("GG")
                                    abort()
                                }
                                let nUser = nUsers[0] as! User
                                
                                print("")
                                print("Nice Grades! " + nUser.username!)
                                print("")
                                
                                for subject in nUser.subjects! {
                                    
                                    let s = subject as! Subject
                                    print(subject.name! + ":")
                                    
                                    for markingPeriod in s.markingPeriods! {
                                        let mp = markingPeriod as! MarkingPeriod
                                        print("\tMarking Period: " + mp.number!)
                                        if (!mp.empty!.boolValue) {
                                        
                                           print("\t" + "(Percent Grade: " + mp.percentGrade! + "):" )
                                        
                                            if (mp.number! == "4") {
                                            
                                            }
                                        
                                            for assignment in mp.assignments! {
                                            
                                                let a = assignment as! Assignment
                                                let score = a.totalPoints! + "/" + a.possiblePoints!
                                                let s = "\t\t" + a.name! + "\t Score: " + score
                                                print(s)
                                            
                                            }
                                        }
                                    }
                                }
                            } catch {
                                print(error)
                                abort()
                            }
                            
                            
                        }
                    }
                })
            } else {
                dispatch_async(dispatch_get_main_queue(), {
                    activityAlert.dismissViewControllerAnimated(false) {
                        let alert = UIAlertController(title: error!.localizedDescription, message: error!.localizedFailureReason, preferredStyle: .Alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
                        self.presentViewController(alert, animated: false, completion: nil)
                    }
                })
            }
        }
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
