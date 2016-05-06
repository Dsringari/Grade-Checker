//
//  DSCoreData.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 5/6/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit
import CoreData

class CoreDataParser {
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    lazy var moc: NSManagedObjectContext = {
        return self.appDelegate.managedObjectContext
    }()
    
    func insert(user: UserInfo, student: StudentInfo) {
        self.appDelegate.deleteAllUsers(moc)
        let cUser: User = NSEntityDescription.insertNewObjectForEntityForName("User", inManagedObjectContext: moc) as! User
        cUser.username = user.username
        cUser.password = user.password
        cUser.pin = user.pin
        
        for student in user.students! {
            let cStudent = NSEntityDescription.insertNewObjectForEntityForName("Student", inManagedObjectContext: moc) as! Student
            cStudent.name = student.name
            cStudent.id = student.id
            cStudent.grade = student.grade
            cStudent.school = student.school
            cStudent.user = cUser
            for subject in student.subjects! {
                let cSubject: Subject
                if let storedSubject = moc.getObjectFromStore("Subject", predicateString: "sectionGUID == %@", args: [subject.sectionGUID]) {
                    cSubject = storedSubject as! Subject
                } else {
                    cSubject = NSEntityDescription.insertNewObjectForEntityForName("Subject", inManagedObjectContext: moc) as! Subject
                }
                    
                cSubject.name = subject.name
                cSubject.sectionGUID = subject.name
                cSubject.htmlPage = subject.htmlPage
                cSubject.room = subject.room
                cSubject.teacher = subject.teacher
                cSubject.student = cStudent
                for mpNumber in 1...4 {
                    let cMp = NSEntityDescription.insertNewObjectForEntityForName("MarkingPeriod", inManagedObjectContext: moc) as! MarkingPeriod
                    cMp.number = mpNumber
                }
            }
        }
    }
    
    func updateExistingSubject(subject: Subject, withInfo subjectInfo: SubjectInfo) {
        guard subject.sectionGUID == subjectInfo.sectionGUID else {
            print("Invalid use of update existing subject. Returning")
            return
        }
        let cMarkingPeriods = subject.markingPeriods!.allObjects as! [MarkingPeriod]
        for mpNumber in 1...4 {
            let cMp = cMarkingPeriods.filter{$0.number == String(mpNumber)}[0]
            let mp = subjectInfo.markingPeriods!.filter{$0.number == String(mpNumber)}[0]
            cMp.possiblePoints = mp.possiblePoints
            cMp.totalPoints = mp.totalPoints
            cMp.percentGrade = mp.percentGrade
            
            guard !mp.empty else {
                cMp.empty = NSNumber(bool: false)
                continue
            }
            
            
            
        }
    }
}
