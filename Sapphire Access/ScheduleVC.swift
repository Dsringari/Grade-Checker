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
	var date: String?
	var letterDay: String?
	@IBOutlet var tableView: UITableView!
	@IBOutlet var loading: UIActivityIndicatorView!
	@IBOutlet var errorView: UIView!

	var student: Student?
	

	var periodNames: [String] = []
	var periodTeachers: [String] = []
	var periodRooms: [String] = []
	var periods: [String] = []
    var times: [String] = []
    var currentLetterDay: String?

	// red, orange, yellow, green, teal blue, blue, purple, pink
	var colors: [UIColor] = [UIColor(red: 255, green: 59, blue: 48), UIColor(red: 255, green: 149, blue: 0), UIColor(red: 255, green: 204, blue: 0), UIColor(red: 76, green: 217, blue: 100), UIColor(red: 90, green: 200, blue: 250), UIColor(red: 0, green: 122, blue: 255), UIColor(red: 88, green: 86, blue: 214), UIColor(red: 255, green: 45, blue: 85)]

	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view.
		tableView.delegate = self
		tableView.dataSource = self
		loadSchedule()
		errorView.hidden = true
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(loadSchedule), name: "loadStudent", object: nil)
	}

	func loadSchedule() {
        if let studentName = NSUserDefaults.standardUserDefaults().stringForKey("selectedStudent") {
            student = Student.MR_findFirstByAttribute("name", withValue: studentName)
        }
        
        guard let student = student else {
            return
        }
        
		startLoadingAnimation()
		Alamofire.request(.GET, "https://pamet-sapphire.k12system.com/CommunityWebPortal/Backpack/StudentSchedule.cfm?STUDENT_RID=\(student.id!)")
		.validate()
			.response(completionHandler: { request, response, data, error in
				dispatch_async(dispatch_get_main_queue(), {
					if (error != nil) {
						self.date = "Error!"
						self.letterDay = "Failed to Load!"
						self.stopLoadingAnimation()
						self.tableView.reloadData()
					} else {
                        
						if let doc = Kanna.HTML(html: data!, encoding: NSUTF8StringEncoding) {
							var currentDayIndex: Int? = nil
							var tbody = ""
							var datesXPath = "//*[@id=\"contentPipe\"]/div[2]/table/\(tbody)tr[1]//th" // *[@id="contentPipe"]/div[2]/table/tbody/tr[1] //*[@id="contentPipe"]/div[2]/table/tbody/tr[1]/th[2]
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

							if (currentDayIndex == nil) {
								tbody = "tbody/"
								datesXPath = "//*[@id=\"contentPipe\"]/div[2]/table/\(tbody)tr[1]//th"

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
							}
                            
							if let index = currentDayIndex {
                                self.reset()
								let periodNameXPath = "//*[@id=\"contentPipe\"]/div[2]/table/\(tbody)tr/td[\(index)]/div/div[1]/a"
								for node in doc.xpath(periodNameXPath) {
									self.periodNames.append(node.text!)
								}

								let teacherNameXPath = "//*[@id=\"contentPipe\"]/div[2]/table/\(tbody)tr/td[\(index)]/div/div[3]"

								for node in doc.xpath(teacherNameXPath) {
									var text = node.text!
									text = text.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ").invertedSet).joinWithSeparator("")
									// insert a space in between first and last name
									let name = self.splitNames(text)
									self.periodTeachers.append(name)
								}

								let roomXPath = "//*[@id=\"contentPipe\"]/div[2]/table/\(tbody)/tr/td[\(index)]/div/div[4]"
								for node in doc.xpath(roomXPath) {
									var text = node.text!
									text = text.componentsSeparatedByString("DUR:")[0]
									text = text.componentsSeparatedByString("RM:")[1]
									text = text.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890").invertedSet).joinWithSeparator("")
									self.periodRooms.append(text)
								}

								let periodXPath = "//*[@id=\"contentPipe\"]/div[2]/table/\(tbody)/tr/th[count(parent::tr/th)=1]"
								let nodes = doc.xpath(periodXPath)
								for i in 0..<nodes.count {
									self.periods.append(nodes[i].text!)
								}
                                
                                let timeXPath = "//*[@id=\"contentPipe\"]/div[2]/table/\(tbody)/tr/td[1]/div/div[5]"
                                for node in doc.xpath(timeXPath) {
                                    let text = node.text!.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "12345567890:-").invertedSet).joinWithSeparator("")
                                    self.times.append(text)
                                }

								let letterDayXPath = "//*[@id=\"contentPipe\"]/div[2]/table/\(tbody)/tr[2]//th[\(index + 1)]"
								let text = doc.xpath(letterDayXPath)[0].text!
                                self.currentLetterDay = text.substringFromIndex(text.endIndex.advancedBy(-1))
								self.letterDay = "Letter Day: " + self.currentLetterDay!
                                
                                self.tabBarController?.tabBar.items![1].badgeValue = self.currentLetterDay
                                
                                
								let formatter = NSDateFormatter()
								formatter.dateFormat = "EEEE, LLLL d"
								self.date = formatter.stringFromDate(NSDate())

								self.tableView.reloadData()
								self.tableView.hidden = false
								self.stopLoadingAnimation()

							} else {
								self.scheduleNotFound()
								self.stopLoadingAnimation()
							}
						}
					}
				})
		})
	}
	@IBAction func reload(sender: AnyObject) {
		self.student = Student.MR_findFirstByAttribute("name", withValue: NSUserDefaults.standardUserDefaults().stringForKey("selectedStudent")!)!
		loadSchedule()
	}

	func scheduleNotFound() {
		date = ""
		letterDay = ""
		tableView.hidden = true
		errorView.hidden = false
        self.tabBarController?.tabBar.items![1].badgeValue = nil
        tableView.reloadData()
	}

	func today() -> String {
		let formatter = NSDateFormatter()
		formatter.dateFormat = "MM/dd/yyyy"
		return formatter.stringFromDate(NSDate())
	}

	func reset() {
		periods = []
		periodNames = []
		periodRooms = []
		periodTeachers = []
        times = []
	}

	// Takes JessicaMcGroary and returns Jessica McGroary
	func splitNames(string: NSString) -> String {
		var newString = ""

		guard string.length != 0 else {
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

	func startLoadingAnimation() {
		tableView.hidden = true
		loading.startAnimating()
		errorView.hidden = true
	}

	func stopLoadingAnimation() {
		tableView.hidden = false
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
		return periods.count + 1
	}
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return (indexPath.row == 0) ? 95 : 75
    }

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("today") as! ScheduleTodayCell
            cell.date.text = date
            cell.letterDay.text = letterDay
            cell.separatorInset = UIEdgeInsetsMake(0, 10000, 0, 0)
            cell.indentationWidth = 10000 * -1
            cell.indentationLevel = 1
            return cell
        }
        
		let cell = tableView.dequeueReusableCellWithIdentifier("period") as! ScheduleCell
		cell.name.text = periodNames[indexPath.row - 1]
		cell.period.text = periods[indexPath.row - 1]
		cell.teacher.text = periodTeachers[indexPath.row - 1]
		cell.room.text = "RM: \(periodRooms[indexPath.row - 1])"
		cell.colorTab.backgroundColor = colors[(indexPath.row - 1) % colors.count]
        cell.time.text = times[safe: indexPath.row - 1]

		return cell
	}

}
