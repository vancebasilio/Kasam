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
    @IBOutlet weak var shadow: UIView!
    @IBOutlet weak var contents: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setupFormatting(){
        contents.layer.cornerRadius = 8.0
        contents.clipsToBounds = true
        
        shadow.layer.cornerRadius = 8.0
        shadow.layer.shadowColor = UIColor.colorFive.cgColor
        shadow.layer.shadowOpacity = 0.5
        shadow.layer.shadowOffset = CGSize.zero
        shadow.layer.shadowRadius = 4
    }
}
