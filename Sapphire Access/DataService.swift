//
//  DataService.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 6/24/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit
import Kanna
import CoreData
import MagicalRecord
import Alamofire
import ReachabilitySwift

typealias CompletionType = (successful: Bool, error: NSError?) -> Void

class UpdateService {
	let student: Student
	let kCharacterSet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890.*+-"
	let context = NSManagedObjectContext.MR_context()
    let firstLoad: Bool
    
    var alamofireManager: Alamofire.Manager

	init?(studentID: NSManagedObjectID) {
		do {
			let object = try context.existingObjectWithID(studentID)
			if let s = object as? Student {
				student = s
                if let subs = student.subjects {
                    firstLoad = subs.allObjects.isEmpty
                } else {
                    firstLoad = true
                }
			} else {
				print("Failed to find student with object ID \(studentID). Could not cast NSManagedObject to Student")
				return nil
			}
            
            let config = NSURLSessionConfiguration.defaultSessionConfiguration()
            config.timeoutIntervalForRequest = 4
            config.requestCachePolicy = .ReloadIgnoringLocalCacheData
            alamofireManager = Alamofire.Manager(configuration: config)
		} catch let error as NSError {
			print("Failed to find student with object ID \(studentID). Error: \(error)")
			return nil
		}

	}

	func updateStudentInformation(completion: CompletionType) {
        
        let reachability: Reachability
        do {
            reachability = try Reachability.reachabilityForInternetConnection()
        } catch {
            completion(successful: false, error: badConnectionError)
            return
        }
        
        guard reachability.isReachable() else {
            completion(successful: false, error: badConnectionError)
            return
        }

		// Load the main courses page
		let coursesURL: String = "https://pamet-sapphire.k12system.com/CommunityWebPortal/Backpack/StudentClasses.cfm?STUDENT_RID=" + student.id!
		alamofireManager.request(.GET, coursesURL)
			.validate()
			.response { request, response, data, error in
				if let error = error {
                    if error.code == NSURLErrorTimedOut {
                        completion(successful: false, error: badConnectionError)
                    } else {
                        completion(successful: false, error: error)
                    }
				} else {
					if let doc = Kanna.HTML(html: data!, encoding: NSUTF8StringEncoding) {
						let subjectLinksPath = "//*[@id=\"contentPipe\"]/table//tr[@class!=\"classNotGraded\"]//td/a" // finds all the links on the visable table NOTE: DO NOT INCLUDE /tbody FOR SIMPLE TABLES WITHOUT A HEADER AND FOOTER
						let subjectLinks = doc.xpath(subjectLinksPath)

						var names: [String] = []
						for link in subjectLinks {
							names.append(link.text!.substringToIndex(link.text!.endIndex.predecessor())) // Remove the space after the name
						}
                        
                        guard names.count != 0 else {
                            completion(successful: false, error: noGradesError)
                            return
                        }

						let teacherXPath = "//*[@id=\"contentPipe\"]/table/tr[@class!=\"classNotGraded\"]/td[2]"
						var teachers: [String] = []
						for teacherElement in doc.xpath(teacherXPath) {
							teachers.append(teacherElement.text!)
						}

						let roomXPath = "//*[@id=\"contentPipe\"]/table/tr[@class!=\"classNotGraded\"]/td[4]"
						var rooms: [String] = []
						for roomElement in doc.xpath(roomXPath) {
							rooms.append(roomElement.text!)
						}

						var errors: [NSError] = []
						let downloadGroup = dispatch_group_create()
                        var subjectsToDelete : [Subject] = Subject.MR_findByAttribute("student", withValue: self.student, inContext: self.context) as! [Subject]
						for index in 0..<subjectLinks.count {
							let address = "https://pamet-sapphire.k12system.com" + subjectLinks[index]["href"]!
							let sectionGUID = address.componentsSeparatedByString("&")[1].componentsSeparatedByString("=")[1]

							dispatch_group_enter(downloadGroup)
                            if let oldSubject = subjectsToDelete.filter({$0.sectionGUID == sectionGUID}).first {
                                subjectsToDelete.removeObject(oldSubject)
								self.updateMarkingPeriodInformation(oldSubject, completion: { successful, error in
									if (error != nil) {
										errors.append(error!)
									}
									dispatch_group_leave(downloadGroup)
								})
							} else {
								if let subject = Subject.MR_createEntityInContext(self.context) {
									subject.htmlPage = address
									subject.name = names[index]
									subject.teacher = teachers[index]
									subject.room = rooms[index]
									subject.sectionGUID = sectionGUID
									subject.student = self.student

									self.updateMarkingPeriodInformation(subject, completion: { successful, error in
										if (error != nil) {
											errors.append(error!)
										}
										dispatch_group_leave(downloadGroup)
									})
								}

							}
                            
                        }
                        
                        for s in subjectsToDelete {
                            s.MR_deleteEntityInContext(self.context)
                        }

						// Runs when every callback in the for loop has completed
						dispatch_group_notify(downloadGroup, dispatch_get_main_queue(), {
							if let error = errors.first {
								self.context.reset()
                                if error.code == NSURLErrorTimedOut {
                                    completion(successful: false, error: badConnectionError)
                                } else {
                                    completion(successful: false, error: error)
                                }
							} else {
								self.context.MR_saveToPersistentStoreAndWait()
								self.refreshLastUpdatedDates({ successful, error in
									completion(successful: true, error: nil) // We don't care if this fails, it's an optional method
								})
							}
						})
					}
				}
		}
	}

	func updateMarkingPeriodInformation(subject: Subject, completion: CompletionType) {
		alamofireManager.request(.GET, subject.htmlPage!)
			.validate()
			.response { request, response, data, error in
				if let error = error {
                    if error.code == NSURLErrorTimedOut {
                        completion(successful: false, error: badConnectionError)
                    } else {
                        completion(successful: false, error: error)
                    }
				} else {
					if let doc = Kanna.HTML(html: data!, encoding: NSUTF8StringEncoding) {
						let mpXPath = "//*[@id=\"contentPipe\"]/div[3]/table/tr//td[a]/a"
						let otherXPath = "//*[@id=\"contentPipe\"]/div[3]/table/tr//td[b]"

						var mpURLStrings: [String] = []
						for node in doc.xpath(mpXPath) {
							if let mpURLString = node["href"] {
								mpURLStrings.append("https://pamet-sapphire.k12system.com" + mpURLString)
							}
						}

						var markingPeriods: [MarkingPeriod] = []
						for index in 0..<mpURLStrings.count {
							if let mp = MarkingPeriod.MR_findFirstByAttribute("htmlPage", withValue: mpURLStrings[index], inContext: self.context) {
								mp.empty = NSNumber(bool: false)
								markingPeriods.append(mp)
							} else if let mp = MarkingPeriod.MR_createEntityInContext(self.context) {
								mp.htmlPage = mpURLStrings[index]
								mp.number = mpURLStrings[index].componentsSeparatedByString("MP_CODE=")[1]
								mp.subject = subject
								mp.empty = NSNumber(bool: false)
								markingPeriods.append(mp)
							}
						}

						var otherGradeTitles: [String] = []
						var otherGradeScores: [String] = []
						for node in doc.xpath(otherXPath) {
							if let string = node.text {
								if let range = string.rangeOfString("(") {
									let x = string.substringToIndex(range.endIndex.predecessor())
									let title = x.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ").invertedSet).joinWithSeparator("")
									let score = x.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "123456778910").invertedSet).joinWithSeparator("")
									otherGradeTitles.append(title)
									otherGradeScores.append(score)
								}

							}
						}

						// Stores the other grades as a json string so we dont have to create more entities in core data.
						let otherGradeDictionary = NSDictionary(objects: otherGradeScores, forKeys: otherGradeTitles)
						do {
							let jsonData = try NSJSONSerialization.dataWithJSONObject(otherGradeDictionary, options: [])
							if let jsonString = String(data: jsonData, encoding: NSUTF8StringEncoding) {
								subject.otherGrades = jsonString
							}
						} catch let error as NSError {
							print(error)
						}

						let mpDownloadGroup = dispatch_group_create()
						var errors: [NSError] = []
						for mp in markingPeriods {
							dispatch_group_enter(mpDownloadGroup)
							self.alamofireManager.request(.GET, mp.htmlPage!)
								.validate()
								.response(completionHandler: { request, response, data, error in
									guard error == nil else {
										errors.append(error!)
										dispatch_group_leave(mpDownloadGroup)
										return
									}

									guard let mpPageDoc = Kanna.HTML(html: data!, encoding: NSUTF8StringEncoding) else {
										errors.append(unknownResponseError)
										dispatch_group_leave(mpDownloadGroup)
										return
									}

									if let currentMP = MarkingPeriod.MR_findFirstByAttribute("htmlPage", withValue: response!.URL!.absoluteString, inContext: self.context) {
										if let result = self.parseMarkingPeriodPage(html: mpPageDoc) {

											currentMP.possiblePoints = result.possiblePoints
											currentMP.totalPoints = result.totalPoints
											currentMP.percentGrade = result.percentGrade
                                            var assignmentsToDelete = currentMP.assignments!.allObjects as! [Assignment]
											for assignment in result.assignments {
												let dateFormatter = NSDateFormatter()
												// http://userguide.icu-project.org/formatparse/datetime/ <- Guidelines to format date
												dateFormatter.dateFormat = "MM/dd/yy"
                                                var dateCreated: NSDate = NSDate()
                                                if let date = assignment.date {
                                                    dateCreated = dateFormatter.dateFromString(date)!
                                                }

                                                if let oldAssignment = assignmentsToDelete.filter({$0.name == assignment.name && $0.category == assignment.category && $0.dateCreated == dateCreated}).first {
                                                    assignmentsToDelete.removeObject(oldAssignment)
													oldAssignment.totalPoints = assignment.totalPoints
													oldAssignment.possiblePoints = assignment.possiblePoints
													oldAssignment.dateCreated = dateCreated
                                                    
                                                    // We don't want to set assignments as old here. We should only change it in detail vc.
                                                    if !oldAssignment.changedValues().isEmpty {
                                                        oldAssignment.newUpdate = true
                                                    }
												} else {
													if let newA = Assignment.MR_createEntityInContext(self.context) {
														newA.dateCreated = dateCreated
														newA.name = assignment.name
														newA.totalPoints = assignment.totalPoints
														newA.possiblePoints = assignment.possiblePoints
														newA.category = assignment.category
														newA.markingPeriod = currentMP
                                                        newA.newUpdate = !self.firstLoad
													}
												}

											}
                                            
                                            for a in assignmentsToDelete {
                                                a.MR_deleteEntityInContext(self.context)
                                            }

										} else {
											currentMP.empty = NSNumber(bool: true)
										}
									}

									dispatch_group_leave(mpDownloadGroup)
							})
						}

						dispatch_group_notify(mpDownloadGroup, dispatch_get_main_queue(), {
							if let error = errors.first {
								completion(successful: false, error: error)
							} else {
								completion(successful: true, error: nil)
							}
						})
					}
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
		for index in 0 ..< aNames.count {
			let newA = (aNames[safe: index], aTotalPoints[safe: index], aPossiblePoints[safe: index], aDates[safe: index], aCategories[safe: index])
			assignments.append(newA)
			// print(newA)
		}

		return (assignments, totalPoints, possiblePoints, percentGrade)
	}

	func refreshLastUpdatedDates(completion: CompletionType) {
		// Get the landing page

		alamofireManager.request(.GET, "http://127.0.0.1/CommunityWebPortal/Backpack/StudentHome.cfm-STUDENT_RID=" + student.id! + ".html")
			.validate()
			.response(completionHandler: { request, response, data, error in
				if (error != nil) {
					completion(successful: false, error: error)
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

					for index in 0 ..< names.count {
						if let subject = Subject.MR_findFirstByAttribute("name", withValue: names[index], inContext: self.context) {
							let dateString = dates[index]
							let dateFormatter = NSDateFormatter()
							// http://userguide.icu-project.org/formatparse/datetime/ <- Guidelines to format date
							dateFormatter.dateFormat = "MM/dd/yy"
							let date = dateFormatter.dateFromString(dateString)
							subject.lastUpdated = date
						}
					}

					self.context.MR_saveToPersistentStoreAndWait()
					completion(successful: true, error: nil)

				} else {
					completion(successful: false, error: unknownResponseError)
				}

		})

	}
}
