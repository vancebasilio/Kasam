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
    
    func setBlock(block: UserStatsFormat) {
        kasamImage.sd_setImage(with: block.imageURL, placeholderImage: PlaceHolders.challoLoadingImage)
        kasamImage.layer.cornerRadius = 8.0
        kasamImage.clipsToBounds = true
        kasamName.text = block.kasamTitle
        let joinedDate = dateConverter(date: block.joinedDate)
        let endDate = dateConverter(date: block.endDate)
        joinedDates.text = "\(joinedDate) - \(endDate)"
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
