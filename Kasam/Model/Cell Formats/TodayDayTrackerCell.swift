//
//  TodayDayTrackerCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2020-02-23.
//  Copyright © 2020 Vance Basilio. All rights reserved.
//

import UIKit

protocol DayTrackerCellDelegate : class {
    func dayPressed(_ sender: UIButton, kasamOrder: Int, day: Int, date: Date?, metricType: String, viewOnly: Bool?)
}

class TodayDayTrackerCell: UICollectionViewCell {
    
    @IBOutlet weak var cellButton: UIButton!
    @IBOutlet weak var cellButtonOutline: UIView!
    @IBOutlet weak var dayTrackerDate: UILabel!
    
    var dayTrackerDelegate: DayTrackerCellDelegate?
    var dayInternal = 0
    var kasamOrderInternal = 0
    var metricTypeInternal = "Checkmark"
    var futureInternal: Bool?
    var dateInternal: Date?
    
    func setBlock(kasamID: String, kasamOrder: Int, day: Int, status: Double, date: Date, today: Bool, future: Bool){
        cellButton.layer.cornerRadius = 12
        if day == 0 {
            cellButton.setTitle("", for: .normal)
        } else {
            cellButton.setTitle("\(day)", for: .normal)
        }
        if SavedData.kasamDict[kasamID]?.sequence == nil {
            dayTrackerDate.text = date.dateToShortString()
        } else {
            if let sequenceDate = SavedData.kasamDict[kasamID]?.dayTrackerArray?[day]?.0 {
                dayTrackerDate.text = dateShortestFormat(date: sequenceDate)
            } else {
                dayTrackerDate.text = date.dateToShortString()
            }
        }
        dayTrackerDate.textColor = UIColor.colorFive
        dayInternal = day
        dateInternal = date
        futureInternal = future
        metricTypeInternal = SavedData.kasamDict[kasamID]!.metricType
        kasamOrderInternal = kasamOrder
        
        //Set Today Button
        if today == true {
            cellButton.backgroundColor = UIColor.colorFour                  //gold color
            cellButton.setTitleColor(UIColor.black, for: .normal)           //black text buttons for today and past days
            cellButtonOutline.layer.borderColor = UIColor.colorFour.cgColor
            cellButtonOutline.layer.borderWidth = 2.0
            cellButtonOutline.layer.cornerRadius = 15
            cellButtonOutline.isHidden = false
        } else {
            cellButtonOutline.isHidden = true
        }
        
        //Set Status Color
        if future == true {
            cellButton.setTitleColor(UIColor.lightGray, for: .normal)       //greys out buttonBG that are in the future
            cellButton.backgroundColor = UIColor.init(hex: 0xEFEFF4)        //greys out buttonText that are in the future
        } else if future != true && status == 0.0 && today != true {
            //Incomplete Kasams
            cellButton.backgroundColor = UIColor.darkGray.lighter
            cellButton.setTitleColor(UIColor.white, for: .normal)
        } else if future != true && status > 0.0 && status < 1.0 {
            //Partially complete Kasams
            cellButton.backgroundColor = UIColor.init(hex: 0xc1deba).withAlphaComponent(0.7)                //light green color
            cellButtonOutline.layer.borderColor = UIColor.init(hex: 0xc1deba).withAlphaComponent(0.7).cgColor
            cellButton.setTitleColor(UIColor.black, for: .normal)
        } else if future != true && status >= 1.0 {
            //Fully complete Kasams
            cellButton.backgroundColor = UIColor.init(hex: 0x66A058).withAlphaComponent(0.7)                //green color
            cellButtonOutline.layer.borderColor = UIColor.init(hex: 0x66A058).withAlphaComponent(0.7).cgColor
            cellButton.setTitleColor(UIColor.black, for: .normal)
        }
    }
    
    @IBAction func dayPressed(_ sender: UIButton) {
        dayTrackerDelegate?.dayPressed(sender, kasamOrder: kasamOrderInternal, day: dayInternal, date: dateInternal, metricType: metricTypeInternal, viewOnly: futureInternal)
    }
}
