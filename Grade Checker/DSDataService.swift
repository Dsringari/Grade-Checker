 //
//  DSDataService.swift
//  Grade Checker
//
//  Created by Dhruv Sringari on 3/18/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit
import Kanna
import CoreData


class UpdateService {
	let completion: (successful: Bool, error: NSError?) -> Void
	let session = NSURLSession.sharedSession()
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	// Storing the error so we can call the completion from one spot in the class
	var result: (successful: Bool, error: NSError?)?

	let timer: ParkBenchTimer?
    

	// The class should only be used with a valid user
	init(student: Student, completionHandler completion: (successful: Bool, error: NSError?) -> Void) {
		self.completion = completion
		self.timer = ParkBenchTimer()
        
        let outDatedStudent = appDelegate.managedObjectContext.objectWithID(student.objectID) as! Student
		
        // Courses & Grades Page Request
        let backpackUrl = NSURL(string: "https://pamet-sapphire.k12system.com/CommunityWebPortal/Backpack/StudentClasses.cfm?STUDENT_RID=" + outDatedStudent.id!)!
        let coursesPageRequest = NSMutableURLRequest(URL: backpackUrl, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: 10)
        coursesPageRequest.HTTPMethod = "GET"
        
        let getCoursePage = self.session.dataTaskWithRequest(coursesPageRequest) { data, response, error in
            
            if (error != nil) {
                self.result = (false, error)
                return
            } else {
                
                if let html = NSString(data: data!, encoding: NSASCIIStringEncoding) {
                    self.createSubjects(coursesAndGradePageHtml: html as String, student: outDatedStudent)
                } else {
                    self.result = (false, unknownResponseError)
                }
            }
        }
        getCoursePage.resume()
	}
    
	// Adds the subjects to the user when the correct page is given
    // MAY BE CALLED FROM NON_MAIN THREAD
	private func createSubjects(coursesAndGradePageHtml html: String, student: Student) {
        let updateGroup = dispatch_group_create()
		let backgroundMOC = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        backgroundMOC.parentContext = self.appDelegate.managedObjectContext
		let updatingStudent = backgroundMOC.objectWithID(student.objectID) as! Student

		if let doc = Kanna.HTML(html: html, encoding: NSASCIIStringEncoding) {

			let xpath = "//*[@id=\"contentPipe\"]/table//tr[@class!=\"classNotGraded\"]//td/a" // finds all the links on the visable table NOTE: DO NOT INCLUDE /tbody FOR SIMPLE TABLES WITHOUT A HEADER AND FOOTER

			let nodes = doc.xpath(xpath)

			// FIXME: If the parsing failed we have to return an error, make a proper error, and use it with self.result
			if (nodes.count == 0) {
				self.result = (false, unknownResponseError)
				return
			}

			// Store the subject's url into a subject object and get the name
			var subjects: [Subject] = []
			for node: XMLElement in nodes {
				// insert the subject into core data
				let newSubject: Subject = NSEntityDescription.insertNewObjectForEntityForName("Subject", inManagedObjectContext: backgroundMOC) as! Subject
				// set properties
				newSubject.student = updatingStudent
				let subjectAddress = node["href"]!
				newSubject.htmlPage = "https://pamet-sapphire.k12system.com" + subjectAddress // The node link includes a / before the page link so we leave the normal / off
				newSubject.name = node.text!.substringToIndex(node.text!.endIndex.predecessor()) // Remove the space after the name

				// Get the course

				// Because the marking period html pages' urls repeat themselves we can use a shortcut
				// There are only 4 marking periods

				// We have to isolate the section guide query paramter from the url because StudentClassPage.cfm changes to StudentClassGrades.cfm
				let sectionGuidText = subjectAddress.componentsSeparatedByString("&")[1]
				for index in 1 ... 4 {
					// Create 4 marking periods
					let newMP: MarkingPeriod = NSEntityDescription.insertNewObjectForEntityForName("MarkingPeriod", inManagedObjectContext: backgroundMOC) as! MarkingPeriod
					// Add the marking periods to the subject
					newMP.subject = newSubject
					newMP.number = String(index)
					newMP.htmlPage = "https://pamet-sapphire.k12system.com/CommunityWebPortal/Backpack/StudentClassGrades.cfm?STUDENT_RID=" + updatingStudent.id! + "&" + sectionGuidText + "&MP_CODE=" + newMP.number!
					newMP.empty = NSNumber(bool: false)
				}
				// save for later
				subjects.append(newSubject)
			}

			// Get the teachers
			// Ignores the not-graded classes, we have to include the predicate on the tr element because we can't skip them by looking for links
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

			
			// This updates the to-many relationships, this is also the reason why we don't include the below marking period for loop in the previous node for loop
            backgroundMOC.refreshAllObjects()
			// Get the marking period information for the subjects
			for subject in subjects {
				// For each marking period for the subject, get the respective information
				for mp in subject.markingPeriods! {
					
					let markingPeriod = mp as! MarkingPeriod
					let markingPeriodUrl = NSURL(string: markingPeriod.htmlPage!)!

					backgroundMOC.saveContext()

					let mpRequest = NSURLRequest(URL: markingPeriodUrl, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: 1000) // FIXME: RETURN TO NORMAL

					// Request the mp page
                    dispatch_group_enter(updateGroup); self.timer!.entries += 1 // 2
                    
					let getMarkingPeriodPage = self.session.dataTaskWithRequest(mpRequest) { data, response, error in
						if (error != nil) {
							self.result = (false, error!)
							dispatch_group_leave(updateGroup); self.timer!.exits += 1 // 2
						} else {

							// Get the correct marking period object
							let mP: MarkingPeriod = backgroundMOC.getObjectsFromStore("MarkingPeriod", predicateString: "htmlPage == %@", args: [response!.URL!.absoluteString])[0] as! MarkingPeriod

							// Test if we recieved valid information, if not return aka fail
							guard let mpPageHtml = Kanna.HTML(html: data!, encoding: NSUTF8StringEncoding) else {
								self.result = (false, unknownResponseError)
								dispatch_group_leave(updateGroup); self.timer!.exits += 1 // 2
								return
							}

							// After recieving the marking period's page store the data
							if let result = self.parseMarkingPeriodPage(html: mpPageHtml) {

								mP.possiblePoints = result.possiblePoints
								mP.totalPoints = result.totalPoints
								mP.percentGrade = result.percentGrade

								for assignment in result.assignments {
									let newA = NSEntityDescription.insertNewObjectForEntityForName("Assignment", inManagedObjectContext: backgroundMOC) as! Assignment
									newA.name = assignment.name
									newA.totalPoints = assignment.totalPoints
									newA.possiblePoints = assignment.possiblePoints
									newA.markingPeriod = mP

									// String to Date
									let dateFormatter = NSDateFormatter()
									// http://userguide.icu-project.org/formatparse/datetime/ <- Guidelines to format date
									dateFormatter.dateFormat = "MM/dd/yy"
									let date = dateFormatter.dateFromString(assignment.date)
									newA.date = date!
								}
                                
								backgroundMOC.saveContext()
							} else {
								mP.empty = NSNumber(bool: true)
							}

							backgroundMOC.saveContext()

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
            print("------------------------------------------------------")
            print("Completed in: " + String(self.timer!.duration!))
            print("Entries: " + String(self.timer!.entries) + ", Exits: " + String(self.timer!.exits))
            print("------------------------------------------------------")
            print("")
            self.appDelegate.managedObjectContext.saveContext()
            self.completion(successful: true, error: nil)
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

