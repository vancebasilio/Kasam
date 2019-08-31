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
    
    @IBOutlet weak var blockTitle: UILabel!
    @IBOutlet weak var blockImage: UIImageView!
    @IBOutlet weak var creatorName: UILabel!
    @IBOutlet weak var blockDurationImage: UILabel!
    @IBOutlet weak var blockDuration: UILabel!
    @IBOutlet weak var blockholder: UIView!
    
    func setBlock(block: KasamCalendarBlockFormat, end: Bool) {
        
        blockImage.sd_setImage(with: block.image, placeholderImage: UIImage(named: "placeholder.png"))
        blockTitle.text = block.title
        blockDurationImage.setIcon(icon: .fontAwesomeSolid(.clock), iconSize: 15, color: UIColor.init(hex: 0xcbcbcb))
        blockDuration.text = " \(block.duration)"
        creatorName.text = block.creator
        blockImage.layer.cornerRadius = 8.0
        blockImage.clipsToBounds = true
    }
    
}
