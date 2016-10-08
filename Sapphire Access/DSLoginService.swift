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
import MagicalRecord

class LoginService {
	var user: User
	let appDelegate = UIApplication.shared.delegate as! AppDelegate
	let completion: (_ successful: Bool, _ error: NSError?) -> Void

	init(loginUserWithID userID: NSManagedObjectID, completionHandler completion: @escaping (_ successful: Bool, _ error: NSError?) -> Void) {
		user = NSManagedObjectContext.mr_default().object(with: userID) as! User
		self.completion = completion
		login()
	}
    
    // refreshes a logged in user
    @discardableResult
    init(refreshUserWithID userID: NSManagedObjectID, completion: @escaping (_ successful: Bool, _ error: NSError?) -> Void) {
        user = NSManagedObjectContext.mr_default().object(with: userID) as! User
        self.completion = completion
        
        let session = URLSession.shared
        let headers = [
            "content-type": "application/x-www-form-urlencoded"
        ]
        
        let postString = "javascript=true&j_username=" + self.user.username! + "&j_password=" + self.user.password! + "&j_pin=" + self.user.pin!
        let postData = NSData(data: postString.data(using: String.Encoding.utf8)!) as Data
        
        let request = NSMutableURLRequest(url: URL(string: "https://pamet-sapphire.k12system.com/CommunityWebPortal/Welcome.cfm")!,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = postData
        
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                self.completion(false, error as NSError?)
                return
            } else {
                self.completion(true, nil)
            }
        })
        
        dataTask.resume()
    }

	func login() {
		// Logout First to avoid problems with logging in with the parent account and then a student account
		logout { failed, error in
			if (failed) {
				self.completion(false, error)
				return
			}
			let session = URLSession.shared
			let headers = [
				"content-type": "application/x-www-form-urlencoded"
			]

			let postString = "javascript=true&j_username=" + self.user.username! + "&j_password=" + self.user.password! + "&j_pin=" + self.user.pin!
			let postData = NSData(data: postString.data(using: String.Encoding.utf8)!) as Data

			let request = NSMutableURLRequest(url: URL(string: "https://pamet-sapphire.k12system.com/CommunityWebPortal/Welcome.cfm")!,
				cachePolicy: .useProtocolCachePolicy,
				timeoutInterval: 10)
			request.httpMethod = "POST"
			request.allHTTPHeaderFields = headers
			request.httpBody = postData

			let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
				if (error != nil) {
					self.completion(false, error as NSError?)
					return
				} else {
					self.getMainPageHtml()
				}
			})

			dataTask.resume()
		}
	}

	func logout(_ completionHandler: @escaping (_ failed: Bool, _ error: NSError?) -> Void) {
		let session = URLSession.shared
		let request = URLRequest(url: URL(string: "https://pamet-sapphire.k12system.com/CommunityWebPortal/Welcome.cfm?logout=1")!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10)

		let logoutTask = session.dataTask(with: request, completionHandler: { data, response, error in
			if (error != nil) {
				completionHandler(true, error as NSError?)
				return
			}
			completionHandler(false, nil)
		})
		logoutTask.resume()
	}

	// Because of sapphire's strange cookie detection, we have to make a seperate request for the main page. Depending on the title of the page, we can determine whether the user has inputed the correct credentials.

	fileprivate func getMainPageHtml() {

		let request = NSMutableURLRequest(url: URL(string: "https://pamet-sapphire.k12system.com/CommunityWebPortal/Welcome.cfm")!,
			cachePolicy: .useProtocolCachePolicy,
			timeoutInterval: 10)
		request.httpMethod = "GET"

		let session = URLSession.shared
		let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
			if (error != nil) {
				self.completion(false, error as NSError?)
			} else {
				if let html: String = NSString(data: data!, encoding: String.Encoding.utf8.rawValue) as? String {

					if let doc = Kanna.HTML(html: html, encoding: String.Encoding.utf8) {

						switch (doc.title!) {
							// This user is a student account so it has one student.
						case " Student Backpack - Sapphire Community Web Portal ":
							// Retrieve student information from backpack screen
							
							let i: String = doc.xpath("//*[@id=\"leftPipe\"]/ul[2]/li[4]/a")[0]["href"]! 
							let id = i.components(separatedBy: "=")[1]
                            var student = Student.mr_findFirst(byAttribute: "id", withValue: id, in: NSManagedObjectContext.mr_default())
                            if student == nil {
                                student = Student.mr_createEntity(in: NSManagedObjectContext.mr_default())
                            }
							let name: String = doc.xpath("//*[@id=\"leftPipe\"]/ul[1]/li/a")[0]["title"]!
							let g: String = doc.xpath("//*[@id=\"leftPipe\"]/ul[1]/li/div[1]")[0]["title"]!
							let grade = g.components(separatedBy: CharacterSet(charactersIn: "1234567890").inverted).joined(separator: "")
							let school: String = doc.xpath("//*[@id=\"leftPipe\"]/ul[1]/li/div[2]")[0]["title"]!

							student?.id = id
							student?.name = name
							student?.grade = grade
							student?.school = school
							student?.user = self.user
							NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait()
                            self.completion(true, nil)
							// This user is a parent
						case " Welcome - Sapphire Community Web Portal ":
                            
                            // Clear Old Students
                            // Todo: Stop Deleting Entities

							var ids: [String] = []
							var names: [String] = []
                            var students: [Student] = []
							for e in doc.xpath("//*[@id=\"leftPipe\"]/ul//li/a") {
								var id = e["href"]!
                                id = id.components(separatedBy: "=")[1]
                                if let oldStudent = Student.mr_findFirst(byAttribute: "id", withValue: id, in: NSManagedObjectContext.mr_default()) {
                                    students.append(oldStudent)
                                } else {
                                    if let newStudent = Student.mr_createEntity(in: NSManagedObjectContext.mr_default()) {
                                        students.append(newStudent)
                                    }
                                }
								let name = e["title"]!
								ids.append(id)
								names.append(name)
							}

							var grades: [String] = []
							for e in doc.xpath("//*[@id=\"leftPipe\"]/ul//li/div[1]") {
								let g = e["title"]!
                                let grade = g.components(separatedBy: CharacterSet(charactersIn: "1234567890").inverted).joined(separator: "")
								grades.append(grade)
							}

							var schools: [String] = []
							for e in doc.xpath("//*[@id=\"leftPipe\"]/ul//li/div[2]") {
								let school = e["title"]!
								schools.append(school)
							}

							for index in 0 ..< ids.count {
								students[index].id = ids[index]
								students[index].name = names[index]
								students[index].grade = grades[index]
								students[index].school = schools[index]
								students[index].user = self.user
							}
							NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait()
							self.completion(true, nil)
                        // Failed to Login
						default:
							self.completion(false, badLoginError)
						}
					} else {
						self.completion(false, unknownResponseError)
					}
				} else {
					self.completion(false, unknownResponseError)
				}
			}
		})

		dataTask.resume()
	}
}
