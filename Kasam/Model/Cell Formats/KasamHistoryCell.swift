//
//  KasamHistoryTableCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-09-28.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Charts

class KasamHistoryTableCell: UITableViewCell {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var metricLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    func setBlock(block: kasamFollowingFormat) {
        dateLabel.text = block.date
        metricLabel.text = block.metric
    }
}
