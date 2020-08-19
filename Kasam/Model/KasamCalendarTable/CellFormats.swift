//
//  DiscoverBlockFormat.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-05-05.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase

class discoverKasamFormat {
    var title: String
    var image: URL
    var rating: String
    var creator: String?
    var kasamID: String
    var genre: String
    
    init(title: String, image: URL, rating: String, creator: String?, kasamID: String, genre: String){
        self.image = image
        self.title = title
        self.rating = rating
        self.creator = creator
        self.kasamID = kasamID
        self.genre = genre
    }
}

class kasamFollowingCellFormat {
    var image: URL
    var title: String
    var kasamID: String
    var metricType: String
    
    init(kasamID: String, title: String, image: URL, metricType: String){
        self.image = image
        self.title = title
        self.kasamID = kasamID
        self.metricType = metricType
    }
}

class weekStatsFormat {
    var kasamID: String
    var kasamTitle: String
    var imageURL: URL
    var daysLeft: Int
    var metricType: String
    var avgMetric: Int
    var metricDictionary = [Int:Double]()
    
    init(kasamID: String, kasamTitle: String, imageURL: URL, daysLeft: Int, metricType: String, metricDictionary: [Int: Double], avgMetric: Int){
        self.kasamID = kasamID
        self.kasamTitle = kasamTitle
        self.imageURL = imageURL
        self.daysLeft = daysLeft
        self.metricType = metricType
        self.avgMetric = avgMetric
        self.metricDictionary = metricDictionary
    }
}

class SquareKasamFormat {
    var image: URL
    var title: String
    var type: String
    var duration: String
    var kasamID: String
    
    init(title: String, type: String, duration: String, image: URL, kasamID: String){
        self.image = image
        self.title = title
        self.type = type
        self.duration = duration
        self.kasamID = kasamID
    }
}

class PersonalBlockFormat {
    var kasamID: String
    var groupID: String?
    var blockID: String
    var image: URL
    var blockTitle: String
    var dayOrder: Int
    var duration: String?
    
    init(kasamID: String, groupID: String?, blockID: String, blockTitle: String, dayOrder: Int, duration: String?, image: URL){
        self.kasamID = kasamID
        self.groupID = groupID
        self.blockID = blockID
        self.dayOrder = dayOrder
        self.image = image
        self.blockTitle = blockTitle
        self.duration = duration
    }
}

class KasamSavedFormat {
    typealias streakInfo = (currentStreak:(value:Int, date:Date?), daysWithAnyProgress:Int, longestStreak:Int)
    var kasamID: String
    var kasamName: String
    var joinedDate: Date
    var startTime: String
    var currentDay: Int
    var repeatDuration: Int
    var image: String
    var metricType: String
    var programDuration: Int?
    var streakInfo: streakInfo
    var displayStatus: String
    var percentComplete: Double
    var badgeList: [String:[String:String]]?
    var benefitsThresholds: [(Int,String)]?
    var dayTrackerArray: [Int:(date: Date, progress: Double)]?
    var groupID: String?
    var groupAdmin: String?
    var groupStatus: String?
    var groupTeam: [String:Double]?
    
    init(kasamID: String, kasamName: String, joinedDate: Date, startTime: String, currentDay: Int, repeatDuration: Int, image: String?, metricType: String?, programDuration: Int?, streakInfo: streakInfo, displayStatus: String, percentComplete: Double, badgeList: [String:[String:String]]?, benefitsThresholds: [(Int,String)]?, dayTrackerArray: [Int:(date: Date, progress: Double)]?, groupID: String?, groupAdmin: String?, groupStatus: String?, groupTeam: [String:Double]?){
        self.kasamID = kasamID
        self.kasamName = kasamName
        self.joinedDate = joinedDate
        self.startTime = startTime
        self.currentDay = currentDay
        self.repeatDuration = repeatDuration
        self.image = image ?? ""
        self.metricType = metricType ?? ""
        self.programDuration = programDuration
        self.streakInfo = streakInfo
        self.displayStatus = displayStatus
        self.percentComplete = percentComplete
        self.badgeList = badgeList
        self.benefitsThresholds = benefitsThresholds
        self.dayTrackerArray = dayTrackerArray
        self.groupID = groupID
        self.groupAdmin = groupAdmin
        self.groupStatus = groupStatus
        self.groupTeam = groupTeam
    }
}

class CompletedKasamFormat {
    var kasamID: String
    var kasamName: String
    var daysCompleted: Int
    var imageURL: URL
    var firstDate: String?
    var lastDate: String?
    var metric: String
    
    init(kasamID: String, kasamName: String, daysCompleted: Int, imageURL: URL, firstDate: String?, lastDate: String?, metric: String){
        self.kasamID = kasamID
        self.kasamName = kasamName
        self.daysCompleted = daysCompleted
        self.imageURL = imageURL
        self.firstDate = firstDate
        self.lastDate = lastDate
        self.metric = metric
    }
}

class NewKasamLoadFormat{
    var blockTitle: String
    var duration: Int
    var durationMetric: String
    var complete: Bool?
    
    init(blockTitle: String, duration: Int, durationMetric: String, complete: Bool?){
        self.blockTitle = blockTitle
        self.duration = duration
        self.durationMetric = durationMetric
        self.complete = complete
    }
}

class kasamFollowingFormat {
    var day: Int
    var shortDate: String
    var fullDate: String
    var metric: Double
    var metricAndType: String
    
    init(day: Int, shortDate: String, fullDate:String, metric: Double, metricAndType: String) {
        self.day = day
        self.shortDate = shortDate
        self.fullDate = fullDate
        self.metric = metric
        self.metricAndType = metricAndType
    }
}

class newActivityFormat {
    var title: String?
    var description: String?
    var imageToLoad: URL?
    var imageToSave: UIImage?
    var reps: Int?
    var interval: Int?
    var hour: Int?
    var min: Int?
    var sec: Int?
    
    init(title: String?, description: String?, imageToLoad: URL?, imageToSave: UIImage?, reps: Int?, interval: Int?, hour: Int?, min: Int?, sec: Int?) {
        self.title = title
        self.description = description
        self.imageToLoad = imageToLoad
        self.imageToSave = imageToSave
        self.reps = reps
        self.interval = interval
        self.hour = hour
        self.min = min
        self.sec = sec
    }
}

class newBlockFormat {
    var duration: String?
    var title: String?
}

class motivationFormat {
    var motivationID: String
    var motivationText: String
    
    init(motivationID: String, motivationText: String) {
        self.motivationID = motivationID
        self.motivationText = motivationText
    }
}

class KasamActivityCellFormat {
    var kasamID: String
    var blockID: String
    var activityTitle: String
    var activityDescription: String
    var increment: String?
    var currentMetric: Double
    var totalMetric: Int
    var imageURL: String?
    var videoURL: String?
    var image: UIImage?
    var type: String
    var currentOrder: Int
    var totalOrder: Int
    
    init(kasamID: String, blockID: String, title: String, description: String, increment: String?, currentMetric: Double, totalMetric: Int, imageURL: String?, videoURL: String?, image: UIImage?, type: String, currentOrder: Int, totalOrder: Int){
        self.kasamID = kasamID
        self.blockID = blockID
        self.activityTitle = title
        self.activityDescription = description
        self.increment = increment
        self.currentMetric = currentMetric
        self.totalMetric = totalMetric
        self.imageURL = imageURL
        self.videoURL = videoURL
        self.image = image
        self.type = type
        self.currentOrder = currentOrder
        self.totalOrder = totalOrder
    }
}

class BlockFormat {
    var blockID: String
    var title: String
    var imageURL: URL?
    var image: UIImage?
    var order: String
    var duration: String
    
    init(blockID: String, title: String, order: String, duration: String, imageURL: URL?, image: UIImage?){
        self.blockID = blockID
        self.title = title
        self.imageURL = imageURL
        self.image = image
        self.order = order
        self.duration = duration
    }
}

class Tracker {
    var userName: String
    var progress: Int
    
    init(userName: String, progress: Int) {
        self.userName = userName
        self.progress = progress
    }
    
}

class TrackerTableView: UITableView {
    var maxHeight: CGFloat = UIScreen.main.bounds.size.height
    
    override func reloadData() {
        super.reloadData()
        self.invalidateIntrinsicContentSize()
        self.layoutIfNeeded()
    }
    
    override var intrinsicContentSize: CGSize {
        let height = min(contentSize.height, maxHeight)
        return CGSize(width: contentSize.width, height: height)
    }
    
}

class UserStatsFormat {
    var kasamID: String
    var kasamTitle: String
    var imageURL: URL
    var joinedDate: Date
    var endDate: Date?
    var metricType: String
    
    init(kasamID: String, kasamTitle: String, imageURL: URL, joinedDate: Date, endDate: Date?, metricType: String){
        self.kasamID = kasamID
        self.kasamTitle = kasamTitle
        self.imageURL = imageURL
        self.joinedDate = joinedDate
        self.endDate = endDate
        self.metricType = metricType
    }
}

class EditMyKasamFormat {
    var kasamID: String
    var kasamTitle: String
    var imageURL: URL
    
    init(kasamID: String, kasamTitle: String, imageURL: URL){
        self.kasamID = kasamID
        self.kasamTitle = kasamTitle
        self.imageURL = imageURL
    }
}
