//
//  GroupStatsCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2020-08-02.
//  Copyright © 2020 Vance Basilio. All rights reserved.
//

import UIKit

class GroupStatsCell: UITableViewCell {
    
    @IBOutlet weak var placeStanding: UIButton!
    @IBOutlet weak var levelLine: UIView!
    @IBOutlet weak var levelLineHolder: UIView!
    @IBOutlet weak var levelLineProgress: NSLayoutConstraint!
    @IBOutlet weak var userInitials: UILabel!
    @IBOutlet weak var percentProgress: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        levelLine.layer.cornerRadius = 4
        placeStanding.backgroundColor = UIColor.init(hex: 0x8F8F8F)
        placeStanding.layer.cornerRadius = 4
    }
}
