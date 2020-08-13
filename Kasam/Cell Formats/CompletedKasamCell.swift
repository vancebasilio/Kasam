//
//  CompletedKasamCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-11-28.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import Foundation

class CompletedKasamCell: UITableViewCell {
    
    @IBOutlet weak var kasamImage: UIImageView!
    @IBOutlet weak var kasamName: UILabel!
    @IBOutlet weak var joinedDates: UILabel!
    @IBOutlet weak var daysCompleted: UILabel!
    
    override func awakeFromNib() {
        kasamImage.layer.cornerRadius = 8.0
    }
    
    func setCompletedBlock(block:CompletedKasamFormat) {
        kasamImage.sd_setImage(with: block.imageURL)
        kasamName.text = block.kasamName
        daysCompleted.text = block.daysCompleted.pluralUnit(unit: "day")
        let joinedDate = convertLongDateToShort(date: block.firstDate!)
        let endDate = convertLongDateToShort(date: block.lastDate!)
        if joinedDate == endDate {
            joinedDates.text = "\(joinedDate)"
        } else {
            joinedDates.text = "\(joinedDate) - \(endDate)"
        }
    }
}
