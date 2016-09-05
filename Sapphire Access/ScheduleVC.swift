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
	@IBOutlet var tableView: UITableView!
	@IBOutlet var loading: UIActivityIndicatorView!
	@IBOutlet var errorView: UIView!
    @IBOutlet var errorImage: UIImageView!
    @IBOutlet var errorText: UILabel!
    @IBOutlet var daySegmentedControl: UISegmentedControl!

	var student: Student?
	
    var schedules: [(date: String, names: [String], teachers: [String], periods: [String], rooms: [String], times: [String], letterDay: String)] = []
    var selectedDayIndex: Int = 0

	// red, orange, yellow, green, teal blue, blue, purple, pink
	var colors: [UIColor] = [UIColor(red: 255, green: 59, blue: 48), UIColor(red: 255, green: 149, blue: 0), UIColor(red: 255, green: 204, blue: 0), UIColor(red: 76, green: 217, blue: 100), UIColor(red: 90, green: 200, blue: 250), UIColor(red: 0, green: 122, blue: 255), UIColor(red: 88, green: 86, blue: 214), UIColor(red: 255, green: 45, blue: 85)]

	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view.
		tableView.delegate = self
		tableView.dataSource = self
		loadSchedule()
        
        // Find the hairline so we can hide it
        for view in self.navigationController!.navigationBar.subviews {
            for aView in view.subviews {
                if (aView.isKindOfClass(UIImageView) &&  aView.bounds.size.width == self.navigationController!.navigationBar.frame.size.width && aView.bounds.size.height < 2) {
                    aView.removeFromSuperview()
                }
            }
        }
        // Remove toolbar's border
        self.navigationController!.toolbar.clipsToBounds = true

        
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
						self.errorText.text = "Error! Failed to Load"
						self.stopLoadingAnimation()
                        self.showErrorView(false)
						self.tableView.reloadData()
					} else {
                        
						if let doc = Kanna.HTML(html: data!, encoding: NSUTF8StringEncoding) {
							var tbody = ""
							var datesXPath = "//*[@id=\"contentPipe\"]/div[2]/table/\(tbody)tr[1]//th" // *[@id="contentPipe"]/div[2]/table/tbody/tr[1] //*[@id="contentPipe"]/div[2]/table/tbody/tr[1]/th[2]
                            var availableDayIndices: [Int] = []
                            var dates: [String] = []
							for index in 0..<doc.xpath(datesXPath).count {
								// the first header is a blank space
								if (index == 0) {
									continue
                                }
								availableDayIndices.append(index)
                                dates.append(doc.xpath(datesXPath)[index].text!)
							}

							if (availableDayIndices.count == 0) {
                                dates = []
								tbody = "tbody/"
								datesXPath = "//*[@id=\"contentPipe\"]/div[2]/table/\(tbody)tr[1]//th"

								for index in 0..<doc.xpath(datesXPath).count {
									// the first header is a blank space
									if (index == 0) {
										continue
									}

									availableDayIndices.append(index)
                                    dates.append(doc.xpath(datesXPath)[index].text!)
								}
							}
                            
                            guard availableDayIndices.count != 0 else {
                                self.stopLoadingAnimation()
                                self.scheduleNotFound()
                                return
                            }
                            
                            self.reset()
                            for index in availableDayIndices {
                                
                                var names: [String] = []
								let periodNameXPath = "//*[@id=\"contentPipe\"]/div[2]/table/\(tbody)tr/td[\(index)]/div/div[1]/a"
								for node in doc.xpath(periodNameXPath) {
									names.append(node.text!)
								}

								let teacherNameXPath = "//*[@id=\"contentPipe\"]/div[2]/table/\(tbody)tr/td[\(index)]/div/div[3]"
                                var teachers: [String] = []
								for node in doc.xpath(teacherNameXPath) {
									var text = node.text!
									text = text.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ").invertedSet).joinWithSeparator("")
									// insert a space in between first and last name
									let name = self.splitNames(text)
									teachers.append(name)
								}

								let roomXPath = "//*[@id=\"contentPipe\"]/div[2]/table/\(tbody)/tr/td[\(index)]/div/div[4]"
                                var rooms: [String] = []
								for node in doc.xpath(roomXPath) {
									var text = node.text!
									text = text.componentsSeparatedByString("DUR:")[0]
									text = text.componentsSeparatedByString("RM:")[1]
									text = text.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890").invertedSet).joinWithSeparator("")
									rooms.append(text)
								}

								let periodXPath = "//*[@id=\"contentPipe\"]/div[2]/table/\(tbody)/tr/th[count(parent::tr/th)=1]"
                                var periods: [String] = []
								let nodes = doc.xpath(periodXPath)
								for i in 0..<nodes.count {
									periods.append(nodes[i].text!)
								}
                                
                                let timeXPath = "//*[@id=\"contentPipe\"]/div[2]/table/\(tbody)/tr/td[1]/div/div[5]"
                                var times: [String] = []
                                for node in doc.xpath(timeXPath) {
                                    let text = node.text!.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "12345567890:-").invertedSet).joinWithSeparator("")
                                    times.append(text)
                                }

								let letterDayXPath = "//*[@id=\"contentPipe\"]/div[2]/table/\(tbody)/tr[2]//th[\(index + 1)]"
                                var letterDay: String
								let text = doc.xpath(letterDayXPath)[0].text!
                                letterDay = text.substringFromIndex(text.endIndex.advancedBy(-1))
                                
                                self.schedules.append((dates[index-1],names, teachers, periods, rooms, times, letterDay))
							}
                            
                            let days = self.schedules.map{$0.date}
                            self.daySegmentedControl.removeAllSegments()
                            let today = self.today()
                            for index in 0..<days.count {
                                if days[index] == today {
                                    self.selectedDayIndex = index
                                    self.tabBarController?.tabBar.items![1].badgeValue = self.schedules[self.selectedDayIndex].letterDay
                                }
                                self.daySegmentedControl.insertSegmentWithTitle(self.dateToDayOfWeek(days[index]), atIndex: index, animated: false)
                            }
                            self.daySegmentedControl.selectedSegmentIndex = self.selectedDayIndex
                            self.navigationController?.navigationBar.topItem?.title = self.dateToText(days[self.selectedDayIndex])
                            
                            self.tableView.reloadData()
                            self.tableView.hidden = false
                            self.stopLoadingAnimation()
						}
					}
				})
		})
	}
    
    
    @IBAction func dayChanged(sender: AnyObject) {
        selectedDayIndex = daySegmentedControl.selectedSegmentIndex
        navigationController?.navigationBar.topItem?.title = self.dateToText(schedules[selectedDayIndex].date)
        tableView.reloadData()
    }
	@IBAction func reload(sender: AnyObject) {
		self.student = Student.MR_findFirstByAttribute("name", withValue: NSUserDefaults.standardUserDefaults().stringForKey("selectedStudent")!)!
		loadSchedule()
	}

	func scheduleNotFound() {
        errorText.text = "No Schedule Found"
		showErrorView(false)
        self.tabBarController?.tabBar.items![1].badgeValue = nil
        tableView.reloadData()
	}

	func today() -> String {
		let formatter = NSDateFormatter()
		formatter.dateFormat = "MM/dd/yyyy"
		return formatter.stringFromDate(NSDate())
	}
    
    func dateToDayOfWeek(date: String) -> String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        let date = formatter.dateFromString(date)!
        formatter.dateFormat = "EEE"
        return formatter.stringFromDate(date)
    }
    
    func dateToText(date: String) -> String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        let date = formatter.dateFromString(date)!
        formatter.dateFormat = "MMMM, d"
        return formatter.stringFromDate(date)
    }

	func reset() {
		schedules = []
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
		showErrorView(true)
        loading.startAnimating()
	}

	func stopLoadingAnimation() {
		hideErrorView()
        loading.stopAnimating()
	}
    
    func showErrorView(loading: Bool) {
        if loading {
            errorView.hidden = false
            errorImage.hidden = true
            errorText.hidden = true
        } else {
            errorView.hidden = false
            errorImage.hidden = false
            errorText.hidden = false
        }
    }
    
    func hideErrorView() {
        errorView.hidden = true
        errorImage.hidden = true
        errorText.hidden = true
    }

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return schedules.count != 0 ? schedules[selectedDayIndex].names.count+1 : 0
	}
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 75
    }

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("today") as! ScheduleTodayCell
            cell.letterDay.text = "Letter Day: " + schedules[selectedDayIndex].letterDay
            cell.separatorInset = UIEdgeInsetsMake(0, 10000, 0, 0)
            cell.indentationWidth = 10000 * -1
            cell.indentationLevel = 1
            return cell
        }
        
		let cell = tableView.dequeueReusableCellWithIdentifier("period") as! ScheduleCell
        let schedule = schedules[selectedDayIndex]
		cell.name.text = schedule.names[indexPath.row - 1]
		cell.period.text = schedule.periods[indexPath.row - 1]
		cell.teacher.text = schedule.teachers[indexPath.row - 1]
		cell.room.text = "RM: \(schedule.rooms[indexPath.row - 1])"
		cell.colorTab.backgroundColor = colors[(indexPath.row - 1) % colors.count]
        cell.time.text = schedule.times[safe: indexPath.row - 1]

		return cell
	}

}
