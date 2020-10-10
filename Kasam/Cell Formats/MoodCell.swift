//
//  KasamStatsCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-09-12.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import SwiftIcons

protocol MoodCellDelegate : class {
    func showPopTipInfo(row: Int, frame: CGRect, type: String)
}

class MoodCell: UICollectionViewCell {
    
    @IBOutlet weak var viewHolder: UIView!
    @IBOutlet weak var levelLine: UIView!
    @IBOutlet weak var levelLineHeight: NSLayoutConstraint!
    @IBOutlet weak var moodIcon: UIButton!

    var cellDelegate: MoodCellDelegate?
    var positionInternal = 0
    var type = ""
    var lineHeightMax = CGFloat(0)
    
    func setBlock(position: Int, value: Double) {
        positionInternal = position
        let width =  NSLayoutConstraint(item: moodIcon, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: viewHolder.frame.width)
        let height = NSLayoutConstraint(item: moodIcon, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 18)
        NSLayoutConstraint.activate([height,width])
        
        lineHeightMax = (viewHolder.frame.height - 20)
        levelLineHeight.constant = CGFloat(value) * lineHeightMax
        levelLine.layer.cornerRadius = 5
        type = moodIcon.setMoodIcon(position: position)
    }
    
    func setLevel(value: Double){
        levelLineHeight.constant = CGFloat(value) * lineHeightMax
    }
    
    @IBAction func moodIconPressed(_ sender: Any) {
        cellDelegate?.showPopTipInfo(row: positionInternal, frame: moodIcon.frame, type: type)
    }
}
