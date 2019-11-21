//
//  DiscoverBlockFormat.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-05-05.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import Foundation
import UIKit

class freeKasamFormat {
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

class expertKasamFormat {
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

class weekStatsFormat {
    var metricDictionary = [Int:Double]()
    var avgMetric: Int
    var order: Int
    
    init(metricDictionary: [Int: Double], avgMetric: Int, order: Int){
        self.metricDictionary = metricDictionary
        self.avgMetric = avgMetric
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
    var kasamID: String
    var blockID: String
    var image: URL
    var title: String
    var dayOrder: String
    var duration: String
    var kasamName: String
    var statusType: String
    var displayStatus: String
    var dayTrackerArray: [Int]
    
    init(kasamID: String, blockID: String, kasamName: String, title: String, dayOrder: String, duration: String, image: URL, statusType: String, displayStatus: String, dayTrackerArray: [Int]){
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
    var title: String
    var description: String
    var image: UIImage
    var metric: Int
    var type: String
    
    init(title: String, description: String, image: UIImage, metric: Int, type: String) {
        self.title = title
        self.description = description
        self.image = image
        self.metric = metric
        self.type = type
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
    var currentMetric: String
    var image: String
    var type: String
    var currentOrder: Int
    var totalOrder: Int
    var currentText: String
    
    init(kasamID: String, blockID: String, title: String, description: String, totalMetric: String, currentMetric: String, image: String, type: String, currentOrder: Int, totalOrder: Int, currentText: String){
        self.kasamID = kasamID
        self.blockID = blockID
        self.activityTitle = title
        self.activityDescription = description
        self.totalMetric = totalMetric
        self.currentMetric = currentMetric
        self.image = image
        self.type = type
        self.currentOrder = currentOrder
        self.totalOrder = totalOrder
        self.currentText = currentText
    }
}

class BlockFormat {
    var image: URL
    var title: String
    var order: String
    var duration: String
    
    init(title: String, order: String, duration: String, image: URL){
        self.image = image
        self.title = title
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
    var startTime: String
    var kasamOrder: Int
    var status: String
    
    init(kasamID: String, kasamName: String, joinedDate: Date, startTime: String, kasamOrder: Int, status: String){
        self.kasamID = kasamID
        self.kasamName = kasamName
        self.joinedDate = joinedDate
        self.startTime = startTime
        self.kasamOrder = kasamOrder
        self.status = status
    }
}

class UserStatsFormat {
    var kasamID: String
    var kasamTitle: String
    var imageURL: URL
    var metricType: String
    var daysLeft: Int
    
    init(kasamID: String, kasamTitle: String, imageURL: URL, metricType: String, daysLeft: Int){
        self.kasamID = kasamID
        self.kasamTitle = kasamTitle
        self.imageURL = imageURL
        self.metricType = metricType
        self.daysLeft = daysLeft
    }
}
