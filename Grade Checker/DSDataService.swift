//
//  DSDataService.swift
//  Grade Checker
//
//  Created by Dhruv Sringari on 3/18/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import Foundation
import Kanna
import CoreData

class UpdateService {
	var user: User
	let completion: (successful: Bool, error: NSError?, user: User?) -> Void
	let updateGroup = dispatch_group_create()
    let session = NSURLSession.sharedSession()
    // Storing the error so we can call the completion from one spot in the class
    var result: (successful: Bool,error: NSError?)?

    // The class should only be used with a valid user
	init(legitamateUser user: User, completionHandler completion: (successful: Bool, error: NSError?, user: User?) -> Void) {
		self.user = user
		self.completion = completion
		self.updateUserInfo()
	}

	private func updateUserInfo() {

		// Courses & Grades Page Request
        let backpackUrl = NSURL(string: "https://pamet-sapphire.k12system.com/CommunityWebPortal/Backpack/StudentClasses.cfm?STUDENT_RID=" + user.id!)!
		let coursesPageRequest = NSMutableURLRequest(URL: backpackUrl, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: 10)
		coursesPageRequest.HTTPMethod = "GET"

		dispatch_group_enter(self.updateGroup)
		let getCoursePage = self.session.dataTaskWithRequest(coursesPageRequest) { data, response, error in

			if (error != nil) {
				self.result = (false, error)
                dispatch_group_leave(self.updateGroup)
                return
			} else {
                
                if let html = NSString(data: data!, encoding: NSASCIIStringEncoding)  {
                    dispatch_group_enter(self.updateGroup)
                    self.createSubjects(coursesAndGradePageHtml: html as String, user: self.user)
                    dispatch_group_leave(self.updateGroup)
                } else {
                    self.result = (false, unknownResponseError)
                }
                
			}
			dispatch_group_leave(self.updateGroup)
		}
		getCoursePage.resume()

		// Runs when the User has been completely updated
		dispatch_group_notify(updateGroup, dispatch_get_main_queue()) {
            print("im done")
		}
	}
    
    // TODO: Make sure to leave the update group when the user has updated sujects
    // Adds the subjects to the user when the correct page is given
    private func createSubjects(coursesAndGradePageHtml html: String, user oldUser: User) {
        let moc = DataController().managedObjectContext
        let user = moc.objectWithID(oldUser.objectID) as! User
        
		if let doc = Kanna.HTML(html: html, encoding: NSASCIIStringEncoding) {
            
            let xpath = "//*[@id=\"contentPipe\"]/table//tr[@class!=\"classNotGraded\"]//td/a" // finds all the links on the visable table NOTE: DO NOT INCLUDE /tbody FOR SIMPLE TABLES WITHOUT A HEADER AND FOOTER
            
            let nodes = doc.xpath(xpath)
            
            // FIXME: If the parsing failed we have to return an error, make a proper error, and use it with self.result
            if (nodes.count == 0) {
                self.result = (false,unknownResponseError)
                return
            }
            
            // Store the subject's url into a subject object and get the name
            var subjects: [Subject] = []
            for node: XMLElement in nodes {
                // insert the subject into core data
                let newSubject: Subject = NSEntityDescription.insertNewObjectForEntityForName("Subject", inManagedObjectContext: moc) as! Subject
                // set properties
                newSubject.user = user
                let subjectAddress = node["href"]!
                newSubject.htmlPage = "https://pamet-sapphire.k12system.com" + subjectAddress // The node link includes a / before the page link so we leave the normal / off
                newSubject.name = node.text!
                
                // Get the course
                
                // Because the marking period html pages' urls repeat themselves we can use a shortcut
                // There are only 4 marking periods
                
                // We have to isolate the section guide query paramter from the url because StudentClassPage.cfm changes to StudentClassGrades.cfm
                let sectionGuidText = subjectAddress.componentsSeparatedByString("&")[1]
                for index in 1...4 {
                    // Create 4 marking periods
                    let newMP: MarkingPeriod = NSEntityDescription.insertNewObjectForEntityForName("MarkingPeriod", inManagedObjectContext: moc) as! MarkingPeriod
                    // Add the marking periods to the subject
                    newMP.subject = newSubject
                    newMP.number = String(index)
                    newMP.htmlPage = "https://pamet-sapphire.k12system.com/CommunityWebPortal/Backpack/StudentClassGrades.cfm?STUDENT_RID=" + user.id! + "&" + sectionGuidText + "&MP_CODE=" + newMP.number!
                }
                // save for later
                subjects.append(newSubject)
            }
            
            // TODO: Get the teachers
            
            do {
                try moc.save()
            } catch {
                print("\nMOC FAILED TO SAVE!\n")
                abort()
            }
            // This updates the to-many relationships, this is also the reason why we don't include the below marking period for loop in the previous node for loop
            moc.refreshAllObjects()
            
            // Get the marking period information for the subjects
            for subject in subjects {
                // For each marking period for the subject, get the respective information
                for mp in subject.markingPeriods! {
                    let markingPeriod = mp as! MarkingPeriod
                    let markingPeriodUrl = NSURL(string: markingPeriod.htmlPage!)!
                    
                   // print("Current Marking Period Html Page: " + markingPeriod.htmlPage! + "\n")
                    
                    let mpRequest = NSURLRequest(URL: markingPeriodUrl, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: 10)
                    
                    // Request the mp page
                    dispatch_group_enter(self.updateGroup)
                    let _ = self.session.dataTaskWithRequest(mpRequest) { data, response, error in
                        if (error != nil) {
                            self.result = (false, error!)
                            dispatch_group_leave(self.updateGroup)
                        } else {
                            
                            // Test if we recieved valid information, if not return aka fail
                            guard let mpPageHtml = Kanna.HTML(html: data!, encoding: NSUTF8StringEncoding) else {
                                self.result = (false, unknownResponseError)
                                return
                            }
                            
                            // After recieving the marking period's page store the data
                            let result = self.parseMarkingPeriodPage(html: mpPageHtml)
                            if result != nil {
                                let formatter = NSNumberFormatter()
                                formatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
                                markingPeriod.possiblePoints = formatter.numberFromString(result!.possiblePoints)
                                markingPeriod.totalPoints = formatter.numberFromString(result!.totalPoints)
                                markingPeriod.percentGrade = result!.percentGrade
                                
                                var assignments: [Assignment] = []
                                for assignment in result!.assignments {
                                    let newA = NSEntityDescription.insertNewObjectForEntityForName("Assignment", inManagedObjectContext: moc) as! Assignment
                                    newA.name = assignment.name
                                    newA.totalPoints = formatter.numberFromString(assignment.totalPoints)
                                    newA.possiblePoints = formatter.numberFromString(assignment.possiblePoints)
                                    newA.markingPeriod = markingPeriod
                                    assignments.append(newA)
                                }
                                
                                do {
                                    try moc.save()
                                } catch {
                                    abort()
                                }
                                
                            } else {
                                markingPeriod.empty = NSNumber(bool: true)
                            }
                            dispatch_group_leave(self.updateGroup)
                        }
                        
                    }.resume()
                }
                do {
                    try moc.save()
                } catch {
                    print("FAILED TO SAVE")
                    abort()
                }
            }
            
        }
	}

    private func parseMarkingPeriodPage(html doc: HTMLDocument) -> (assignments: [(name: String, totalPoints: String, possiblePoints: String)], totalPoints: String, possiblePoints: String, percentGrade: String)? {
        var percentGrade: String = ""
        var totalPoints: String = ""
        var possiblePoints: String = ""
        
        // Parse percent grade
        let percentageTextXpath = "//*[@id=\"assignmentFinalGrade\"]/b[1]/following-sibling::text()"
        let pointsTextXpath = "//*[@id=\"assignmentFinalGrade\"]/b[2]/following-sibling::text()"
        
        if let percentageTextElement = doc.at_xpath(percentageTextXpath) {
            // Check for only a percent symbol, if so the marking period is empty
            var text = percentageTextElement.text!
            // Remove all the spaces and other characters
            text = text.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "123456790.%").invertedSet).joinWithSeparator("")
            if (text == "%") {
                return nil
            }
            percentGrade = text
        } else {
            print("Failed to find percentageTextElement!")
            return nil
        }
        
        // Parse total points
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
        
        // Parse all the assignments while ignoring the assignment descriptions
        let assignmentsXpath = "//*[@id=\"assignments\"]/tr[count(td)=6]"
        
        // Get all the assignment names
        var aNames: [String] = []
        for aE: XMLElement in doc.xpath(assignmentsXpath + "/td[1]") {
            aNames.append(aE.text!)
        }
        
        // Get all total points
        var aTotalPoints: [String] = []
        for aE: XMLElement in doc.xpath(assignmentsXpath + "/td[2]") {
            var text = aE.text!
            text = text.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "1234567890.").invertedSet).joinWithSeparator("")
            aTotalPoints.append(text)
        }
        
        // Get All possible points
        var aPossiblePoints: [String] = []
        for aE: XMLElement in doc.xpath(assignmentsXpath + "/td[3]") {
            var text = aE.text!
            text = text.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "1234567890.").invertedSet).joinWithSeparator("")
            aPossiblePoints.append(text)
        }
        
        // Build the assignment tuples
        var assignments: [(name: String, totalPoints: String, possiblePoints: String)] = []
        for index in 0...(aNames.count - 1) {
            let newA = (aNames[index],aTotalPoints[index],aPossiblePoints[index])
            assignments.append(newA)
            print(newA)
        }
            
        
        return (assignments, totalPoints, possiblePoints, percentGrade)
    }

}




