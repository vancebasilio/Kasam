//
//  SavedData.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-10-12.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Foundation
import FirebaseDatabase
import FirebaseAuth
import Lottie
import SwiftEntryKit

struct SavedData {
    static var todayKasamBlocks = ["personal": [(kasamID: String, data: TodayBlockFormat)](), "group": [(kasamID: String, data: TodayBlockFormat)]()]
    static var upcomingKasamBlocks = ["personal": [(kasamID: String, data: TodayBlockFormat)](), "group": [(kasamID: String, data: TodayBlockFormat)]()]
    static var kasamDict: [String:KasamSavedFormat] = [:]
    
    static var trophiesAchieved: [String: (kasamName: String, kasamTrophies: [(completedDate: String, trophyThreshold: Int)])] = [:]
    static var trophiesCount = 0                                    //All badges achieved only
    static var userType = "Basic"
    static var userID = Auth.auth().currentUser?.uid ?? ""
    
    static func wipeAllData(){
        todayKasamBlocks = [:]
        kasamDict = [:]
        trophiesAchieved = [:]
        trophiesCount = 0
        userType = "Basic"
    }
}

struct DBRef {
    static let coachKasams = Database.database().reference().child("Coach-Kasams")
    static let coachKasamIndex = Database.database().reference().child("Coach-Kasam-Index")
    static let users = Database.database().reference().child("Users")
    static let userEmails = Database.database().reference().child("User-Emails")
    
    static var userPersonalFollowing = Database.database().reference().child("Users").child(SavedData.userID).child("Kasam-Following")
    static var userTrophies = Database.database().reference().child("Users").child(SavedData.userID).child("Trophies")
    static var userInfo = Database.database().reference().child("Users").child(SavedData.userID).child("Info")
    static var userKasams = Database.database().reference().child("User-Kasams").child(SavedData.userID)
    static var userPersonalHistory = Database.database().reference().child("Users").child(SavedData.userID).child("History")
    static var userHistoryTotals = Database.database().reference().child("Users").child(SavedData.userID).child("History-Totals")
    static var userGroupFollowing = Database.database().reference().child("Users").child(SavedData.userID).child("Group-Following")
    
    static func resetDBs(){         //for when a user logs out and logs back into a different account
        DBRef.userPersonalFollowing = Database.database().reference().child("Users").child(SavedData.userID).child("Kasam-Following")
        DBRef.userTrophies = Database.database().reference().child("Users").child(SavedData.userID).child("Trophies")
        DBRef.userInfo = Database.database().reference().child("Users").child(SavedData.userID).child("Info")
        DBRef.userKasams = Database.database().reference().child("User-Kasams").child(SavedData.userID)
        DBRef.userPersonalHistory = Database.database().reference().child("Users").child(SavedData.userID).child("History")
        DBRef.userHistoryTotals = Database.database().reference().child("Users").child(SavedData.userID).child("History-Totals")
        DBRef.userGroupFollowing = Database.database().reference().child("Users").child(SavedData.userID).child("Group-Following")
    }
}

struct PopupAttributes{
    static func bottom() -> EKAttributes {
        var attributes: EKAttributes
        attributes = .bottomFloat
        attributes.displayMode = .light
        attributes.displayDuration = .infinity
        attributes.hapticFeedbackType = .none
        attributes.screenBackground = .color(color: EKColor(UIColor.black.withAlphaComponent(0.3)))
        attributes.entryBackground = .color(color: .white)
        attributes.screenInteraction = .dismiss
        attributes.entryInteraction = .absorbTouches
        attributes.entranceAnimation = .init(translate: .init(duration: 0.5, spring: .init(damping: 1, initialVelocity: 0)))
        attributes.exitAnimation = .init(translate: .init(duration: 0.35))
        attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.35)))
        attributes.shadow = .active(with: .init(color: .black, opacity: 0.3, radius: 6))
        attributes.roundCorners = .all(radius: 20)
        attributes.positionConstraints.verticalOffset = 0
        attributes.positionConstraints.safeArea = .empty(fillSafeArea: true)
        attributes.statusBar = .dark
        return attributes
    }
    
    static func center() -> EKAttributes {
        var attributes: EKAttributes
        attributes = .centerFloat
        attributes.displayMode = .light
        attributes.displayDuration = .infinity
        attributes.hapticFeedbackType = .none
        attributes.screenBackground = .color(color: EKColor(UIColor.black.withAlphaComponent(0.3)))
        attributes.entryBackground = .color(color: .white)
        attributes.screenInteraction = .dismiss
        attributes.entryInteraction = .absorbTouches
        attributes.entranceAnimation = .init(translate: .init(duration: 0.5, spring: .init(damping: 1, initialVelocity: 0)))
        attributes.exitAnimation = .init(translate: .init(duration: 0.35))
        attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.35)))
        attributes.shadow = .active(with: .init(color: .black, opacity: 0.3, radius: 6))
        attributes.roundCorners = .all(radius: 20)
        attributes.positionConstraints.safeArea = .overridden
        attributes.statusBar = .dark
        return attributes
    }
}

struct Assets {
    static var levelsArray = ["Easy", "Medium", "Hard"]
    static var featuredKasams: [String]? = ["-LqRRHDQuwf2tJmoNoaa"]
    static var discoverCriteria = ["Fitness", "Health", "My Kasams"]
}

struct Icons {
    static let categoryIcons: [String] = ["Fitness", "Personal", "Health", "Spiritual", "Writing"]
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
    static var chosenGenre = "Personal"
    static var benefits = ""
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
        self.chosenGenre = "Personal"
        self.benefits = ""
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
    static var kasamHeaderPlaceholderURL =  "https://firebasestorage.googleapis.com/v0/b/kasam-coach.appspot.com/o/placeholders%2Fkasam-header-placehodler.jpg?alt=media&token=be102264-4a50-4a36-b1fd-2191840a23e3"
    
    static var kasamHeaderPlaceholderImage = UIImage()
    
    static var kasamActivityPlaceholderURL = "https://firebasestorage.googleapis.com/v0/b/kasam-coach.appspot.com/o/kasam%2Fgiphy%20(1).gif?alt=media&token=e91fd36a-1e2a-43db-b211-396b4b8d65e1"
    
    static var kasamLoadingImageURL = "https://firebasestorage.googleapis.com/v0/b/kasam-coach.appspot.com/o/kasam%2Fplaceholder.jpg?alt=media&token=580f119e-b022-4782-9bfd-0464a5b55c7e"
    
    static var kasamLoadingImage = UIImage(named: "placeholder-logo")
    
    static var kasamActivityRestImageURL = "https://firebasestorage.googleapis.com/v0/b/kasam-coach.appspot.com/o/kasam%2FRest_animation.gif?alt=media&token=347b9eca-6d37-40fc-82f3-12483d71e440"
    
    static var motivationPlaceholder = UIImage(named: "today_motivation_background4")
}
