//
//  KasamTrackerCell.swift
//  
//
//  Created by Vance Basilio on 2019-04-27.
//

import UIKit

class KasamTrackerCell: UITableViewCell {

    @IBOutlet weak var trackerBar: UIView!
    @IBOutlet weak var userName: UILabel!
    
    func setKasam(kasam: Tracker){
        userName.text = kasam.userName
    }
    
}
