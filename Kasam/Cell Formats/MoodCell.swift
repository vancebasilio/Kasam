//
//  KasamStatsCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-09-12.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import SwiftIcons

class MoodCell: UICollectionViewCell {
    
    @IBOutlet weak var viewHolder: UIView!
    @IBOutlet weak var levelLine: UIView!
    @IBOutlet weak var levelLineHeight: NSLayoutConstraint!
    @IBOutlet weak var moodLabel: UILabel!
    
    override func awakeFromNib() {
        
    }
    
    func setBlock(position: Int, value: Double) {
        let iconSize = CGFloat(18)
        switch position {
            case 0: moodLabel.setIcon(icon: .icofont(.brain), iconSize: iconSize, color: .darkGray, bgColor: .clear)
            case 1: moodLabel.setIcon(icon: .icofont(.muscle), iconSize: iconSize, color: .darkGray, bgColor: .clear)
            case 2: moodLabel.setIcon(icon: .icofont(.university), iconSize: iconSize, color: .darkGray, bgColor: .clear)
            case 3: moodLabel.setIcon(icon: .icofont(.money), iconSize: iconSize, color: .darkGray, bgColor: .clear)
            case 4: moodLabel.setIcon(icon: .icofont(.usersAlt5), iconSize: iconSize, color: .darkGray, bgColor: .clear)
            case 5: moodLabel.setIcon(icon: .icofont(.home), iconSize: iconSize, color: .darkGray, bgColor: .clear)
            case 6: moodLabel.setIcon(icon: .icofont(.heart), iconSize: iconSize, color: .darkGray, bgColor: .clear)
            case 7: moodLabel.setIcon(icon: .fontAwesomeSolid(.fire), iconSize: iconSize - 3, color: .darkGray, bgColor: .clear)
            default: moodLabel.setIcon(icon: .icofont(.heart), iconSize: iconSize, color: .darkGray, bgColor: .clear)
        }
        levelLineHeight.constant = CGFloat(value) * (viewHolder.frame.height - 20)
        levelLine.layer.cornerRadius = 5
    }
}
