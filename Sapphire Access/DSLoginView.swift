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
    var loginButtonTitleText: String!
    
	@IBOutlet var forgotPasswordButton: UIButton!
	var containerVC: ContainerVC!

	@IBOutlet var keyboardConstraint: NSLayoutConstraint!
	var kbHeight: CGFloat?
	var setConstant: CGFloat?
	var isHidden: Bool = true

	let appDelegate = UIApplication.shared.delegate as! AppDelegate
	var validatedUser: User!
	var selectedStudentIndex: Int = 0

	// This is the Indicator that will show while the app retrieves all the required data
	var activityIndicator: UIActivityIndicatorView!

	override func viewDidLoad() {
		super.viewDidLoad()
        loginButtonTitleText = loginButton.titleLabel?.text
		containerVC = self.navigationController!.parent! as! ContainerVC

		// If the user taps outside the textfields close the keyboard
		let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
		view.addGestureRecognizer(tap)

		// Center Text
		usernameField.contentVerticalAlignment = .center
		passwordField.contentVerticalAlignment = .center
		pinField.contentVerticalAlignment = .center
	}

	override func viewDidAppear(_ animated: Bool) {
		// Setup Button Activity Indicator
		activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
		activityIndicator.isHidden = true
		loginButton.addSubview(activityIndicator)

		// Check If we have a user already
		if let user = User.mr_findFirst() {
			user.mr_deleteEntity()
			NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait()
		}

	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		registerForKeyboardNotifications()
	}

	override func viewWillDisappear(_ animated: Bool) {
		deregisterFromKeyboardNotifications()
	}

	func registerForKeyboardNotifications()
	{
		// Adding notifies on keyboard appearing
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
	}

	func deregisterFromKeyboardNotifications()
	{
		// Removing notifies on keyboard appearing
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
	}

	func keyboardWillShow(_ notification: Notification) {
		if (isHidden) {
            
			if let kbFrame = (notification as NSNotification).userInfo?[UIKeyboardFrameEndUserInfoKey] {
                isHidden = false
				let keyboardAnimationDuration = (notification as NSNotification).userInfo![UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval
				let keyboardFrame = (kbFrame as AnyObject).cgRectValue
				kbHeight = keyboardFrame?.height

				setConstant = keyboardConstraint.constant
				keyboardConstraint.constant = kbHeight! + 15

				UIView.animate(withDuration: keyboardAnimationDuration, animations: {
					self.view.layoutIfNeeded()
				})
			}
		}
	}

	func keyboardWillHide(_ notification: Notification)
	{
		if let constant = setConstant {
			isHidden = true
			let animationDuration = (notification as NSNotification).userInfo![UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval
			keyboardConstraint.constant = constant
			UIView.animate(withDuration: animationDuration, animations: {
				self.view.layoutIfNeeded()
			})

		}

	}

	@IBAction func forgotPassword(_ sender: AnyObject) {
		UIApplication.shared.openURL(URL(string: "https://pamet-sapphire.k12system.com/CommunityWebPortal/Public/ForgotPassword.cfm")!)
	}

	// Ask if the user wants to use touch id every time they log in with a new account
	@IBAction func login(_ sender: AnyObject) {
		self.view.endEditing(true)
		// Reset Activity Indicator Pos incase button moved
		activityIndicator.center = CGPoint(x: loginButton.frame.size.width/2, y: loginButton.frame.size.height / 2)
		self.view.layoutIfNeeded()
		let user: User = User.mr_createEntity()!
		user.username = usernameField.text!
		user.password = passwordField.text!
		user.pin = pinField.text!
		startLoading()
		loginUser(user)
	}

	func loginUser(_ user: User) {
		// Try to Login
		let _ = LoginService(loginUserWithID: user.objectID, completionHandler: { successful, error in

			DispatchQueue.main.async(execute: {
				if (successful) {
					self.stopLoading()
					self.performSegue(withIdentifier: "selectStudent", sender: self)
                    self.clearFields()
				} else {
					// If we failed
					self.stopLoading()
					self.shakeLoginButton({
						user.mr_deleteEntity()
						var err = error
						if (error!.code == NSURLErrorTimedOut) {
							err = badConnectionError
                        } else if error == badLoginError {
                            self.clearFields()
                        }
						let alert = UIAlertController(title: err!.localizedDescription, message: err!.localizedFailureReason, preferredStyle: .alert)
						alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
						self.present(alert, animated: true, completion: {
							// delete the invalid user
							User.mr_deleteAll(matching: NSPredicate(value: true))
							NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait()
						})
					})
				}
			})
		})
	}

	func clearFields() {
		passwordField.text = nil
		pinField.text = nil
	}

	func startLoading() {
		loginButton.isUserInteractionEnabled = false
        loginButton.setTitle("", for: .normal)
		activityIndicator.isHidden = false
		activityIndicator.startAnimating()
	}

	func stopLoading() {

		activityIndicator.stopAnimating()
		activityIndicator.isHidden = true
        loginButton.setTitle(loginButtonTitleText, for: .normal)
		loginButton.isUserInteractionEnabled = true
	}

	func shakeLoginButton(_ completion: @escaping () -> Void) {

		loginButton.animation = "shake"
		loginButton.duration = 1
		// loginButton.curve = "spring"
		loginButton.animateNext(completion: completion)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	// In a storyboard-based application, you will often want to do a little preparation before navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

	}
}
