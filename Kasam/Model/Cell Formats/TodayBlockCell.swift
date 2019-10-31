//
//  BlocksCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-05-05.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import SDWebImage
import SwiftIcons

protocol TodayCellDelegate {
    func clickedButton(kasamID: String, blockID: String, status: String)
}

class TodayBlockCell: UITableViewCell {
    
    @IBOutlet weak var kasamName: UILabel!
    @IBOutlet weak var blockImage: UIImageView!
    @IBOutlet weak var dayNumber: UILabel!
    @IBOutlet weak var blockDuration: UILabel!
    @IBOutlet weak var blockContents: UIView!
    @IBOutlet weak var blockShadow: UIView!
    @IBOutlet weak var statusButton: UIButton!
    
    @IBOutlet weak var day1: UIView!
    @IBOutlet weak var day2: UIView!
    @IBOutlet weak var day3: UIView!
    @IBOutlet weak var day4: UIView!
    @IBOutlet weak var day5: UIView!
    @IBOutlet weak var day6: UIView!
    @IBOutlet weak var day7: UIView!
    @IBOutlet weak var day8: UIView!
    @IBOutlet weak var day9: UIView!
    @IBOutlet weak var day10: UIView!
    @IBOutlet weak var day11: UIView!
    @IBOutlet weak var day12: UIView!
    @IBOutlet weak var day13: UIView!
    @IBOutlet weak var day14: UIView!
    @IBOutlet weak var day15: UIView!
    @IBOutlet weak var day16: UIView!
    @IBOutlet weak var day17: UIView!
    @IBOutlet weak var day18: UIView!
    @IBOutlet weak var day19: UIView!
    @IBOutlet weak var day20: UIView!
    @IBOutlet weak var day21: UIView!
    @IBOutlet weak var day22: UIView!
    @IBOutlet weak var day23: UIView!
    @IBOutlet weak var day24: UIView!
    @IBOutlet weak var day25: UIView!
    @IBOutlet weak var day26: UIView!
    @IBOutlet weak var day27: UIView!
    @IBOutlet weak var day28: UIView!
    @IBOutlet weak var day29: UIView!
    @IBOutlet weak var day30: UIView!
    
    var delegate: TodayCellDelegate?
    var kasamID: String?
    var blockID: String?
    var processedStatus: String?
    let progress = Progress(totalUnitCount: 30)
    
    func setBlock(block: TodayBlockFormat, end: Bool) {
        let dayTrackerArray = [day1, day2, day3, day4, day5, day6, day7, day8, day9, day10, day11, day12, day13, day14, day15, day16, day17, day18, day19, day20, day21, day22, day23, day24, day25, day26, day27, day28, day29, day30]
        kasamID = block.kasamID
        kasamName.text = block.kasamName
        blockID = block.title
        blockImage.sd_setImage(with: block.image)
        dayNumber.text = "Day \(block.dayOrder) • "
        blockDuration.text = "\(block.duration)"
        processedStatus = block.displayStatus
        
        //DayTracker
        day1.roundedLeft()
        day30.roundedRight()
        let count = block.dayTrackerArray.count
        for i in 0...29 {
            dayTrackerArray[i]?.backgroundColor = UIColor.init(hex: 0xEFEFF4)
        }
        if count > 0 {
            for i in 1...count {
                let day = block.dayTrackerArray[i - 1]
                dayTrackerArray[day - 1]?.backgroundColor = UIColor.init(hex: 0xE1C270)
            }
        }
        
        //Checkbox
        if block.displayStatus == "Checkmark" {
            statusButton?.setIcon(icon: .fontAwesomeRegular(.playCircle), iconSize: 30, color: UIColor.colorFour, forState: .normal)
        } else if block.displayStatus == "Check" {
            statusButton?.setIcon(icon: .fontAwesomeSolid(.checkCircle), iconSize: 30, color: UIColor.init(hex: 0x007f00), forState: .normal)
        } else if block.displayStatus == "Progress" {
            statusButton?.setIcon(icon: .fontAwesomeSolid(.thermometerHalf), iconSize: 30, color: UIColor.colorFour, forState: .normal)
        }

        //Cell formatting
        blockContents.layer.cornerRadius = 8.0
        blockContents.clipsToBounds = true
        
        blockShadow.layer.cornerRadius = 8.0
        blockShadow.layer.shadowColor = UIColor.black.cgColor
        blockShadow.layer.shadowOpacity = 0.2
        blockShadow.layer.shadowOffset = CGSize.zero
        blockShadow.layer.shadowRadius = 4
    }
}
