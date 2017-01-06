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

typealias CompletionType = (_ successful: Bool, _ error: NSError?) -> Void

class Manager {
    static let sharedInstance = { () -> Alamofire.SessionManager in
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        config.httpCookieStorage = HTTPCookieStorage.shared
        return Alamofire.SessionManager(configuration: config)
    }()
    private init() {} //This prevents usage of the default '()' initializer for this class.
}

class UpdateService {
	let student: Student
	let kCharacterSet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890.*+-"
	let context = NSManagedObjectContext.mr_()
    let firstLoad: Bool

	init?(studentID: NSManagedObjectID) {
		do {
			let object = try context.existingObject(with: studentID)
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
		} catch let error as NSError {
			print("Failed to find student with object ID \(studentID). Error: \(error)")
			return nil
		}

	}

	func updateStudentInformation(_ completion: @escaping CompletionType) {
        
        guard Reachability() != nil else {
            completion(false, badConnectionError)
            return
        }
        
        LoginService(refreshUserWithID: student.user!.objectID) { successful, error in
            guard successful else {
                completion(false, badLoginError)
                return
            }
            
            // Load the main courses page
            let coursesURL: String = "https://pamet-sapphire.k12system.com/CommunityWebPortal/Backpack/StudentClasses.cfm?STUDENT_RID=" + self.student.id!
            Manager.sharedInstance.request(coursesURL)
                .validate()
                .response { response in
                    if let error = response.error as? NSError {
                        if error.code == NSURLErrorTimedOut {
                            completion(false, badConnectionError)
                        } else {
                            completion(false, error)
                        }
                    } else {
                        if let doc = Kanna.HTML(html: response.data!, encoding: String.Encoding.utf8) {
                            let subjectLinksPath = "//*[@id=\"contentPipe\"]/table//tr[@class!=\"classNotGraded\"]//td/a" // finds all the links on the visable table NOTE: DO NOT INCLUDE /tbody FOR SIMPLE TABLES WITHOUT A HEADER AND FOOTER
                            let subjectLinks = doc.xpath(subjectLinksPath)
                            
                            var names: [String] = []
                            for link in subjectLinks {
                                names.append(link.text!.substring(to: link.text!.index(before: link.text!.endIndex))) // Remove the space after the name
                            }
                            
                            guard names.count != 0 else {
                                completion(false, noGradesError)
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
                            let downloadGroup = DispatchGroup()
                            var subjectsToDelete : [Subject] = Subject.mr_find(byAttribute: "student", withValue: self.student, in: self.context) as! [Subject]
                            for (index, node) in subjectLinks.enumerated() {
                                let address = "https://pamet-sapphire.k12system.com" + node["href"]!
                                let sectionGUID = address.components(separatedBy: "&")[1].components(separatedBy: "=")[1]
                                
                                downloadGroup.enter()
                                if let oldSubject = subjectsToDelete.filter({$0.sectionGUID == sectionGUID}).first {
                                    subjectsToDelete.removeObject(oldSubject)
                                    self.updateMarkingPeriodInformation(oldSubject, completion: { successful, error in
                                        if (error != nil) {
                                            errors.append(error!)
                                        }
                                        downloadGroup.leave()
                                    })
                                } else {
                                    if let subject = Subject.mr_createEntity(in: self.context) {
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
                                            downloadGroup.leave()
                                        })
                                    }
                                    
                                }
                                
                            }
                            
                            for s in subjectsToDelete {
                                s.mr_deleteEntity(in: self.context)
                            }
                            
                            // Runs when every callback in the for loop has completed
                            
                            downloadGroup.notify(queue: DispatchQueue.main) {
                                if let error = errors.first {
                                    self.context.reset()
                                    if error.code == NSURLErrorTimedOut {
                                        completion(false, badConnectionError)
                                    } else {
                                        completion(false, error)
                                    }
                                } else {
                                    self.refreshLastUpdatedDates({ successful, error in
                                        downloadGroup.notify(queue: DispatchQueue.main) {
                                            completion(true, nil) // We don't care if this fails, it's an optional method
                                        }
                                    })
                                }
                            }
                        }
                    }
            }
            
        }

    }

	func updateMarkingPeriodInformation(_ subject: Subject, completion: @escaping CompletionType) {
		Manager.sharedInstance.request(subject.htmlPage!)
			.validate()
			.response { response in
				if let error = response.error as? NSError {
                    if error.code == NSURLErrorTimedOut {
                        completion(false, badConnectionError)
                    } else {
                        completion(false, error)
                    }
				} else {
					if let doc = Kanna.HTML(html: response.data!, encoding: String.Encoding.utf8) {
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
							if let mp = MarkingPeriod.mr_findFirst(byAttribute: "htmlPage", withValue: mpURLStrings[index], in: self.context) {
								mp.empty = NSNumber(value: false)
								markingPeriods.append(mp)
							} else if let mp = MarkingPeriod.mr_createEntity(in: self.context) {
								mp.htmlPage = mpURLStrings[index]
                                mp.number = mpURLStrings[index].components(separatedBy: "MP_CODE=")[1]
								mp.subject = subject
								mp.empty = NSNumber(value: false)
								markingPeriods.append(mp)
							}
						}

						var otherGradeTitles: [String] = []
						var otherGradeScores: [String] = []
						for node in doc.xpath(otherXPath) {
							if let string = node.text {
                                if let range = string.range(of: "(") {
                                    let x = string.substring(to: string.index(before: range.upperBound))
                                    let title = x.components(separatedBy: CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ").inverted).joined(separator: "")
									let score = x.components(separatedBy: CharacterSet(charactersIn: "123456778910").inverted).joined(separator: "")
									otherGradeTitles.append(title)
									otherGradeScores.append(score)
								}

							}
						}

						// Stores the other grades as a json string so we dont have to create more entities in core data.
						let otherGradeDictionary = NSDictionary(objects: otherGradeScores, forKeys: otherGradeTitles as [NSCopying])
						do {
							let jsonData = try JSONSerialization.data(withJSONObject: otherGradeDictionary, options: [])
							if let jsonString = String(data: jsonData, encoding: String.Encoding.utf8) {
								subject.otherGrades = jsonString
							}
						} catch let error as NSError {
							print(error)
						}

						let mpDownloadGroup = DispatchGroup()
						var errors: [NSError] = []
						for mp in markingPeriods {
							mpDownloadGroup.enter()
							Manager.sharedInstance.request(mp.htmlPage!)
								.validate()
								.response(completionHandler: { response in
									guard response.error == nil else {
										errors.append(response.error! as NSError)
										mpDownloadGroup.leave()
										return
									}

									guard let mpPageDoc = Kanna.HTML(html: response.data!, encoding: String.Encoding.utf8) else {
										errors.append(unknownResponseError)
										mpDownloadGroup.leave()
										return
									}

									if let currentMP = MarkingPeriod.mr_findFirst(byAttribute: "htmlPage", withValue: response.response!.url!.absoluteString, in: self.context) {
										if let result = self.parseMarkingPeriodPage(html: mpPageDoc) {

											currentMP.possiblePoints = result.possiblePoints
											currentMP.totalPoints = result.totalPoints
											currentMP.percentGrade = result.percentGrade
                                            var assignmentsToDelete = currentMP.assignments!.allObjects as! [Assignment]
											for assignment in result.assignments {
												let dateFormatter = DateFormatter()
												// http://userguide.icu-project.org/formatparse/datetime/ <- Guidelines to format date
												dateFormatter.dateFormat = "MM/dd/yy"
                                                var dateCreated: NSDate = NSDate()
                                                if let date = assignment.date {
                                                    dateCreated = dateFormatter.date(from: date)! as NSDate
                                                }

                                                if let oldAssignment = assignmentsToDelete.filter({$0.name == assignment.name && $0.category == assignment.category && $0.dateCreated == dateCreated as Date}).first {
                                                    assignmentsToDelete.removeObject(oldAssignment)
													oldAssignment.totalPoints = assignment.totalPoints
													oldAssignment.possiblePoints = assignment.possiblePoints
													oldAssignment.dateCreated = dateCreated as Date
                                                    
                                                    // We don't want to set assignments as old here. We should only change it in detail vc.
                                                    if !oldAssignment.changedValues().isEmpty {
                                                        oldAssignment.newUpdate = true
                                                    }
												} else {
													if let newA = Assignment.mr_createEntity(in: self.context) {
														newA.dateCreated = dateCreated as Date
														newA.name = assignment.name
														newA.totalPoints = assignment.totalPoints
														newA.possiblePoints = assignment.possiblePoints
														newA.category = assignment.category
														newA.markingPeriod = currentMP
                                                        newA.newUpdate = !self.firstLoad as NSNumber
													}
												}

											}
                                            
                                            for a in assignmentsToDelete {
                                                a.mr_deleteEntity(in: self.context)
                                            }

										} else {
											currentMP.empty = NSNumber(value: true)
										}
									}

									mpDownloadGroup.leave()
							})
						}
                        
                        mpDownloadGroup.notify(queue: DispatchQueue.main) {
                            if let error = errors.first {
                                completion(false, error)
                            } else {
                                completion(true, nil)
                            }
                        }
					}
				}
		}
	}

	fileprivate func parseMarkingPeriodPage(html doc: HTMLDocument) -> (assignments: [(name: String?, totalPoints: String?, possiblePoints: String?, date: String?, category: String?)], totalPoints: String, possiblePoints: String, percentGrade: String)? {
		var percentGrade: String = ""
		var totalPoints: String = ""
		var possiblePoints: String = ""

		var assigntmentIndex: String
		var totalScoreIndex: String
		var possibleScoreIndex: String
		var dueDateIndex: String
		var categoryIndex: String? = nil

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

		assigntmentIndex = String(headers.index(of: "Assignment")! + 1)
		totalScoreIndex = String(headers.index(of: "totalScore")! + 1)
		possibleScoreIndex = String(headers.index(of: "possibleScore")! + 1)
		dueDateIndex = String(headers.index(of: "DateDue")! + 1)
        if let catIndex = headers.index(of: "Category") {
            categoryIndex = String(catIndex+1)
        }
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
			text = text.components(separatedBy: CharacterSet(charactersIn: "1234567890.%").inverted).joined(separator: "")
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
			text = text.components(separatedBy: CharacterSet(charactersIn: "1234567890./").inverted).joined(separator: "")
			// Seperate the String into Possible / Total Points
            totalPoints = text.components(separatedBy: "/")[0]
			possiblePoints = text.components(separatedBy: "/")[1]
		} else {
			print("Failed to find pointsTextElement!")
			return nil
		}

		// Get all total points
		var aTotalPoints: [String] = []
		for aE: XMLElement in doc.xpath(assignmentsXpath + "/td[" + totalScoreIndex + "]") {
			var text = aE.text!
			text = text.components(separatedBy: CharacterSet(charactersIn: kCharacterSet).inverted).joined(separator: "")
			aTotalPoints.append(text)
		}

		// Get All possible points
		var aPossiblePoints: [String] = []
		for aE: XMLElement in doc.xpath(assignmentsXpath + "/td[" + possibleScoreIndex + "]") {
			var text = aE.text!
			text = text.components(separatedBy: NSCharacterSet(charactersIn: "1234567890.").inverted).joined(separator: "")
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
        if let categoryIndex = categoryIndex {
            for aE: XMLElement in doc.xpath(assignmentsXpath + "/td[" + categoryIndex + "]") {
                let text = aE.text!
                aCategories.append(text)
            }
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

	func refreshLastUpdatedDates(_ completion: @escaping CompletionType) {
		// Get the landing page

		Manager.sharedInstance.request("http://pamet-sapphire.k12system.com/CommunityWebPortal/Backpack/StudentHome.cfm?STUDENT_RID=" + student.id!)
			.validate()
			.response(completionHandler: { response in
				if (response.error != nil) {
					completion(false, response.error as NSError?)
					return
				}

				if let doc = Kanna.HTML(html: response.data!, encoding: String.Encoding.utf8) { // BTW A PARENT ACCOUNT CAN HAVE ONLY ONE STUDENT
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
						if let subject = Subject.mr_findFirst(byAttribute: "name", withValue: names[index], in: self.context) {
							let dateString = dates[index]
							let dateFormatter = DateFormatter()
							// http://userguide.icu-project.org/formatparse/datetime/ <- Guidelines to format date
							dateFormatter.dateFormat = "M/d/yy"
                            if let date = dateFormatter.date(from: dateString) {
                                subject.lastUpdated = date
                            }
						}
					}
					self.context.mr_saveToPersistentStoreAndWait()
					completion(true, nil)

				} else {
					completion(false, unknownResponseError)
				}

		})

	}
}
