//
//  GroupSearchCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2020-08-04.
//  Copyright © 2020 Vance Basilio. All rights reserved.
//

import UIKit

class GroupSearchCell: UITableViewCell {
    
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var checkBox: UIButton!

    override func awakeFromNib() {
        userImage.layer.cornerRadius = userImage.frame.height / 2
        checkBox.setIcon(icon: .fontAwesomeRegular(.circle), iconSize: 30, color: .colorFour, forState: .normal)
    }
    
}
