//
//  DSDataService.swift
//  Grade Checker
//
//  Created by Dhruv Sringari on 3/18/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import Foundation
import Kanna

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
		let coursesPageRequest = NSMutableURLRequest(URL: NSURL(string: "https://pamet-sapphire.k12system.com/CommunityWebPortal/Backpack/StudentClasses.cfm?STUDENT_RID=" + user.id!)!, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: 10)
		coursesPageRequest.HTTPMethod = "GET"

		dispatch_group_enter(self.updateGroup)
		let getCoursePage = session.dataTaskWithRequest(coursesPageRequest) { data, response, error in

			if (error != nil) {
				self.result = (false, error)
			} else {
				if let html = NSString(data: data!, encoding: NSUTF8StringEncoding) {
					dispatch_group_enter(self.updateGroup)
					self.updateSubjects(coursesAndGradePageHtml: html as String)
					dispatch_group_leave(self.updateGroup)
				}
			}
			dispatch_group_leave(self.updateGroup)
		}
		getCoursePage.resume()

		// Runs when the User has been completely updated
		dispatch_group_notify(updateGroup, dispatch_get_main_queue()) {
		}
	}

	private func updateSubjects(coursesAndGradePageHtml html: String) {
		if let doc = Kanna.HTML(html: html, encoding: NSUTF8StringEncoding) {
            let table = doc.xpath("//*[@id=\"contentPipe\"]/table/tbody") ////*[@id="contentPipe"]/table/tbody/tr[3]/td[2]
            for row in table {
                if (row["class"] != "classNotGraded") {
                    var subject = Subject()
                }
            }
        } else {
            self.result = (false,unknownResponseError)
        }
	}
}
