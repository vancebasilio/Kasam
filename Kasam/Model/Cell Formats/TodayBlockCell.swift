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
    @IBOutlet weak var progressBar: UIProgressView!
    
    var delegate: TodayCellDelegate?
    var kasamID: String?
    var blockID: String?
    var processedStatus: String?
    let progress = Progress(totalUnitCount: 30)
    
    func setBlock(block: TodayBlockFormat, end: Bool) {
        kasamID = block.kasamID
        kasamName.text = block.kasamName
        blockID = block.title
        blockImage.sd_setImage(with: block.image, placeholderImage: UIImage(named: "placeholder.png"))
        dayNumber.text = "Day \(block.dayOrder)"
        blockDuration.text = "\(block.duration)"
        processedStatus = block.displayStatus
        
        //Progress Bar
        self.progressBar.setProgress(0.5, animated: true)
        
        //Checkbox
        if block.displayStatus == "Checkmark" {
            statusButton?.setIcon(icon: .fontAwesomeRegular(.playCircle), iconSize: 30, color: UIColor.colorFour, forState: .normal)
        } else if block.displayStatus == "Check" {
            statusButton?.setIcon(icon: .fontAwesomeSolid(.checkCircle), iconSize: 30, color: UIColor.init(hex: 0x007f00), forState: .normal)
        } else if block.displayStatus == "Progress" {
            statusButton?.setIcon(icon: .fontAwesomeSolid(.spinner), iconSize: 30, color: UIColor.colorFour, forState: .normal)
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
    
    @IBAction func statusButtonPressed(_ sender: UIButton) {
        if processedStatus == "Checkmark" {
            statusButton?.setIcon(icon: .fontAwesomeSolid(.checkCircle), iconSize: 30, color: UIColor.init(hex: 0x007f00), forState: .normal)
            delegate?.clickedButton(kasamID: kasamID ?? "", blockID: blockID ?? "", status: "Check")
            processedStatus = "Check"
        } else if processedStatus == "Check" {
            statusButton?.setIcon(icon: .fontAwesomeRegular(.checkCircle), iconSize: 30, color: UIColor.colorFour, forState: .normal)
            delegate?.clickedButton(kasamID: kasamID ?? "", blockID: blockID ?? "", status: "Checkmark")
            processedStatus = "Checkmark"
        }
    }
}
