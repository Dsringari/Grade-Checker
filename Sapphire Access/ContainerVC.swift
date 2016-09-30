//
//  ContainerVC.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 5/14/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit
import MagicalRecord


class ContainerVC: UIViewController {

	@IBOutlet weak var containerView: UIView!
	weak var currentViewController: UIViewController?

	var currentSegueIdentifier: String!

	override func viewDidLoad() {
		super.viewDidLoad()
		if UserDefaults.standard.string(forKey: "selectedStudent") == nil {
			currentViewController = storyboard?.instantiateViewController(withIdentifier: "login")
		} else {
			currentViewController = storyboard?.instantiateViewController(withIdentifier: "resume")
		}
        
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(popToResume), name: "popToResume", object: nil)

		self.currentViewController!.view.translatesAutoresizingMaskIntoConstraints = false
		addChildViewController(currentViewController!)
		self.addSubview(self.currentViewController!.view, toView: self.containerView)

	}

	func addSubview(_ subView: UIView, toView parentView: UIView) {
		parentView.addSubview(subView)

		var viewBindingsDict = [String: AnyObject]()
		viewBindingsDict["subView"] = subView
		parentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[subView]|", options: [], metrics: nil, views: viewBindingsDict))
		parentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[subView]|", options: [], metrics: nil, views: viewBindingsDict))
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func cycleFromViewController(_ oldViewController: UIViewController, toViewController newViewController: UIViewController) {
		oldViewController.willMove(toParentViewController: nil)
		self.addChildViewController(newViewController)
		self.addSubview(newViewController.view, toView: self.containerView!)

		newViewController.view.layoutIfNeeded()

		oldViewController.view.removeFromSuperview()
		oldViewController.removeFromParentViewController()
		newViewController.didMove(toParentViewController: self)

	}

	func toLogin() {
		let newViewController = self.storyboard?.instantiateViewController(withIdentifier: "login")
		newViewController!.view.translatesAutoresizingMaskIntoConstraints = false
		cycleFromViewController(currentViewController!, toViewController: newViewController!)
		currentViewController = newViewController
	}
    
    func toResume() {
        let newViewController = self.storyboard?.instantiateViewController(withIdentifier: "resume")
        newViewController!.view.translatesAutoresizingMaskIntoConstraints = false
        cycleFromViewController(currentViewController!, toViewController: newViewController!)
        currentViewController = newViewController
    }

}
