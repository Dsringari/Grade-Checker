//
//  DSLoginService.swift
//  Grade Checker
//
//  Created by Dhruv Sringari on 3/10/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import Foundation
import Kanna

class LoginService {
	var user: User
	let completion: (successful: Bool, error: NSError?, user: User?) -> Void

	init(userToBeLoggedIn: User, completionHandler completion: (successful: Bool, error: NSError?, user: User?) -> Void) {
		user = userToBeLoggedIn
		self.completion = completion
		login()
	}

	func login() {

		let headers = [
			"content-type": "application/x-www-form-urlencoded"
		]

		let postString = "javascript=true&j_username=" + user.username + "&j_password=" + user.password + "&j_pin=" + user.pin
		let postData = NSMutableData(data: postString.dataUsingEncoding(NSUTF8StringEncoding)!)

		let request = NSMutableURLRequest(URL: NSURL(string: "https://pamet-sapphire.k12system.com/CommunityWebPortal/Welcome.cfm")!,
			cachePolicy: .UseProtocolCachePolicy,
			timeoutInterval: 10.0)
		request.HTTPMethod = "POST"
		request.allHTTPHeaderFields = headers
		request.HTTPBody = postData

		let session = NSURLSession.sharedSession()
		let dataTask = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
			if (error != nil) {

				self.completion(successful: false, error: error, user: nil)
				return
			} else {
				self.getMainPageHtml()
			}
		})

		dataTask.resume()
	}

	// Because of sapphire's strange cookie detection, we have to make a seperate request for the main page. Depending on the title of the page, we can determine whether the user has inputted the correct credentials.

	private func getMainPageHtml() {

		let request = NSMutableURLRequest(URL: NSURL(string: "https://pamet-sapphire.k12system.com/CommunityWebPortal/Welcome.cfm")!,
			cachePolicy: .UseProtocolCachePolicy,
			timeoutInterval: 10.0)
		request.HTTPMethod = "GET"

		let session = NSURLSession.sharedSession()
		let dataTask = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
			if (error != nil) {
				print(error)
				print(error!.userInfo[NSLocalizedRecoverySuggestionErrorKey])
				self.completion(successful: false, error: error, user: nil)
			} else {
				if let html: String = NSString(data: data!, encoding: NSUTF8StringEncoding) as? String {

					if let doc = Kanna.HTML(html: html, encoding: NSUTF8StringEncoding) {

						print(doc)
						if (doc.title! == " Student Backpack - Sapphire Community Web Portal ") {

							// we can retrieve the student id from their current grade page link's query parameter
							let idString: String = doc.xpath("//*[@id=\"leftPipe\"]/ul[2]/li[4]/a")[0]["href"]!
							let id = idString.componentsSeparatedByString("=")[1]
							self.user.id = id
							self.completion(successful: true, error: nil, user: self.user)
						} else {

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