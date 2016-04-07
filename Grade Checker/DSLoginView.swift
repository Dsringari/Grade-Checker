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
        // create a new user in the database
        let moc = DataController().managedObjectContext
        var user: User = NSEntityDescription.insertNewObjectForEntityForName("User", inManagedObjectContext: moc) as! User
        user.username = usernameField.text!
        user.password = passwordField.text!
        user.pin = pinField.text!
        
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
                    let alert = UIAlertController(title: "Hello, " + user.id!, message: "It Works", preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
                    self.presentViewController(alert, animated: false, completion: nil)
                    
                    let _ = UpdateService(legitamateUser: legitamateUser!) { successful, error, user in
                        if (successful) {
                            print("we updated the user")
                        }
                    }
                    
                    do {
                        try moc.save()
                    } catch {
                        abort()
                    }
                })
            } else {
                dispatch_async(dispatch_get_main_queue(), {
                    activityAlert.dismissViewControllerAnimated(false, completion: nil)
                    let alert = UIAlertController(title: error!.localizedDescription, message: error!.localizedFailureReason, preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
                    self.presentViewController(alert, animated: false, completion: nil)
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
