//
//  SapphireAccessHelper.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 9/3/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit

func calculateAverageGrade(_ subject: Subject, roundToWholeNumber: Bool = true) -> String? {
    guard var markingPeriods = subject.markingPeriods?.allObjects as? [MarkingPeriod] else {
        return nil
    }
    
    markingPeriods = markingPeriods.filter{!$0.empty!.boolValue}
    
    var mpTotal: NSDecimalNumber = 0
    var mpPossible: NSDecimalNumber = 20
    var mpCount: NSDecimalNumber = 0
    for mp in markingPeriods {
        
        // Remove %
        guard let percentgradeString = mp.percentGrade?.components(separatedBy: CharacterSet(charactersIn: "1234567890.").inverted).joined(separator: "") else {
            continue
        }
        
        mpTotal = mpTotal.adding(NSDecimalNumber(string: percentgradeString))
        mpCount = mpCount.adding(1)
    }
    
    
    if (mpCount.doubleValue == 0) {
        return nil
    }
    
    mpTotal = mpTotal.multiplying(by: 0.2)
    mpPossible = mpPossible.multiplying(by: mpCount)
    
    var midtermFinalTotal: NSDecimalNumber = 0
    var midtermFinalCount: NSDecimalNumber = 0
    var midtermFinalPossible: NSDecimalNumber = 10
    if let mt = dictionaryFromOtherGradesJSON(subject.otherGrades)?["MT"] {
        midtermFinalCount = midtermFinalCount.adding(1)
        midtermFinalTotal = midtermFinalTotal.adding(NSDecimalNumber(string: mt))
    }
    
    if let fe = dictionaryFromOtherGradesJSON(subject.otherGrades)?["FE"] {
        midtermFinalCount = midtermFinalCount.adding(1)
        midtermFinalTotal = midtermFinalTotal.adding(NSDecimalNumber(string: fe))
    }
    midtermFinalTotal = midtermFinalTotal.multiplying(by: 0.1)
    midtermFinalPossible = midtermFinalPossible.multiplying(by: midtermFinalCount)
    
    let total = mpTotal.adding(midtermFinalTotal)
    let possible = mpPossible.adding(midtermFinalPossible)
    
    
    let average = total.dividing(by: possible).multiplying(byPowerOf10: 2)
    if roundToWholeNumber {
        return String(Int(round(average.doubleValue)))
    }
    
    let numberFormatter = NumberFormatter()
    numberFormatter.minimumFractionDigits = 2
    numberFormatter.maximumFractionDigits = 2
    numberFormatter.minimumIntegerDigits = 1
    numberFormatter.roundingMode = .halfUp
    numberFormatter.numberStyle = .decimal
    return numberFormatter.string(from: average)
    
}


func dictionaryFromOtherGradesJSON(_ string: String?) -> [String: String]? {
    guard let jsonData = string?.data(using: String.Encoding.utf8) else {
        return nil
    }
    
    do {
        return try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: String]
    } catch {
        return nil
    }
}

