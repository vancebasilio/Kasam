//
//  KasamFollowingCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-09-28.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import SDWebImage

class MetricTypeCell: UICollectionViewCell {

    @IBOutlet weak var metricTypeIcon: UIImageView!
    @IBOutlet weak var metricTypeBG: UIView!
    @IBOutlet weak var metricTypeTitle: UILabel!
    @IBOutlet weak var metricIconBG: UIView!
    @IBOutlet weak var metricBGOutline: UIView!
    
    func setMetric(title: String) {
        let iconSize = metricIconBG.frame.height * (0.6)
        if title == "Count" {
            metricTypeIcon.setIcon(icon: .fontAwesomeSolid(.sortAmountUp), textColor: .white, backgroundColor: .clear, size: CGSize(width: iconSize, height: iconSize))
        } else if title == "Completion" {
            metricTypeIcon.setIcon(icon: .fontAwesomeSolid(.checkSquare), textColor: .white, backgroundColor: .clear, size: CGSize(width: iconSize, height: iconSize))
        } else {
            metricTypeIcon.setIcon(icon: .fontAwesomeSolid(.stopwatch), textColor: .white, backgroundColor: .clear, size: CGSize(width: iconSize, height: iconSize))
        }
        metricTypeBG.layer.cornerRadius = 20
        metricTypeBG.clipsToBounds = true
        metricIconBG.layer.cornerRadius = 20
        metricIconBG.clipsToBounds = true
        metricBGOutline.layer.cornerRadius = 25
        metricBGOutline.clipsToBounds = true
        metricBGOutline.layer.borderColor = UIColor.init(hex: 0x66A058).cgColor
        metricBGOutline.layer.borderWidth = 3.0
        metricTypeTitle.text = title
    }
}
