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

class KasamCalendarCell: UITableViewCell {
    
    @IBOutlet weak var kasamName: UILabel!
    @IBOutlet weak var blockTitle: UILabel!
    @IBOutlet weak var blockImage: UIImageView!
    @IBOutlet weak var blockDurationImage: UILabel!
    @IBOutlet weak var blockDuration: UILabel!
    @IBOutlet weak var blockContents: UIView!
    @IBOutlet weak var blockShadow: UIView!
    @IBOutlet weak var statusButton: UIButton!
    
    func setBlock(block: KasamCalendarBlockFormat, end: Bool) {
        kasamName.text = block.kasamName
        blockImage.sd_setImage(with: block.image, placeholderImage: UIImage(named: "placeholder.png"))
        blockTitle.text = block.title
        blockDurationImage.setIcon(icon: .fontAwesomeSolid(.clock), iconSize: 15, color: UIColor.init(hex: 0xcbcbcb))
        blockDuration.text = " \(block.duration)"
        
        blockContents.layer.cornerRadius = 8.0
        blockContents.clipsToBounds = true
        
        blockShadow.layer.cornerRadius = 8.0
        blockShadow.layer.shadowColor = UIColor.black.cgColor
        blockShadow.layer.shadowOpacity = 0.2
        blockShadow.layer.shadowOffset = CGSize.zero
        blockShadow.layer.shadowRadius = 4
        
        var dummy = 0
        
        if dummy == 0 {
            statusButton?.setIcon(icon: .fontAwesomeRegular(.playCircle), iconSize: 30, color: UIColor.colorFour, forState: .normal)
        }
    }
    
}
