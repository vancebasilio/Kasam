//
//  SavedData.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-10-12.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import Foundation

struct SavedData {
    static var kasamArray: [savedKasamFormat] = []
    
    static func clearKasamArray(){
        kasamArray.removeAll()
    }

    static func addKasam(kasam: savedKasamFormat) {
        self.kasamArray.append(kasam)
        print(kasamArray.count)
    }
}
