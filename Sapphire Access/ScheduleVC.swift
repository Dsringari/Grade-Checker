//
//  ScheduleVC.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 6/29/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit

class ScheduleVC: UIViewController {
    @IBOutlet var date: UILabel!
    @IBOutlet var letterDay: UILabel!
    @IBOutlet var periods: UITableView!
    @IBOutlet var loading: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    
    func startLoadingAnimation() {
        date.hidden = true
        letterDay.hidden = true
        loading.startAnimating()
    }
    
    func stopLoadingAnimation() {
        date.hidden = false
        letterDay.hidden = false
        loading.stopAnimating()
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
