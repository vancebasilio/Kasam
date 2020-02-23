//
//  DiscoverBlockFormat.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-05-05.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import Foundation
import UIKit

class discoverKasamFormat {
    var image: URL
    var title: String
    var rating: String
    var creator: String
    var kasamID: String
    
    init(title: String, image: URL, rating: String, creator: String, kasamID: String){
        self.image = image
        self.title = title
        self.rating = rating
        self.creator = creator
        self.kasamID = kasamID
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
    var order: Int
    
    init(kasamID: String, kasamTitle: String, imageURL: URL, daysLeft: Int, metricType: String, metricDictionary: [Int: Double], avgMetric: Int, order: Int){
        self.kasamID = kasamID
        self.kasamTitle = kasamTitle
        self.imageURL = imageURL
        self.daysLeft = daysLeft
        self.metricType = metricType
        self.avgMetric = avgMetric
        self.metricDictionary = metricDictionary
        self.order = order
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

class TodayBlockFormat {
    var kasamOrder: Int
    var kasamID: String
    var blockID: String
    var image: URL
    var title: String
    var dayOrder: String
    var duration: String
    var kasamName: String
    var statusType: String
    var displayStatus: String
    var dayTrackerArray: [(Int,Bool)]?
    
    init(kasamOrder: Int, kasamID: String, blockID: String, kasamName: String, title: String, dayOrder: String, duration: String, image: URL, statusType: String, displayStatus: String, dayTrackerArray: [(Int,Bool)]?){
        self.kasamOrder = kasamOrder
        self.kasamID = kasamID
        self.blockID = blockID
        self.kasamName = kasamName
        self.dayOrder = dayOrder
        self.image = image
        self.title = title
        self.duration = duration
        self.statusType = statusType
        self.displayStatus = displayStatus
        self.dayTrackerArray = dayTrackerArray
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
    var date: String
    var metric: String
    var text: String
    
    init(day: Int, date: String, metric: String, text: String) {
        self.day = day
        self.date = date
        self.metric = metric
        self.text = text
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
    var totalMetric: String
    var increment: String?
    var currentMetric: String
    var imageURL: String
    var image: UIImage?
    var type: String
    var currentOrder: Int
    var totalOrder: Int
    var currentText: String
    
    init(kasamID: String, blockID: String, title: String, description: String, totalMetric: String, increment: String?, currentMetric: String, imageURL: String, image: UIImage?, type: String, currentOrder: Int, totalOrder: Int, currentText: String){
        self.kasamID = kasamID
        self.blockID = blockID
        self.activityTitle = title
        self.activityDescription = description
        self.totalMetric = totalMetric
        self.increment = increment
        self.currentMetric = currentMetric
        self.imageURL = imageURL
        self.image = image
        self.type = type
        self.currentOrder = currentOrder
        self.totalOrder = totalOrder
        self.currentText = currentText
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

class KasamFormat {
    var kasamTitle : String = ""
    var kasamTiming: String = ""
    var kasamImage: String = ""
    var kasamID: String = ""
    
}

class KasamSavedFormat {
    var kasamID: String
    var kasamName: String
    var joinedDate: Date
    var endDate: Date
    var startTime: String
    var kasamOrder: Int
    var image: String
    var metricType: String
    var currentStatus: String
    var pastKasamJoinDates: [String]
    var type: String
    
    init(kasamID: String, kasamName: String, joinedDate: Date, endDate: Date, startTime: String, kasamOrder: Int, image: String?, metricType: String?, currentStatus: String, pastKasamJoinDates: [String], type: String){
        self.kasamID = kasamID
        self.kasamName = kasamName
        self.joinedDate = joinedDate
        self.endDate = endDate
        self.startTime = startTime
        self.kasamOrder = kasamOrder
        self.image = image ?? ""
        self.metricType = metricType ?? ""
        self.currentStatus = currentStatus
        self.pastKasamJoinDates = pastKasamJoinDates
        self.type = type
    }
}

class UserStatsFormat {
    var kasamID: String
    var kasamTitle: String
    var imageURL: URL
    var joinedDate: Date
    var endDate: Date
    var metricType: String
    var order: Int
    
    init(kasamID: String, kasamTitle: String, imageURL: URL, joinedDate: Date, endDate: Date, metricType: String, order: Int){
        self.kasamID = kasamID
        self.kasamTitle = kasamTitle
        self.imageURL = imageURL
        self.joinedDate = joinedDate
        self.endDate = endDate
        self.metricType = metricType
        self.order = order
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
