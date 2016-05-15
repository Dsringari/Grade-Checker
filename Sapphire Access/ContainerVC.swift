//
//  ContainerVC.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 5/14/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit
import MagicalRecord

struct SegueIdentifier {
	static let login = "login"
	static let resume = "resume"
	static var initial: String?
}

class ContainerVC: UIViewController {

	@IBOutlet weak var containerView: UIView!
	weak var currentViewController: UIViewController?

	var currentSegueIdentifier: String!

	override func viewDidLoad() {
		super.viewDidLoad()
		if NSUserDefaults.standardUserDefaults().stringForKey("selectedStudent") == nil {
			currentViewController = storyboard?.instantiateViewControllerWithIdentifier("login")
		} else {
			currentViewController = storyboard?.instantiateViewControllerWithIdentifier("resume")
		}
        
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(popToResume), name: "popToResume", object: nil)

		self.currentViewController!.view.translatesAutoresizingMaskIntoConstraints = false
		addChildViewController(currentViewController!)
		self.addSubview(self.currentViewController!.view, toView: self.containerView)

	}

	func addSubview(subView: UIView, toView parentView: UIView) {
		parentView.addSubview(subView)

		var viewBindingsDict = [String: AnyObject]()
		viewBindingsDict["subView"] = subView
		parentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[subView]|", options: [], metrics: nil, views: viewBindingsDict))
		parentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[subView]|", options: [], metrics: nil, views: viewBindingsDict))
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func cycleFromViewController(oldViewController: UIViewController, toViewController newViewController: UIViewController) {
		oldViewController.willMoveToParentViewController(nil)
		self.addChildViewController(newViewController)
		self.addSubview(newViewController.view, toView: self.containerView!)

		newViewController.view.layoutIfNeeded()

		oldViewController.view.removeFromSuperview()
		oldViewController.removeFromParentViewController()
		newViewController.didMoveToParentViewController(self)

	}

	func toLogin() {
		let newViewController = self.storyboard?.instantiateViewControllerWithIdentifier("login")
		newViewController!.view.translatesAutoresizingMaskIntoConstraints = false
		cycleFromViewController(currentViewController!, toViewController: newViewController!)
		currentViewController = newViewController
	}
    
    func toResume() {
        let newViewController = self.storyboard?.instantiateViewControllerWithIdentifier("resume")
        newViewController!.view.translatesAutoresizingMaskIntoConstraints = false
        cycleFromViewController(currentViewController!, toViewController: newViewController!)
        currentViewController = newViewController
    }

}
