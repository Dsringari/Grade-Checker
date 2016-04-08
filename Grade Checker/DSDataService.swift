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
	let user: User
	let completion: (successful: Bool, error: NSError?, user: User?) -> Void
	let updateGroup = dispatch_group_create()
    // Storing the error so we can call the completion from one spot in the class
    var result: (successful: Bool,error: NSError?)?

    // The class should only be used with a valid user
	init(legitamateUser user: User, completionHandler completion: (successful: Bool, error: NSError?, user: User?) -> Void) {
		self.user = user
		self.completion = completion
		self.updateUserInfo()
	}

	private func updateUserInfo() {
		let session = NSURLSession.sharedSession()

		// Courses & Grades Page Request
        let backpackUrl = NSURL(string: "https://pamet-sapphire.k12system.com/CommunityWebPortal/Backpack/StudentClasses.cfm?STUDENT_RID=" + user.id!)!
		let coursesPageRequest = NSMutableURLRequest(URL: backpackUrl, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: 10)
		coursesPageRequest.HTTPMethod = "GET"

		dispatch_group_enter(self.updateGroup)
		let getCoursePage = session.dataTaskWithRequest(coursesPageRequest) { data, response, error in

			if (error != nil) {
				self.result = (false, error)
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
		}
	}
    
    // TODO: Make sure to leave the update group when the user has updated sujects
    // Adds the subjects to the user when the correct page is given
    private func createSubjects(coursesAndGradePageHtml html: String, user: User) {
        let moc = DataController().managedObjectContext
        
		if let doc = Kanna.HTML(html: html, encoding: NSASCIIStringEncoding) {
            
            let xpath = "//*[@id=\"contentPipe\"]/table//tr[@class!=\"classNotGraded\"]//td/a" // finds all the links on the visable table NOTE: DO NOT INCLUDE /tbody FOR SIMPLE TABLES WITHOUT A HEADER AND FOOTER
            
            let nodes = doc.xpath(xpath)
            
            // FIXME: If the parsing failed we have to return an error, make a proper error, and use it with self.result
            if (nodes.count == 0) {
                self.result = (false,unknownResponseError)
                return
            }
            
            // Store the subject's url into a subject
            var subjects: [Subject] = []
            for node: XMLElement in nodes {
                // insert the subject into core data
                let newSubject: Subject = NSEntityDescription.insertNewObjectForEntityForName("Subject", inManagedObjectContext: moc) as! Subject
                // set properties
                newSubject.user = user
                newSubject.htmlPage = "https://pamet-sapphire.k12system.com/" + node["href"]!
                
                // Because the marking period html pages' urls repeat themselves we can use a shortcut
                // There are only 4 marking periods
                for index in 1...4 {
                    // Create 4 marking periods
                    let newMP: MarkingPeriod = NSEntityDescription.insertNewObjectForEntityForName("MarkingPeriod", inManagedObjectContext: moc) as! MarkingPeriod
                    // Add the marking periods to the subject
                    newMP.subject = newSubject
                    newMP.number = String(index)
                    newMP.htmlPage = newSubject.htmlPage! + "&MP_CODE=" + newMP.number!
                }
                // save for later
                subjects.append(newSubject)
            }
            
            // Get all the information for the subject from their respective pages
            for subject in subjects {
                let requestUrl = NSURL(string: subject.htmlPage!)!
                let request = NSMutableURLRequest(URL: requestUrl, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: 10)
                request.HTTPMethod = "GET"
                
                let session = NSURLSession.sharedSession()
                dispatch_group_enter(self.updateGroup)
                let _ = session.dataTaskWithRequest(request) { data ,response , error in
                    if (error != nil) {
                        self.result = (false, error)
                        // FIXME: Find better error handling / validate error
                        // If we failed to load we don't want to save the subject
                        moc.deleteObject(subject)
                        subjects.removeObject(subject)
                    } else {
                        if let html = NSString(data: data!, encoding: NSASCIIStringEncoding) {
                            // TODO: start to parse the subject here
                            self.parseSubjectPage(subjectToBeUpdated: subject, subjectMainPageHtml: html as String)
                        } else {
                            // TODO: Failed
                            self.result = (false, unknownResponseError)
                        }
                    }
                    dispatch_group_leave(self.updateGroup)
                }.resume()
            }
            
        } else {
            self.result = (false,unknownResponseError)
        }
	}
    
    
    private func parseSubjectPage(subjectToBeUpdated subject: Subject, subjectMainPageHtml html: String) {
        if let doc = Kanna.HTML(html: html, encoding: NSASCIIStringEncoding) {
            // The first step is to
            
        } else {
            self.result = (false, unknownResponseError)
        }
    }
}


