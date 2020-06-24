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
        daysCompleted.text = block.daysCompleted.pluralUnit(unit: "day")
        
        if let snap = block.userHistorySnap {
            if snap.exists() {
                let snapArray = Array((snap.value as! [String:Any]).keys).sorted()
                let joinedDate = convertLongDateToShort(date: snapArray.first!)
                let endDate = convertLongDateToShort(date: snapArray.last ?? joinedDate)
                if joinedDate == endDate {
                    joinedDates.text = "\(joinedDate)"
                } else {
                    joinedDates.text = "\(joinedDate) - \(endDate)"
                }
            } else {
                if let joinedDate = SavedData.kasamDict[block.kasamID]?.joinedDate.dateToShortString() {
                    joinedDates.text = "\(joinedDate)"
                }
            }
        }
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
