//
//  SavedData.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-10-12.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import Foundation

struct SavedData {
    static var kasamTodayArray: [KasamSavedFormat] = []                 //kasamTodayArray includes only active kasams that the user is following
    static var kasamArray: [KasamSavedFormat] = []                      //kasamArray includes all kasams that the user is following
    
    static var kasamDict: [String:KasamSavedFormat] = [:]               //kasamDict is used to update kasams when progress is made
    static var dayTrackerDict: [String: [Int:String]] = [:]

    static func addChallo(challo: KasamSavedFormat) {
        self.kasamArray.append(challo)
        self.kasamDict[challo.kasamID] = challo
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

struct PlaceHolders {
    static var challoHeaderPlaceholderImage = UIImage(named: "image-add-placeholder")
    static var challoHeaderPlaceholderURL =  "https://firebasestorage.googleapis.com/v0/b/kasam-coach.appspot.com/o/kasam%2Fimage-add-placeholder.jpg?alt=media&token=491fdb83-2612-4423-9d2e-cdd44ab8157e"
    static var challoActivityPlaceholderURL = "https://firebasestorage.googleapis.com/v0/b/kasam-coach.appspot.com/o/kasam%2Fgiphy%20(1).gif?alt=media&token=e91fd36a-1e2a-43db-b211-396b4b8d65e1"
    
    static var challoLoadingImageURL = "https://firebasestorage.googleapis.com/v0/b/kasam-coach.appspot.com/o/kasam%2Fplaceholder.jpg?alt=media&token=580f119e-b022-4782-9bfd-0464a5b55c7e"
    static var challoLoadingImage = UIImage(named: "placeholder.png")
    
    static var challoActivityRestImageURL = "https://firebasestorage.googleapis.com/v0/b/kasam-coach.appspot.com/o/kasam%2FRest_animation.gif?alt=media&token=347b9eca-6d37-40fc-82f3-12483d71e440"
}
