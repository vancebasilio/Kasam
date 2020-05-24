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
    
    func setCompletedBlock(block:CompletedKasamFormat) {
        kasamImage.sd_setImage(with: block.imageURL)
        kasamImage.layer.cornerRadius = 8.0
        kasamImage.clipsToBounds = true
        kasamName.text = block.kasamName
        daysCompleted.text = "\(block.daysCompleted) days"
//        let joinedDate = dateConverter(date: block.joinedDate)
//        let endDate = dateConverter(date: block.endDate ?? block.joinedDate)
//        joinedDates.text = "\(joinedDate) - \(endDate)"
    }
    
    func dateConverter(date: Date) -> String {
        let date = date
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateFormat = "MMM d"
        let finalDate = formatter.string(from: date)
        return finalDate
    }
}
