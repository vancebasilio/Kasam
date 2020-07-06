//
//  Unused_Functions.swift
//  Kasam
//
//  Created by Vance Basilio on 2020-07-06.
//  Copyright © 2020 Vance Basilio. All rights reserved.
//

import Foundation


//func currentStreak(kasamID: String, dictionary: [Int:(Date, Double)], currentDay: Int) -> (currentStreak:Int, daysWithAnyProgress:Int, longestStreak:Int) {
//    var daysWithAnyProgress = 0
//    var daysWithCompleteProgress = 0
//    var currentStreak = 0
//    var currentStreakCompleteProgress = 0
//    var anyProgressCheck = 0
//    var completeProgressCheck = 0
//    var longestStreak = 0
//    var streak = [0]
//    var streakEndDate = [0]
//    for day in stride(from: currentDay, through: 1, by: -1) {
//        if dictionary[day] != nil {
//            streak[streak.count - 1] += 1
//            if dictionary[day]!.1 == 1.0 {
//                daysWithCompleteProgress += 1                                   //all days with 100% progress
//                if streakEndDate.count != streak.count {streakEndDate[streakEndDate.count - 1] = day}
//            } else if completeProgressCheck == 0 {
//                currentStreakCompleteProgress = daysWithCompleteProgress        //current streak days with 100% progress
//                completeProgressCheck = 1
//            }
//        } else if day != currentDay {
//            streak += [0]
//            streakEndDate += [0]
//            if anyProgressCheck == 0 {
//                currentStreakCompleteProgress = daysWithCompleteProgress        //current streak days with 100% progress
//            }
//            anyProgressCheck = 1
//        }
//    }
//    longestStreak = streak.max() ?? 0
//    daysWithAnyProgress = streak.reduce(0, +)
//    if anyProgressCheck == 0 {                                                  //in case all days have some progress
//        currentStreak = daysWithAnyProgress
//        if currentStreakCompleteProgress == 0 {
//            currentStreakCompleteProgress = daysWithCompleteProgress
//        }
//    }
//    return (currentStreak, daysWithAnyProgress, longestStreak)
//}
