//
//  SapphireAccessHelper.swift
//  Sapphire Access
//
//  Created by Dhruv Sringari on 9/3/16.
//  Copyright © 2016 Dhruv Sringari. All rights reserved.
//

import UIKit

func calculateAverageGrade(subject: Subject, roundToWholeNumber: Bool = true) -> String? {
    guard var markingPeriods = subject.markingPeriods?.allObjects as? [MarkingPeriod] else {
        return nil
    }
    
    markingPeriods = markingPeriods.filter{!$0.empty!.boolValue}
    
    var mpTotal: NSDecimalNumber = 0
    var mpPossible: NSDecimalNumber = 20
    var mpCount: NSDecimalNumber = 0
    for mp in markingPeriods {
        
        // Remove %
        guard let percentgradeString = mp.percentGrade?.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "1234567890.").invertedSet).joinWithSeparator("") else {
            continue
        }
        
        mpTotal = mpTotal.decimalNumberByAdding(NSDecimalNumber(string: percentgradeString))
        mpCount = mpCount.decimalNumberByAdding(1)
    }
    
    
    if (mpCount.doubleValue == 0) {
        return nil
    }
    
    mpTotal = mpTotal.decimalNumberByMultiplyingBy(0.2)
    mpPossible = mpPossible.decimalNumberByMultiplyingBy(mpCount)
    
    var midtermFinalTotal: NSDecimalNumber = 0
    var midtermFinalCount: NSDecimalNumber = 0
    var midtermFinalPossible: NSDecimalNumber = 10
    if let mt = dictionaryFromOtherGradesJSON(subject.otherGrades)?["MT"] {
        midtermFinalCount = midtermFinalCount.decimalNumberByAdding(1)
        midtermFinalTotal = midtermFinalTotal.decimalNumberByAdding(NSDecimalNumber(string: mt))
    }
    
    if let fe = dictionaryFromOtherGradesJSON(subject.otherGrades)?["FE"] {
        midtermFinalCount = midtermFinalCount.decimalNumberByAdding(1)
        midtermFinalTotal = midtermFinalTotal.decimalNumberByAdding(NSDecimalNumber(string: fe))
    }
    midtermFinalTotal = midtermFinalTotal.decimalNumberByMultiplyingBy(0.1)
    midtermFinalPossible = midtermFinalPossible.decimalNumberByMultiplyingBy(midtermFinalCount)
    
    let total = mpTotal.decimalNumberByAdding(midtermFinalTotal)
    let possible = mpPossible.decimalNumberByAdding(midtermFinalPossible)
    
    
    let average = total.decimalNumberByDividingBy(possible).decimalNumberByMultiplyingByPowerOf10(2)
    if roundToWholeNumber {
        return String(Int(round(average.doubleValue)))
    }
    
    let numberFormatter = NSNumberFormatter()
    numberFormatter.minimumFractionDigits = 2
    numberFormatter.maximumFractionDigits = 2
    numberFormatter.minimumIntegerDigits = 1
    numberFormatter.roundingMode = .RoundHalfUp
    numberFormatter.numberStyle = .DecimalStyle
    return numberFormatter.stringFromNumber(average)
    
}


func dictionaryFromOtherGradesJSON(string: String?) -> [String: String]? {
    guard let jsonData = string?.dataUsingEncoding(NSUTF8StringEncoding) else {
        return nil
    }
    
    do {
        return try NSJSONSerialization.JSONObjectWithData(jsonData, options: []) as? [String: String]
    } catch {
        return nil
    }
}

