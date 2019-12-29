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

struct NewChallo {
    static var editChalloCheck = false
    static var kasamID = ""
    static var kasamName = ""
    static var kasamDescription = ""
    static var chosenMetric = ""
    static var loadedInChalloImage = UIImage()
    static var loadedInChalloImageURL = URL(string: "")
    static var challoImageToSave = UIImage()
    static var dataLoadCheck = false
    static var numberOfBlocks = 1
    static var challoTransferArray = [Int:NewChalloLoadFormat]()
    static var fullActivityMatrix = [Int: [Int: newActivityFormat]]()
    
    static func resetChallo(){
        self.editChalloCheck = false
        self.kasamID = ""
        self.kasamName = ""
        self.kasamDescription = ""
        self.chosenMetric = ""
        self.loadedInChalloImage = UIImage()
        self.loadedInChalloImageURL = URL(string: "")
        self.challoImageToSave = UIImage()
        self.dataLoadCheck = false
        self.numberOfBlocks = 1
        self.challoTransferArray.removeAll()
        self.fullActivityMatrix.removeAll()
    }
}
