//
//  KasamFormat.swift
//  Kasam 1.0
//
//  Created by Vance Basilio on 2019-04-22.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Foundation

class KasamFormat {

var kasamTitle : String = ""
var kasamTiming: String = ""
var kasamImage: String = ""
var kasamID: String = ""

}

class KasamPreference {
    
    var kasamID: String
    var joinedDate: Date
    var startTime: String
    
    init(kasamID: String, joinedDate: Date, startTime: String){
        self.kasamID = kasamID
        self.joinedDate = joinedDate
        self.startTime = startTime
    }
}
