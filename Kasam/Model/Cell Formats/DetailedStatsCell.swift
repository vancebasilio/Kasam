//
//  KasamHistoryTableCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-09-28.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Charts
import SwipeCellKit

class KasamHistoryTableCell: SwipeTableViewCell {
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var metricLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setBlock(block: kasamFollowingFormat) {
        dayLabel.text = "Day \(block.day)"
        dateLabel.text = block.shortDate
        if block.text != "" {
            metricLabel.text = block.text
        } else {
            metricLabel.text = block.metric
        }
    }
}
