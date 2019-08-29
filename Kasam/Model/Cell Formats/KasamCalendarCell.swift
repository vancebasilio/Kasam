//
//  BlocksCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-05-05.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import SDWebImage

class KasamCalendarCell: UITableViewCell {
    
    @IBOutlet weak var blockTitle: UILabel!
    @IBOutlet weak var blockImage: UIImageView!
    @IBOutlet weak var blockGenre: UIImageView!
    @IBOutlet weak var blockHour: UILabel!
    @IBOutlet weak var blockMinute: UILabel!
    @IBOutlet weak var creatorName: UILabel!
    @IBOutlet weak var blockDuration: UILabel!
    @IBOutlet weak var blockholder: UIView!
    @IBOutlet weak var leftView: UIView!
    @IBOutlet weak var rightView: UIView!
    @IBOutlet weak var innerholder: UIView!
    @IBOutlet weak var connectorTop: UIView!
    @IBOutlet weak var connectorBottom: UIView!
    @IBOutlet weak var connectorTconstraint: NSLayoutConstraint!
    @IBOutlet weak var connectorBConstraint: NSLayoutConstraint!
    
    func setBlock(block: KasamCalendarBlockFormat, end: Bool) {
        
        blockImage.sd_setImage(with: block.image, placeholderImage: UIImage(named: "placeholder.png"))
        blockTitle.text = block.title
        blockHour.text = block.hour
        blockMinute.text = block.minute
        blockDuration.text = block.duration
        creatorName.text = block.creator
        blockImage.layer.cornerRadius = 8.0
        blockImage.clipsToBounds = true
        connectorBottom.isHidden = end
    
        innerholder.layer.cornerRadius = 8.0
        innerholder.clipsToBounds = true
        
        connectorTconstraint.constant = (leftView.frame.height + blockGenre.frame.height + 10) / 2
        connectorBConstraint.constant = (leftView.frame.height + blockGenre.frame.height + 10) / 2
        
    }
    
}
