//
//  SavedData.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-10-12.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import Foundation

struct SavedData {
    static var kasamArray: [KasamSavedFormat] = []
    static var kasamDict: [String:KasamSavedFormat] = [:]
    
    static func clearKasamArray(){
        kasamArray.removeAll()
    }

    static func addKasam(kasam: KasamSavedFormat) {
        self.kasamArray.append(kasam)
        self.kasamDict[kasam.kasamID] = kasam
    }
}
