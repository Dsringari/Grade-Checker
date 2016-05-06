//
// DSDataService.swift
// Grade Checker
//
// Created by Dhruv Sringari on 3/18/16.
// Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit
import Kanna
import CoreData

struct SubjectInfo {
	var htmlPage: String
	var name: String
	var room: String
	var teacher: String
	var sectionGUID: String
	var markingPeriods: [MarkingPeriodInfo]?
}

extension SubjectInfo: Equatable {}
func ==(lhs: SubjectInfo, rhs: SubjectInfo) -> Bool {
    return lhs.htmlPage == rhs.htmlPage && lhs.name == rhs.name && lhs.room == rhs.room && lhs.teacher == rhs.teacher && lhs.sectionGUID == rhs.sectionGUID
}


struct MarkingPeriodInfo {
	var empty: Bool
	var number: String
	var percentGrade: String
	var possiblePoints: String
	var totalPoints: String
	var assignments: [AssignmentInfo]?
}

struct AssignmentInfo {
	var name: String
	var possiblePoints: String
	var totalPoints: String
	var dateCreated: NSDate
}

class UpdateService {
	var user: UserInfo
	var student: StudentInfo
	let session = NSURLSession.sharedSession()
	let timer: ParkBenchTimer?

	// The class should only be used with a valid user
	init(withUserInfo user: UserInfo, andStudent student: StudentInfo) {
		self.student = student
		self.user = user
		self.timer = ParkBenchTimer()
	}

    func update(completionHandler: (successful: Bool, error: NSError?, student: StudentInfo?) -> Void) {
		// Make Sure we have the correct log in cookies
		let loginService = LoginService(withUserInfo: self.user)
		loginService.refresh { successful, error in
			if (successful) {
				// Courses & Grades Page Request
				let backpackUrl = NSURL(string: "https://pamet-sapphire.k12system.com/CommunityWebPortal/Backpack/StudentClasses.cfm?STUDENT_RID=" + self.student.id)!
				let coursesPageRequest = NSMutableURLRequest(URL: backpackUrl, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: 10)
				coursesPageRequest.HTTPMethod = "GET"

				let getCoursePage = self.session.dataTaskWithRequest(coursesPageRequest) { data, response, error in

					if (error != nil) {
						completionHandler(successful: false, error: error, student: nil)
						return
					} else {

						if let html = NSString(data: data!, encoding: NSASCIIStringEncoding) {
							self.downloadSubjects(coursesAndGradePageHtml: html as String, completionHandler: completionHandler)
						} else {
							completionHandler(successful: false, error: unknownResponseError, student: nil)
						}
					}
				}
				getCoursePage.resume()
			} else {
				completionHandler(successful: false, error: error, student: nil)
			}

		}
	}

	// Adds the subjects to the user when the correct page is given
	// MAY BE CALLED FROM NON_MAIN THREAD
	private func downloadSubjects(coursesAndGradePageHtml html: String, completionHandler: (successful: Bool, error: NSError?, student: StudentInfo?) -> Void) {
		let updateGroup = dispatch_group_create()

		let doc = Kanna.HTML(html: html, encoding: NSASCIIStringEncoding)!

		let xpath = "//*[@id=\"contentPipe\"]/table//tr[@class!=\"classNotGraded\"]//td/a" // finds all the links on the visable table NOTE: DO NOT INCLUDE /tbody FOR SIMPLE TABLES WITHOUT A HEADER AND FOOTER

		let nodes = doc.xpath(xpath)

		if (nodes.count == 0) {
			completionHandler(successful: false, error: unknownResponseError, student: nil)
			return
		}

		// Store the subject's url into a subject object and get the name
		var subjectAddresses: [String] = []
		var sectionGUIDs: [String] = []
		var htmlPages: [String] = []
		var names: [String] = []
		for node: XMLElement in nodes {
			let subjectAddress = node["href"]!
			// Used to unique the subject
			let sectionGuidText = subjectAddress.componentsSeparatedByString("&")[1]
			let htmlPage = "https://pamet-sapphire.k12system.com" + subjectAddress // The node link includes a / before the page link so we leave the normal / off
			let name = node.text!.substringToIndex(node.text!.endIndex.predecessor()) // Remove the space after the name

			subjectAddresses.append(subjectAddress)
			sectionGUIDs.append(sectionGuidText)
			htmlPages.append(htmlPage)
			names.append(name)
		}

		// Get the teachers
		// Ignores the "not-graded" html classes and we have to include the predicate on the tr element because we can't skip them by looking for links
		let teacherXPath = "//*[@id=\"contentPipe\"]/table/tr[@class!=\"classNotGraded\"]/td[2]"
		var teachers: [String] = []
		for teacherElement in doc.xpath(teacherXPath) {
			teachers.append(teacherElement.text!)
		}

		// Get the room number
		let roomXPath = "//*[@id=\"contentPipe\"]/table/tr[@class!=\"classNotGraded\"]/td[4]"
		var rooms: [String] = []
		for roomElement in doc.xpath(roomXPath) {
			rooms.append(roomElement.text!)
		}

		var subjects: [SubjectInfo] = []
		for index in 0 ... (subjectAddresses.count - 1) {
			let newSubject = SubjectInfo(htmlPage: htmlPages[index], name: names[index], room: rooms[index], teacher: teachers[index], sectionGUID: sectionGUIDs[index], markingPeriods: nil)
			subjects.append(newSubject)
		}

		// Get the marking period information for the subjects
		var results: [(successful: Bool, error: NSError?)] = []
		for subject in subjects {
			for index in 1 ... 4 {

				let markingPeriodAddress = "https://pamet-sapphire.k12system.com/CommunityWebPortal/Backpack/StudentClassGrades.cfm?STUDENT_RID=" + self.student.id + "&COUR" + subject.sectionGUID + "&MP_CODE=" + String(index)

				let mpRequest = NSURLRequest(URL: NSURL(string: markingPeriodAddress)!, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: 10)

				// Request the mp page
				dispatch_group_enter(updateGroup); self.timer!.entries += 1 // 2

				let getMarkingPeriodPage = self.session.dataTaskWithRequest(mpRequest) { data, response, error in
					if (error != nil) {
						results.append((false, error!))
						dispatch_group_leave(updateGroup); self.timer!.exits += 1 // 2
					} else {

						// Test if we recieved valid information, if not return aka fail
						guard let mpPageHtml = Kanna.HTML(html: data!, encoding: NSUTF8StringEncoding) else {
							results.append((false, unknownResponseError))
							dispatch_group_leave(updateGroup); self.timer!.exits += 1 // 2
							return
						}
                        // Get the correct subject and mp number from the response url
                        let sectionGUID = response!.URL!.absoluteString.componentsSeparatedByString("&COURSE_SECTION_GUID=")[1].componentsSeparatedByString("&")[0]
                        let mpNumber = response!.URL!.absoluteString.componentsSeparatedByString("&MP_CODE=")[1]
                        
                        var subject = subjects.filter{$0.sectionGUID == sectionGUID}[0]
                        subjects.removeObject(subject)
                        
                        if (subject.markingPeriods == nil) {
                            subject.markingPeriods = []
                        }

						// Parse the page
						let markingPeriod: MarkingPeriodInfo
						if let result = self.parseMarkingPeriodPage(html: mpPageHtml) {
                            var assignments: [AssignmentInfo] = []
							for assignment in result.assignments {
                                // String to Date
                                let dateFormatter = NSDateFormatter()
                                // http://userguide.icu-project.org/formatparse/datetime/ <- Guidelines to format date
                                dateFormatter.dateFormat = "MM/dd/yy"
                                let date = dateFormatter.dateFromString(assignment.date)!
                                let newA = AssignmentInfo(name: assignment.name, possiblePoints: assignment.possiblePoints, totalPoints: assignment.totalPoints, dateCreated: date)
                                assignments.append(newA)
							}
                            
                            markingPeriod = MarkingPeriodInfo(empty: false, number: mpNumber, percentGrade: result.percentGrade, possiblePoints: result.possiblePoints, totalPoints: result.totalPoints, assignments: assignments)

						} else {
							markingPeriod = MarkingPeriodInfo(empty: true, number: mpNumber, percentGrade: "", possiblePoints: "", totalPoints: "", assignments: nil)
						}

						subject.markingPeriods!.append(markingPeriod)
                        subjects.append(subject)
						dispatch_group_leave(updateGroup); self.timer!.exits += 1 // 2
					}
				}
				getMarkingPeriodPage.resume()
			} // Marking Period Loop
		} // Subject Loop

		// Runs when the User has been completely updated
		dispatch_group_notify(updateGroup, dispatch_get_main_queue()) {
			self.timer!.stop()
//            print("------------------------------------------------------")
//            print("Completed in: " + String(self.timer!.duration!))
//            print("Entries: " + String(self.timer!.entries) + ", Exits: " + String(self.timer!.exits))
//            print("------------------------------------------------------")
//            print("")
            // Successful
            self.student.subjects = subjects
            if (!results.isEmpty) {
                completionHandler(successful: true, error: nil, student: self.student)
            } else {
                completionHandler(successful: false, error: results[0].error, student: nil) // Not Really Reliable but whatever
            }
		}
	}

	private func parseMarkingPeriodPage(html doc: HTMLDocument) -> (assignments: [(name: String, totalPoints: String, possiblePoints: String, date: String)], totalPoints: String, possiblePoints: String, percentGrade: String)? {
		var percentGrade: String = ""
		var totalPoints: String = ""
		var possiblePoints: String = ""

		// Parse all the assignments while ignoring the assignment descriptions
		let assignmentsXpath = "//*[@id=\"assignments\"]/tr[count(td)=6]"

		// Get all the assignment names
		var aNames: [String] = []
		for aE: XMLElement in doc.xpath(assignmentsXpath + "/td[1]") {
			aNames.append(aE.text!)
		}

		// Check if we have an empty marking period
		if (aNames.count == 0) {
			return nil
		}

		// Parse percent grade
		let percentageTextXpath = "//*[@id=\"assignmentFinalGrade\"]/b[1]/following-sibling::text()"
		if let percentageTextElement = doc.at_xpath(percentageTextXpath) {
			var text = percentageTextElement.text!
			// Remove all the spaces and other characters
			text = text.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "1234567890.%").invertedSet).joinWithSeparator("")
			// If we have a marking period with assignments but 0/0 points change the % to 0.00%
			if (text == "%") {
				text = "0.00%"
			}
			percentGrade = text
		} else {
			print("Failed to find percentageTextElement!")
			return nil
		}

		// Parse total points
		let pointsTextXpath = "//*[@id=\"assignmentFinalGrade\"]/b[2]/following-sibling::text()"
		if let pointsTextElement = doc.at_xpath(pointsTextXpath) {
			var text = pointsTextElement.text!
			// Remove all the spaces and other characters
			text = text.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "1234567890./").invertedSet).joinWithSeparator("")
			// Seperate the String into Possible / Total Points
			totalPoints = text.componentsSeparatedByString("/")[0]
			possiblePoints = text.componentsSeparatedByString("/")[1]
		} else {
			print("Failed to find pointsTextElement!")
			return nil
		}

		// Get all total points
		var aTotalPoints: [String] = []
		for aE: XMLElement in doc.xpath(assignmentsXpath + "/td[2]") {
			var text = aE.text!
			text = text.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "1234567890.+*ex").invertedSet).joinWithSeparator("")
			aTotalPoints.append(text)
		}

		// Get All possible points
		var aPossiblePoints: [String] = []
		for aE: XMLElement in doc.xpath(assignmentsXpath + "/td[3]") {
			var text = aE.text!
			text = text.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "1234567890.").invertedSet).joinWithSeparator("")
			aPossiblePoints.append(text)
		}

		// Get All the dates
		var aDates: [String] = []
		for aE: XMLElement in doc.xpath(assignmentsXpath + "/td[4]") {
			let text = aE.text!
			aDates.append(text)
		}

		// Build the assignment tuples
		var assignments: [(name: String, totalPoints: String, possiblePoints: String, date: String)] = []
		for index in 0 ... (aNames.count - 1) {
			let newA = (aNames[index], aTotalPoints[index], aPossiblePoints[index], aDates[index])
			assignments.append(newA)
			// print(newA)
		}

		return (assignments, totalPoints, possiblePoints, percentGrade)
	}

}

class ParkBenchTimer {

	let startTime: CFAbsoluteTime
	var endTime: CFAbsoluteTime?
	var entries: Int = 0
	var exits: Int = 0

	init() {
		startTime = CFAbsoluteTimeGetCurrent()
	}

	func stop() -> CFAbsoluteTime {
		endTime = CFAbsoluteTimeGetCurrent()

		return duration!
	}

	var duration: CFAbsoluteTime? {
		if let endTime = endTime {
			return endTime - startTime
		} else {
			return nil
		}
	}
}

