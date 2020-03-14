//
//  TodayDayTrackerCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2020-02-23.
//  Copyright © 2020 Vance Basilio. All rights reserved.
//

import UIKit

protocol DayTrackerCellDelegate : class {
    func dayPressed(_ sender: UIButton, kasamOrder: Int, day: Int)
}

class TodayDayTrackerCell: UICollectionViewCell {
    
    @IBOutlet weak var cellButton: UIButton!
    @IBOutlet weak var cellButtonOutline: UIView!
    @IBOutlet weak var dayTrackerDate: UILabel!
    
    var dayTrackerDelegate: DayTrackerCellDelegate?
    var dayInternal = 0
    var kasamOrderInternal = 0
    
    func cellFormatting(today: Bool?, future: Bool){
        cellButton.layer.cornerRadius = cellButton.frame.width / 2
        if today == true {
            cellButton.backgroundColor = UIColor.colorFour                  //gold color
            cellButtonOutline.layer.borderColor = UIColor.colorFour.cgColor
            cellButtonOutline.layer.borderWidth = 2.0
            cellButtonOutline.layer.cornerRadius = cellButtonOutline.frame.size.width / 2
            cellButtonOutline.isHidden = false
        } else {
            cellButtonOutline.isHidden = true
            cellButton.backgroundColor = UIColor.init(hex: 0xEFEFF4)        //grey color
        }
        if future == true {
            cellButton.setTitleColor(UIColor.lightGray, for: .normal)       //grey out buttons that are in the future
            cellButton.isEnabled = false
        } else {
            cellButton.setTitleColor(UIColor.black, for: .normal)           //black text buttons for today and past days
            cellButton.isEnabled = true
        }
    }
    
    func setBlock(kasamOrder: Int, day: Int, status: Bool?, date: String){
        cellButton.setTitle("\(day)", for: .normal)
        dayTrackerDate.text = date
        dayInternal = day
        kasamOrderInternal = kasamOrder
        if status == true {
            cellButton.backgroundColor = UIColor.init(hex: 0x66A058).withAlphaComponent(0.7)        //green color
            cellButtonOutline.layer.borderColor = UIColor.init(hex: 0x66A058).withAlphaComponent(0.7).cgColor
        } else if status == false {
            cellButton.backgroundColor = UIColor.init(hex: 0xcd742c)                                //orange color
            cellButtonOutline.layer.borderColor = UIColor.init(hex: 0xcd742c).cgColor
        }
    }
    
    @IBAction func dayPressed(_ sender: UIButton) {
        dayTrackerDelegate?.dayPressed(sender, kasamOrder: kasamOrderInternal, day: dayInternal)
    }
}


