//
//  ScheduleVC.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 6/29/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit
import Alamofire
import Kanna

class ScheduleVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
	@IBOutlet var date: UILabel!
	@IBOutlet var letterDay: UILabel!
	@IBOutlet var tableView: UITableView!
	@IBOutlet var loading: UIActivityIndicatorView!

	lazy var student: Student = {
		return Student.MR_findFirstByAttribute("name", withValue: NSUserDefaults.standardUserDefaults().stringForKey("selectedStudent")!)!
	}()

	var periodNames: [String] = []
	var periodTeachers: [String] = []
	var periodRooms: [String] = []
	var periods: [String] = []

	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view.
		tableView.delegate = self
		tableView.dataSource = self
		loadSchedule()
	}

	func loadSchedule() {
		startLoadingAnimation()
		Alamofire.request(.GET, "http://192.168.1.3/CommunityWebPortal/Backpack/StudentSchedule.cfm-STUDENT_RID=\(student.id!).html")
			.validate()
			.response(completionHandler: { request, response, data, error in
				if (error != nil) {
					dispatch_async(dispatch_get_main_queue(), {
						self.date.text = "Error!"
						self.letterDay.text = error?.description
						self.stopLoadingAnimation()
						self.tableView.reloadData()
					})
				} else {
					if let doc = Kanna.HTML(html: data!, encoding: NSUTF8StringEncoding) {
						var currentDayIndex: Int?
						let datesXPath = "//*[@id=\"contentPipe\"]/div[2]/table/tbody/tr[1]/th" // *[@id="contentPipe"]/div[2]/table/tbody/tr[1]
						print(doc.title!)

						let today = self.today()
						for index in 0..<doc.xpath(datesXPath).count {
							// the first header is a blank space
							if (index == 0) {
								continue
							}
							let node = doc.xpath(datesXPath)[index]

							if (node.text! == today) {
								currentDayIndex = index
							}
						}

						if let index = currentDayIndex {
							let index = String(index)
							let periodNameXPath = "//*[@id=\"contentPipe\"]/div[2]/table/tbody//tr/td[\(index)]/div/div[1]/a"
							for node in doc.xpath(periodNameXPath) {
								self.periodNames.append(node.text!)
							}

							let teacherNameXPath = "//*[@id=\"contentPipe\"]/div[2]/table/tbody//tr/td[\(index)]/div/div[3]"

							for node in doc.xpath(teacherNameXPath) {
								var text = node.text!
								text = text.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ").invertedSet).joinWithSeparator("")
								// insert a space in between first and last name
								let name = self.splitNames(text)
								self.periodTeachers.append(name)
							}

							let roomXPath = "//*[@id=\"contentPipe\"]/div[2]/table/tbody//tr/td[\(index)]/div/div[4]"
							for node in doc.xpath(roomXPath) {
								var text = node.text!
								text = text.componentsSeparatedByString("DUR:")[0]
								text = text.componentsSeparatedByString("RM:")[1]
								text = text.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890").invertedSet).joinWithSeparator("")
								self.periodRooms.append(text)
							}

							print(self.periodNames, self.periodRooms, self.periodTeachers, separator: "\n")
						}
					}
				}
		})
	}

	func scheduleNotFound() {
		date.text = ""
	}

	func today() -> String {
		let formatter = NSDateFormatter()
		formatter.dateFormat = "MM/dd/yyyy"
		return "06/01/2016" // formatter.stringFromDate(NSDate()) //FIXME: THIS TOO THANKS BB
	}
    
    // Takes JessicaMcGroary and returns Jessica McGroary
    func splitNames(string: NSString) -> String {
        var newString = ""
        if (string.length == 0) {
            return ""
        }
        var stop = false
        for i in 1..<string.length {
            let ch = string.substringWithRange(NSMakeRange(i, 1)) as NSString
            if ch.rangeOfCharacterFromSet(NSCharacterSet.uppercaseLetterCharacterSet()).location != NSNotFound && !stop {
                newString.appendContentsOf(" ")
                stop = true
            }
            newString.appendContentsOf(ch as String)
        }
        let cString = string as String
        return String(cString[cString.startIndex]) + newString
    }

	func reload() {
		loadSchedule()
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

	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		return UITableViewCell()
	}

}
