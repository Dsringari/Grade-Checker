//
//  DSLoginService.swift
//  Grade Checker
//
//  Created by Dhruv Sringari on 3/10/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import Foundation
import Kanna
import CoreData

class LoginService {
	var user: User
	let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
	let completion: (successful: Bool, error: NSError?, user: User?) -> Void

	init(userToBeLoggedIn: User, completionHandler completion: (successful: Bool, error: NSError?, user: User?) -> Void) {
		user = userToBeLoggedIn
		self.completion = completion
		login()
	}
    
    // refreshes a logged in user
    init(refreshUser: User, completion: (successful: Bool, error: NSError?, user: User?) -> Void) {
        self.user = refreshUser
        self.completion = completion
        
        let session = NSURLSession.sharedSession()
        let headers = [
            "content-type": "application/x-www-form-urlencoded"
        ]
        
        let postString = "javascript=true&j_username=" + self.user.username! + "&j_password=" + self.user.password! + "&j_pin=" + self.user.pin!
        let postData = NSMutableData(data: postString.dataUsingEncoding(NSUTF8StringEncoding)!)
        
        let request = NSMutableURLRequest(URL: NSURL(string: "https://pamet-sapphire.k12system.com/CommunityWebPortal/Welcome.cfm")!,
                                          cachePolicy: .UseProtocolCachePolicy,
                                          timeoutInterval: 10)
        request.HTTPMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.HTTPBody = postData
        
        let dataTask = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                print(error)
                self.completion(successful: false, error: error, user: nil)
                return
            } else {
                self.completion(successful: true, error: nil, user: nil)
            }
        })
        
        dataTask.resume()
    }

	func login() {
		// Logout First to avoid problems with logging in with the parent account and then a student account
		logout { failed, error in
			if (failed) {
				self.completion(successful: false, error: error, user: nil)
				return
			}
            print("Logout Successful")
			let session = NSURLSession.sharedSession()
			let headers = [
				"content-type": "application/x-www-form-urlencoded"
			]

			let postString = "javascript=true&j_username=" + self.user.username! + "&j_password=" + self.user.password! + "&j_pin=" + self.user.pin!
			let postData = NSMutableData(data: postString.dataUsingEncoding(NSUTF8StringEncoding)!)

			let request = NSMutableURLRequest(URL: NSURL(string: "https://pamet-sapphire.k12system.com/CommunityWebPortal/Welcome.cfm")!,
				cachePolicy: .UseProtocolCachePolicy,
				timeoutInterval: 10)
			request.HTTPMethod = "POST"
			request.allHTTPHeaderFields = headers
			request.HTTPBody = postData

			let dataTask = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
				if (error != nil) {
					print(error)
					self.completion(successful: false, error: error, user: nil)
					return
				} else {
					self.getMainPageHtml()
				}
			})

			dataTask.resume()
		}
	}

	func logout(completionHandler: (failed: Bool, error: NSError?) -> Void) {
		let session = NSURLSession.sharedSession()
		let request = NSURLRequest(URL: NSURL(string: "https://pamet-sapphire.k12system.com/CommunityWebPortal/Welcome.cfm?logout=1")!, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: 1)

		let logoutTask = session.dataTaskWithRequest(request, completionHandler: { data, response, error in
			if (error != nil) {
				completionHandler(failed: true, error: error)
				return
			}
			completionHandler(failed: false, error: nil)
		})
		logoutTask.resume()
	}

	// Because of sapphire's strange cookie detection, we have to make a seperate request for the main page. Depending on the title of the page, we can determine whether the user has inputed the correct credentials.

	private func getMainPageHtml() {

		let request = NSMutableURLRequest(URL: NSURL(string: "https://pamet-sapphire.k12system.com/CommunityWebPortal/Welcome.cfm")!,
			cachePolicy: .UseProtocolCachePolicy,
			timeoutInterval: 10.0)
		request.HTTPMethod = "GET"

		let session = NSURLSession.sharedSession()
		let temporaryContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
		temporaryContext.parentContext = appDelegate.managedObjectContext
		let dataTask = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
			if (error != nil) {
				print(error)
				print(error!.userInfo[NSLocalizedRecoverySuggestionErrorKey])
				self.completion(successful: false, error: error, user: nil)
			} else {
				if let html: String = NSString(data: data!, encoding: NSUTF8StringEncoding) as? String {

					if let doc = Kanna.HTML(html: html, encoding: NSUTF8StringEncoding) {

						switch (doc.title!) {
							// This user is a student account so it has one student.
						case " Student Backpack - Sapphire Community Web Portal ":
							let user = temporaryContext.objectWithID(self.user.objectID) as! User

							// Retrieve student information from backpack screen
							let student = NSEntityDescription.insertNewObjectForEntityForName("Student", inManagedObjectContext: temporaryContext) as! Student
							let i: String = doc.xpath("//*[@id=\"leftPipe\"]/ul[2]/li[4]/a")[0]["href"]!
							let id = i.componentsSeparatedByString("=")[1]
							let name: String = doc.xpath("//*[@id=\"leftPipe\"]/ul[1]/li/a")[0]["title"]!
							let g: String = doc.xpath("//*[@id=\"leftPipe\"]/ul[1]/li/div[1]")[0]["title"]!
							let grade = g.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "1234567890").invertedSet).joinWithSeparator("")
							let school: String = doc.xpath("//*[@id=\"leftPipe\"]/ul[1]/li/div[2]")[0]["title"]!

							student.id = id
							student.name = name
							student.grade = grade
							student.school = school
							student.user = user
							temporaryContext.saveContext()
							self.completion(successful: true, error: nil, user: user)
							// This user is a parent
						case " Welcome - Sapphire Community Web Portal ":
							let user = temporaryContext.objectWithID(self.user.objectID) as! User

							var ids: [String] = []
							var names: [String] = []
							for e in doc.xpath("//*[@id=\"leftPipe\"]/ul//li/a") {
								let i = e["href"]!
								let id = i.componentsSeparatedByString("=")[1]
								let name = e["title"]!
								ids.append(id)
								names.append(name)
							}

							var grades: [String] = []
							for e in doc.xpath("//*[@id=\"leftPipe\"]/ul//li/div[1]") {
								let g = e["title"]!
								let grade = g.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "1234567890").invertedSet).joinWithSeparator("")
								grades.append(grade)
							}

							var schools: [String] = []
							for e in doc.xpath("//*[@id=\"leftPipe\"]/ul//li/div[2]") {
								let school = e["title"]!
								schools.append(school)
							}

							for index in 0 ... (ids.count - 1) {
								let student = NSEntityDescription.insertNewObjectForEntityForName("Student", inManagedObjectContext: temporaryContext) as! Student
								student.id = ids[index]
								student.name = names[index]
								student.grade = grades[index]
								student.school = schools[index]
								student.user = user
							}
							temporaryContext.saveContext()
							self.completion(successful: true, error: nil, user: user)
                        // Failed to Login
						default:
							self.completion(successful: false, error: badLoginError, user: nil)
						}
					} else {
						self.completion(successful: false, error: unknownResponseError, user: nil)
					}
				} else {
					self.completion(successful: false, error: unknownResponseError, user: nil)
				}
			}
		})

		dataTask.resume()
	}
}