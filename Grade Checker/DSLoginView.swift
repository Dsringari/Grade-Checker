//
//  DSLoginView.swift
//  
//
//  Created by Dhruv Sringari on 3/10/16.
//
//

import UIKit

class DSLoginView: UIViewController {
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var usernameField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var pinField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func login(sender: AnyObject) {
        let user: User = User(username: usernameField.text!, password: passwordField.text!, pin: passwordField.text!)
        let loginService = LoginService(userToBeLoggedIn: user)
        loginService.login { successful in
            if (successful) {
                let alert = UIAlertController(title: "Hello", message: "It Works", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
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
