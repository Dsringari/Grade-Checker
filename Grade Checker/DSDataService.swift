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
        print(backpackUrl)
		let coursesPageRequest = NSMutableURLRequest(URL: backpackUrl, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: 10)
		coursesPageRequest.HTTPMethod = "GET"

		dispatch_group_enter(self.updateGroup)
		let getCoursePage = session.dataTaskWithRequest(coursesPageRequest) { data, response, error in

			if (error != nil) {
				self.result = (false, error)
			} else {
                
                if let html = NSString(data: data!, encoding: NSASCIIStringEncoding)  {
                    dispatch_group_enter(self.updateGroup)
                    self.updateSubjects(coursesAndGradePageHtml: html as String)
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
	private func updateSubjects(coursesAndGradePageHtml html: String) {
        
		if let doc = Kanna.HTML(html: html, encoding: NSASCIIStringEncoding) {
            
            let xpath = "//*[@id=\"contentPipe\"]/table//tr[@class!=\"classNotGraded\"]//td/a" // finds all the links on the visable table NOTE: DO NOT INCLUDE /tbody FOR SIMPLE TABLES WITHOUT A HEADER AND FOOTER
            
            let nodes = doc.xpath(xpath)
            
            for node: XMLElement in nodes {
                    print(node.toHTML!)
                
                   // print(node.text!)
                    //print(node["href"]!)
            }
            
        } else {
            self.result = (false,unknownResponseError)
        }
	}
}
