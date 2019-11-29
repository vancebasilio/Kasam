//
//  CompletedKasamCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-11-28.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import Foundation

class CompletedKasamCell: UITableViewCell {
    
    @IBOutlet weak var kasamImage: UIImageView!
    @IBOutlet weak var kasamName: UILabel!
    
    func setBlock(block: UserStatsFormat) {
        kasamImage.sd_setImage(with: block.imageURL, placeholderImage: UIImage(named: "placeholder.png"))
        kasamImage.layer.cornerRadius = 8.0
        kasamImage.clipsToBounds = true
        kasamName.text = block.kasamTitle
    }
    
    
    
    
    
    
}
