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
import MagicalRecord
class UpdateService {
    
    let kCharacterSet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890.*+-"
    
	let completion: (successful: Bool, error: NSError?) -> Void
	let session = NSURLSession.sharedSession()
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	var fails: [NSError] = []
	// Storing the error so we can call the completion from one spot in the class
	// var result: (successful: Bool, error: NSError?) = (true, nil)

	let timer: ParkBenchTimer?

	// The class should only be used with a valid user
	init(studentID: NSManagedObjectID, completionHandler completion: (successful: Bool, error: NSError?) -> Void) {
		self.completion = completion
		self.timer = ParkBenchTimer()

		let student = NSManagedObjectContext.MR_defaultContext().objectWithID(studentID) as! Student

		// Make Sure we have the correct log in cookies although this is redundant on the first login.
		let _ = LoginService(refreshUserWithID: student.user!.objectID, completion: { successful, error in
			if (successful) {
				NSManagedObjectContext.MR_defaultContext().refreshObject(student, mergeChanges: false)

				// Courses & Grades Page Request
				let backpackUrl = NSURL(string: "https://pamet-sapphire.k12system.com/CommunityWebPortal/Backpack/StudentClasses.cfm?STUDENT_RID=" + student.id!)!
				let coursesPageRequest = NSMutableURLRequest(URL: backpackUrl, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: 10)
				coursesPageRequest.HTTPMethod = "GET"

				let getCoursePage = self.session.dataTaskWithRequest(coursesPageRequest) { data, response, error in

					if (error != nil) {
						completion(successful: false, error: error!)
						return
					} else {

						if let html = NSString(data: data!, encoding: NSASCIIStringEncoding) {
							// Delete the subjects
							Subject.MR_deleteAllMatchingPredicate(NSPredicate(value: true), inContext: NSManagedObjectContext.MR_defaultContext())
							NSManagedObjectContext.MR_defaultContext().MR_saveOnlySelfAndWait()

							self.createSubjects(coursesAndGradePageHtml: html as String, student: student)

						} else {
							completion(successful: false, error: unknownResponseError)
						}
					}
				}
				getCoursePage.resume()
			} else {
				completion(successful: false, error: error!)
			}
		})
	}

	// Adds the subjects to the user when the correct page is given
	// MAY BE CALLED FROM NON_MAIN THREAD
	private func createSubjects(coursesAndGradePageHtml html: String, student: Student) {
		let updateGroup = dispatch_group_create()
		let subjectContext = NSManagedObjectContext.MR_context()
		let updatingStudent = subjectContext.objectWithID(student.objectID) as! Student

		if let doc = Kanna.HTML(html: html, encoding: NSASCIIStringEncoding) {

			let xpath = "//*[@id=\"contentPipe\"]/table//tr[@class!=\"classNotGraded\"]//td/a" // finds all the links on the visable table NOTE: DO NOT INCLUDE /tbody FOR SIMPLE TABLES WITHOUT A HEADER AND FOOTER

			let nodes = doc.xpath(xpath)

			if (nodes.count == 0) {
				completion(successful: false, error: unknownResponseError)
				return
			}

			// Store the subject's url into a subject object and get the name
			var subjects: [Subject] = []
			for node: XMLElement in nodes {
				let subjectAddress = node["href"]!
				// Used to unique the subject
				let sectionGuidText = subjectAddress.componentsSeparatedByString("&")[1].componentsSeparatedByString("=")[1]

				let newSubject: Subject = Subject.MR_createEntityInContext(subjectContext)!

				// Because the marking period html pages' urls repeat themselves we can use a shortcut to skip the select marking period page
				// There are only 4 marking periods
				// Even invalid marking periods have a html page
				for index in 1 ... 4 {
					// Create 4 marking periods
					let newMP: MarkingPeriod = NSEntityDescription.insertNewObjectForEntityForName("MarkingPeriod", inManagedObjectContext: subjectContext) as! MarkingPeriod
					// Add the marking periods to the subject
					newMP.subject = newSubject
					newMP.number = String(index)
					newMP.htmlPage = "https://pamet-sapphire.k12system.com/CommunityWebPortal/Backpack/StudentClassGrades.cfm?STUDENT_RID=" + student.id! + "&" + "COURSE_SECTION_GUID=" + sectionGuidText + "&MP_CODE=" + newMP.number!
					newMP.empty = NSNumber(bool: false)
				}

				newSubject.student = updatingStudent
				newSubject.htmlPage = "https://pamet-sapphire.k12system.com" + subjectAddress // The node link includes a / before the page link so we leave the normal / off
				newSubject.name = node.text!.substringToIndex(node.text!.endIndex.predecessor()) // Remove the space after the name
				newSubject.sectionGUID = sectionGuidText

				subjects.append(newSubject)
			}
			// This updates the to-many relationships, this is also the reason why we don't include the below marking period for loop in the previous node for loop

			// Get the teachers
			// Ignores the "not-graded" html classes and we have to include the predicate on the tr element because we can't skip them by looking for links
			let teacherXPath = "//*[@id=\"contentPipe\"]/table/tr[@class!=\"classNotGraded\"]/td[2]"
			var t: [String] = []
			for teacherElement in doc.xpath(teacherXPath) {
				t.append(teacherElement.text!)
			}

			// Get the room number
			let roomXPath = "//*[@id=\"contentPipe\"]/table/tr[@class!=\"classNotGraded\"]/td[4]"
			var r: [String] = []
			for roomElement in doc.xpath(roomXPath) {
				r.append(roomElement.text!)
			}

			for index in 0 ... (subjects.count - 1) {
				subjects[index].teacher = t[index]
				subjects[index].room = r[index]
			}

			subjectContext.MR_saveOnlySelfAndWait()
			// Get the marking period information for the subjects
			for subject in subjects {
				// For each marking period for the subject, get the respective information
				for mp in subject.markingPeriods! {

					let markingPeriod = mp as! MarkingPeriod
					let markingPeriodUrl = NSURL(string: markingPeriod.htmlPage!)!

					let mpRequest = NSURLRequest(URL: markingPeriodUrl, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: 10)

					// Request the mp page
					dispatch_group_enter(updateGroup); self.timer!.entries += 1 // 2

					let getMarkingPeriodPage = self.session.dataTaskWithRequest(mpRequest) { data, response, error in
						if (error != nil) {
							self.fails.append(error!)
							dispatch_group_leave(updateGroup); self.timer!.exits += 1 // 2
						} else {

							let mpRequestMOC = NSManagedObjectContext.MR_context()
							// Get the correct marking period object
							let mP: MarkingPeriod = MarkingPeriod.MR_findFirstByAttribute("htmlPage", withValue: response!.URL!.absoluteString, inContext: mpRequestMOC)!

							// Test if we recieved valid information, if not return aka fail
							guard let mpPageHtml = Kanna.HTML(html: data!, encoding: NSUTF8StringEncoding) else {
								self.fails.append(unknownResponseError)
								dispatch_group_leave(updateGroup); self.timer!.exits += 1 // 2
								return
							}

							// After recieving the marking period's page store the data
							if let result = self.parseMarkingPeriodPage(html: mpPageHtml) {

								mP.possiblePoints = result.possiblePoints
								mP.totalPoints = result.totalPoints
								mP.percentGrade = result.percentGrade

								for assignment in result.assignments {
									let newA: Assignment = Assignment.MR_createEntityInContext(mpRequestMOC)!

									// String to Date
									let dateFormatter = NSDateFormatter()
									// http://userguide.icu-project.org/formatparse/datetime/ <- Guidelines to format date
									dateFormatter.dateFormat = "MM/dd/yy"

									if let date = assignment.date {
										newA.dateCreated = dateFormatter.dateFromString(date)
									}
									newA.name = assignment.name
									newA.totalPoints = assignment.totalPoints
									newA.possiblePoints = assignment.possiblePoints
									newA.markingPeriod = mP
								}

							} else {
								mP.empty = NSNumber(bool: true)
							}

							mpRequestMOC.MR_saveOnlySelfAndWait()
							dispatch_group_leave(updateGroup); self.timer!.exits += 1 // 2
						}
					}
					getMarkingPeriodPage.resume()
				} // Marking Period Loop
			} // Subject Loop
		} // Html Check

		// Runs when the User has been completely updated
		dispatch_group_notify(updateGroup, dispatch_get_main_queue()) {
			self.timer!.stop()
			/*
			 print("------------------------------------------------------")
			 print("Completed in: " + String(self.timer!.duration!))
			 print("Entries: " + String(self.timer!.entries) + ", Exits: " + String(self.timer!.exits))
			 print("------------------------------------------------------")
			 print("")
			 */

			guard (self.fails.isEmpty) else {
				Subject.MR_deleteAllMatchingPredicate(NSPredicate(value: true))
                NSManagedObjectContext.MR_defaultContext().MR_saveToPersistentStoreAndWait()
				self.completion(successful: false, error: self.fails.first!)
				return
			}

			// This is kind of optional, only gives more accurate dates
			let updater = RefreshLastUpdatedDates(forStudent: student)
			updater.update { _, _ in
				NSManagedObjectContext.MR_defaultContext().MR_saveToPersistentStoreAndWait()
				self.completion(successful: true, error: nil)
			}
		}
	}

	private func parseMarkingPeriodPage(html doc: HTMLDocument) -> (assignments: [(name: String?, totalPoints: String?, possiblePoints: String?, date: String?, category: String?)], totalPoints: String, possiblePoints: String, percentGrade: String)? {
		var percentGrade: String = ""
		var totalPoints: String = ""
		var possiblePoints: String = ""

		var assigntmentIndex: String
		var totalScoreIndex: String
		var possibleScoreIndex: String
		var dueDateIndex: String
		var categoryIndex: String

		// Find under which td are the headers we want under
		var headers: [String] = []
		for header: XMLElement in doc.xpath("//*[@id=\"assignments\"]/tr[1]//th") {

			let text = header.text!

			if (text == "Score") {
				headers.append("totalScore")
				headers.append("possibleScore")
			} else {
				headers.append(text)
			}
		}

		// Check if we have an empty marking period
		if (headers.count == 0) {
			return nil
		}

		assigntmentIndex = String(headers.indexOf("Assignment")! + 1)
		totalScoreIndex = String(headers.indexOf("totalScore")! + 1)
		possibleScoreIndex = String(headers.indexOf("possibleScore")! + 1)
		dueDateIndex = String(headers.indexOf("DateDue")! + 1)
		categoryIndex = String(headers.indexOf("Category")! + 1)

		// Parse all the assignments while ignoring the assignment descriptions and teacher comments
		let assignmentsXpath = "//*[@id=\"assignments\"]//tr/td[not(contains(@class, 'assignDesc')) and not(contains(@class, 'assignComments'))]/.."

		// Get all the assignment names
		var aNames: [String] = []
		for aE: XMLElement in doc.xpath(assignmentsXpath + "/td[" + assigntmentIndex + "]") {
			let text = aE.text!
			aNames.append(text)
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
		for aE: XMLElement in doc.xpath(assignmentsXpath + "/td[" + totalScoreIndex + "]") {
			var text = aE.text!
			text = text.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: kCharacterSet).invertedSet).joinWithSeparator("")
			aTotalPoints.append(text)
		}

		// Get All possible points
		var aPossiblePoints: [String] = []
		for aE: XMLElement in doc.xpath(assignmentsXpath + "/td[" + possibleScoreIndex + "]") {
			var text = aE.text!
			text = text.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "1234567890.").invertedSet).joinWithSeparator("")
			aPossiblePoints.append(text)
		}

		// Get All the dates
		var aDates: [String] = []
		for aE: XMLElement in doc.xpath(assignmentsXpath + "/td[" + dueDateIndex + "]") {
			let text = aE.text!
			aDates.append(text)
		}

		// Get all the categories
		var aCategories: [String] = []
		for aE: XMLElement in doc.xpath(assignmentsXpath + "/td[" + categoryIndex + "]") {
			let text = aE.text!
			aCategories.append(text)
		}

		// Build the assignment tuples
		var assignments: [(name: String?, totalPoints: String?, possiblePoints: String?, date: String?, category: String?)] = []
		for index in 0 ... (aNames.count - 1) {
			let newA = (aNames[safe: index], aTotalPoints[safe: index], aPossiblePoints[safe: index], aDates[safe: index], aCategories[safe: index])
			assignments.append(newA)
			// print(newA)
		}

		return (assignments, totalPoints, possiblePoints, percentGrade)
	}

}

class RefreshLastUpdatedDates {
	let student: Student
	let session = NSURLSession.sharedSession()

	init(forStudent student: Student) {
		self.student = student
	}

	// Changes the last updated on the subjects
	func update(completionHandler: (successful: Bool, error: NSError?) -> Void) {
		// Get the landing page
		let url = NSURL(string: "https://pamet-sapphire.k12system.com/CommunityWebPortal/Backpack/StudentHome.cfm?STUDENT_RID=" + student.id!)
		let request = NSURLRequest(URL: url!, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: 10)
		session.dataTaskWithRequest(request, completionHandler: { data, response, error in

			let localMOC = NSManagedObjectContext.MR_context()

			if (error != nil) {
				completionHandler(successful: false, error: error)
				return
			}

			if let doc = Kanna.HTML(html: data!, encoding: NSUTF8StringEncoding) { // BTW A PARENT ACCOUNT CAN HAVE ONLY ONE STUDENT
				// Get all the Class Names
				var namePath: String
				var datePath: String

				// Student Account
				namePath = "//*[@id=\"contentPipe\"]/div[3]/table//tr/td[2]"
				datePath = "//*[@id=\"contentPipe\"]/div[3]/table//tr/td[3]"

				var names: [String] = []
				for element in doc.xpath(namePath) {
					let text = element.text!
					names.append(text)
				}

				var dates: [String] = []
				for element in doc.xpath(datePath) {
					let text = element.text!
					dates.append(text)
				}

				// //*[@id="contentPipe"]/div[2]/table/tbody/tr[2]/td[1]
				// //*[@id="contentPipe"]/div[2]/table/tbody/tr[2]/td[1]

				if (names.count == 0 && dates.count == 0) {
					// Parent Account
					namePath = "//*[@id=\"contentPipe\"]/div[2]/table//tr/td[2]"
					datePath = "//*[@id=\"contentPipe\"]/div[2]/table//tr/td[3]"

					for element in doc.xpath(namePath) {
						let text = element.text!
						names.append(text)
					}

					for element in doc.xpath(datePath) {
						let text = element.text!
						dates.append(text)
					}
				}

				for index in 0 ... names.count - 1 {
					if let subject = Subject.MR_findFirstByAttribute("name", withValue: names[index], inContext: localMOC) {
						let dateString = dates[index]
						let dateFormatter = NSDateFormatter()
						// http://userguide.icu-project.org/formatparse/datetime/ <- Guidelines to format date
						dateFormatter.dateFormat = "MM/dd/yy"
						let date = dateFormatter.dateFromString(dateString)
						subject.lastUpdated = date
					}
				}

				localMOC.MR_saveOnlySelfAndWait()
				completionHandler(successful: true, error: nil)

			} else {
				completionHandler(successful: false, error: unknownResponseError)
			}
		}).resume()
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

