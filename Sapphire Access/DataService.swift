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
        config.timeoutIntervalForRequest = 0
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
                            var addresses: [String] = []
                            for link in subjectLinks {
                                names.append(link.text!.substring(to: link.text!.index(before: link.text!.endIndex))) // Remove the space after the name
                                let address = "https://pamet-sapphire.k12system.com" + link["href"]!
                                addresses.append(address)
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
                            
                            // Delete all subjects that were not found by their address
                            let predicate = NSPredicate(format: "NOT(address IN %@)", argumentArray: [addresses])
                            Subject.mr_deleteAll(matching: predicate, in: self.context)
                            
                            let subjectDownloadTask = DispatchGroup()
                            var downloadTaskSuccess = true
                            var downloadTaskError: Error? = nil
                            
                            for (i,_) in subjectLinks.enumerated() {
                                let subject = [
                                    "name": names[i],
                                    "teacher": teachers[i],
                                    "room": rooms[i],
                                    "address": addresses[i],
                                ]
                                let importedSubject = Subject.mr_import(from: subject, in: self.context)
                                importedSubject.student = self.student
                                subjectDownloadTask.enter()
                                self.updateMarkingPeriodInformation(importedSubject) { success, error in
                                    guard error == nil && success else {
                                        downloadTaskSuccess = false
                                        downloadTaskError = error
                                        return
                                    }
                                    subjectDownloadTask.leave()
                                    
                                }
                            }
                            
                            subjectDownloadTask.notify(queue: DispatchQueue.main) {
                                guard downloadTaskSuccess else {
                                    self.context.rollback()
                                    completion(false, downloadTaskError as NSError?)
                                    return
                                }
                                self.context.mr_saveToPersistentStoreAndWait()
                                self.refreshLastUpdatedDates({ _, _ in
                                    completion(true, nil)
                                })
                            }
                            
                        }
                    }
            }
            
        }

    }

	func updateMarkingPeriodInformation(_ subject: Subject, completion: @escaping CompletionType) {
		Manager.sharedInstance.request(subject.address)
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
                        
                        let subjectAddress = response.response!.url!.absoluteString
                        let currentSubject = Subject.mr_findFirst(byAttribute: "address", withValue: subjectAddress, in: self.context)!
                        
                        let mpAddresses = doc.xpath(mpXPath).map{"https://pamet-sapphire.k12system.com" + $0["href"]!}
                        
                        // Delete all mp of this subject that are not found in mpAddresses
                        let predicate = NSPredicate(format: "NOT(address IN %@) AND subject.address == %@", argumentArray: [mpAddresses, subjectAddress])
                        MarkingPeriod.mr_deleteAll(matching: predicate, in: self.context)
                        
                        let mpDownloadGroup = DispatchGroup()
                        var mpDownloadTaskSuccess = true
                        var mpDownloadTaskError: Error? = nil
                        
						for (_, node) in doc.xpath(mpXPath).enumerated() {
							if let mpAddress = node["href"] {
                                let mp: [String: Any] = [
                                    "address": "https://pamet-sapphire.k12system.com" + mpAddress,
                                    "empty": false,
                                    "number": mpAddress.components(separatedBy: "MP_CODE=")[1],
                                    "subjectAddress": subjectAddress
                                ]
                                MarkingPeriod.mr_import(from: mp, in: self.context)
                                
                                mpDownloadGroup.enter()
                                Manager.sharedInstance.request(mp["address"]! as! String)
                                    .validate()
                                    .response(completionHandler: { response in
                                        guard response.error == nil else {
                                            mpDownloadTaskError = response.error
                                            mpDownloadTaskSuccess = false
                                            mpDownloadGroup.leave()
                                            return
                                        }
                                        
                                        guard let mpPageDoc = Kanna.HTML(html: response.data!, encoding: String.Encoding.utf8) else {
                                            mpDownloadTaskError = unknownResponseError
                                            mpDownloadTaskSuccess = false
                                            mpDownloadGroup.leave()
                                            return
                                        }
                                        
                                        if let currentMP = MarkingPeriod.mr_findFirst(byAttribute: "address", withValue: response.response!.url!.absoluteString, in: self.context) {
                                            if let result = self.parseMarkingPeriodPage(html: mpPageDoc) {
                                                let subject = currentMP.subject
                                                currentMP.possiblePoints = result.possiblePoints
                                                currentMP.totalPoints = result.totalPoints
                                                currentMP.percentGrade = result.percentGrade
                                                var assignmentsToDelete = currentMP.assignments!.allObjects as! [Assignment]
                                                for assignment in result.assignments {
                                                    let dateFormatter = DateFormatter()
                                                    // http://userguide.icu-project.org/formatparse/datetime/ <- Guidelines to format date
                                                    dateFormatter.dateFormat = "MM/dd/yy-z"
                                                    dateFormatter.timeZone = TimeZone(abbreviation: "EST")
                                
                                                    let dateCreated = dateFormatter.date(from: assignment["date"]!!)!
                                                    
                                                    // See if lastUpdated has the most recent date
                                                    if let lastUpdated = subject.lastUpdated {
                                                        if lastUpdated.compare(dateCreated) == .orderedAscending {
                                                            subject.lastUpdated = dateCreated
                                                        }
                                                    } else {
                                                        subject.lastUpdated = dateCreated
                                                    }
                                                    
                                                    let foundAssignment = assignmentsToDelete.filter { a in
                                                        if a.name == assignment["name"]!! && a.category == assignment["category"]!! {
                                                            return a.date.compare(dateCreated) == .orderedSame
                                                        }
                                                        
                                                        return false
                                                    }.first
                                                    
                                                    if let oldAssignment = foundAssignment {
                                                        assignmentsToDelete.removeObject(oldAssignment)
                                                        oldAssignment.mr_importValuesForKeys(with: assignment)
                                                        
                                                        // We don't want to set assignments as old here. We should only change it in detail vc.
                                                        if !oldAssignment.changedValues().isEmpty {
                                                            oldAssignment.newUpdate = true
                                                        }
                                                    } else {
                                                        let newA = Assignment.mr_createEntity(in: self.context)!
                                                        newA.mr_importValuesForKeys(with: assignment)
                                                        newA.markingPeriod = currentMP
                                                        newA.newUpdate = !self.firstLoad as NSNumber
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
						}
                        
                        mpDownloadGroup.notify(queue: DispatchQueue.main) {
                            guard mpDownloadTaskSuccess else {
                                completion(false, mpDownloadTaskError as NSError?)
                                return
                            }
                            completion(true, nil)
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
								currentSubject.otherGrades = jsonString
							}
						} catch let error as NSError {
                            print("Failed to parse otherGrades into NSData. Error: ")
							print(error)
						}
					}
				}
		}
	}

    fileprivate func parseMarkingPeriodPage(html doc: HTMLDocument) -> (assignments: [[String: String?]], totalPoints: String, possiblePoints: String, percentGrade: String)? {
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
        var aNames: [Int: String] = [:]
		for (i, aE) in doc.xpath(assignmentsXpath + "/td[" + assigntmentIndex + "]").enumerated() {
			let text = aE.text!
			aNames[i] = (text)
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
        var aTotalPoints: [Int: String] = [:]
		for (i, aE) in doc.xpath(assignmentsXpath + "/td[" + totalScoreIndex + "]").enumerated() {
			var text = aE.text!
			text = text.components(separatedBy: CharacterSet(charactersIn: kCharacterSet).inverted).joined(separator: "")
			aTotalPoints[i] = text
		}

		// Get All possible points
        var aPossiblePoints: [Int: String] = [:]
		for (i, aE) in doc.xpath(assignmentsXpath + "/td[" + possibleScoreIndex + "]").enumerated() {
			var text = aE.text!
			text = text.components(separatedBy: NSCharacterSet(charactersIn: "1234567890.").inverted).joined(separator: "")
			aPossiblePoints[i] = text
		}

		// Get All the dates
		var aDates: [Int: String] = [:]
		for (i, aE) in doc.xpath(assignmentsXpath + "/td[" + dueDateIndex + "]").enumerated() {
			let text = aE.text! + "-EST"
			aDates[i] = text
		}

		// Get all the categories
		var aCategories: [Int: String] = [:]
        if let categoryIndex = categoryIndex {
            for (i, aE) in doc.xpath(assignmentsXpath + "/td[" + categoryIndex + "]").enumerated() {
                let text = aE.text!
                aCategories[i] = text
            }
        }
		

		// Build the assignment dictionary
        var assignments: [[String: String?]] = []
		for i in 0 ..< aNames.count {
			let newA = ["name": aNames[i],"totalPoints": aTotalPoints[i],"possiblePoints": aPossiblePoints[i],"date": aDates[i],"category": aCategories[i]]
			assignments.append(newA)
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
