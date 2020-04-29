//
//  SavedData.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-10-12.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Foundation
import Firebase
import Lottie

struct SavedData {
    static var kasamTodayArray: [KasamSavedFormat] = []                 //kasamTodayArray includes only active kasams that the user is following
    static var kasamArray: [KasamSavedFormat] = []                      //kasamArray includes all kasams that the user is following
    
    static var kasamDict: [String:KasamSavedFormat] = [:]               //kasamDict is used to update kasams when progress is made
    static var dayTrackerDict: [String: [Int:String]] = [:]

    static func addKasam(kasam: KasamSavedFormat) {
        self.kasamArray.append(kasam)
        self.kasamDict[kasam.kasamID] = kasam
    }
}

struct DBRef {
    static let userKasamFollowing = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Kasam-Following")
    static let coachKasams = Database.database().reference().child("Coach-Kasams")
    static let userCreator = Database.database().reference().child("Users")
    static let currentUser = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!)
    static let motivationImages = Database.database().reference().child("Assets").child("Motivation Images")
    static let userHistory = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("History")
    static let userKasams = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Kasams")
}

struct Assets {
    static var levelsArray = [""]
}

struct Dates {
    static func getCurrentDate() -> String {
        let currentDateTime = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateFormat = "yyyy-MM-dd"                                     //***keep this value the same as below
        let finalDate = formatter.string(from: currentDateTime)
        return finalDate
    }
}

struct Animations {
    static let kasamBadges = [Animation.named("crownMedal"), Animation.named("goldCup"), Animation.named("crownSmooth")]
}

struct NewKasam {
    static var editKasamCheck = false
    static var kasamID = ""
    static var kasamName = ""
    static var kasamDescription = ""
    static var chosenMetric = ""
    static var loadedInKasamImage = UIImage()
    static var loadedInKasamImageURL = URL(string: "")
    static var kasamImageToSave = UIImage()
    static var dataLoadCheck = false
    static var numberOfBlocks = 1
    static var kasamTransferArray = [Int:NewKasamLoadFormat]()
    static var fullActivityMatrix = [Int: [Int: newActivityFormat]]()
    
    static func resetKasam(){
        self.editKasamCheck = false
        self.kasamID = ""
        self.kasamName = ""
        self.kasamDescription = ""
        self.chosenMetric = ""
        self.loadedInKasamImage = UIImage()
        self.loadedInKasamImageURL = URL(string: "")
        self.kasamImageToSave = UIImage()
        self.dataLoadCheck = false
        self.numberOfBlocks = 1
        self.kasamTransferArray.removeAll()
        self.fullActivityMatrix.removeAll()
    }
}

struct PlaceHolders {
    static var kasamHeaderPlaceholderImage = UIImage(named: "image-add-placeholder")
    static var kasamHeaderPlaceholderURL =  "https://firebasestorage.googleapis.com/v0/b/kasam-coach.appspot.com/o/kasam%2Fimage-add-placeholder.jpg?alt=media&token=491fdb83-2612-4423-9d2e-cdd44ab8157e"
    static var kasamActivityPlaceholderURL = "https://firebasestorage.googleapis.com/v0/b/kasam-coach.appspot.com/o/kasam%2Fgiphy%20(1).gif?alt=media&token=e91fd36a-1e2a-43db-b211-396b4b8d65e1"
    
    static var kasamLoadingImageURL = "https://firebasestorage.googleapis.com/v0/b/kasam-coach.appspot.com/o/kasam%2Fplaceholder.jpg?alt=media&token=580f119e-b022-4782-9bfd-0464a5b55c7e"
    static var kasamLoadingImage = UIImage(named: "placeholder.png")
    
    static var kasamActivityRestImageURL = "https://firebasestorage.googleapis.com/v0/b/kasam-coach.appspot.com/o/kasam%2FRest_animation.gif?alt=media&token=347b9eca-6d37-40fc-82f3-12483d71e440"
    
    static var motivationPlaceholder = UIImage(named: "today_motivation_background4")
}
