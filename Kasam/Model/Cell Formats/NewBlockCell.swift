//
//  NewBlockCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-10-14.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import SkyFloatingLabelTextField

class NewBlockCell: UITableViewCell {
    
    @IBOutlet weak var durationTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var titleTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var dayNumber: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}
