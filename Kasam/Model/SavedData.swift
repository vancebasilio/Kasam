//
//  SavedData.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-10-12.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import Foundation

struct SavedData {
    static var kasamTodayArray: [KasamSavedFormat] = []
    static var kasamArray: [KasamSavedFormat] = []
    static var kasamDict: [String:KasamSavedFormat] = [:]
    static var dayTrackerArray: [String] = []
    static var dayTrackerDict: [String: [Int:String]] = [:]

    static func addKasam(kasam: KasamSavedFormat) {
        self.kasamArray.append(kasam)
        self.kasamDict[kasam.kasamID] = kasam
    }
    
    static func addDayTracker(kasam: String, dayTrackerArray: [Int:String]) {
        self.dayTrackerDict[kasam] = dayTrackerArray
    }
}
