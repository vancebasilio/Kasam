//
//  BlocksCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-05-05.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import SDWebImage

class BlocksCell: UITableViewCell {
    
    @IBOutlet weak var blockTitle: UILabel!
    @IBOutlet weak var blockImage: UIImageView!
    @IBOutlet weak var dayNo: UILabel!
    @IBOutlet weak var blockDuration: UILabel!
    @IBOutlet weak var benefitsLabel: UILabel!
    
    func setBlock(block: BlockFormat) {
        if block.image != nil {
            blockImage.image = block.image!
        } else {
            blockImage.sd_setImage(with: block.imageURL, placeholderImage: PlaceHolders.kasamLoadingImage)
        }
        blockTitle.text = block.title
        dayNo.text = "DAY \(block.order)"
        blockDuration.text = block.duration
        blockImage.layer.cornerRadius = 10
        blockImage.clipsToBounds = true
    }
    
    func setBenefits(benefits: String) {
        benefitsLabel.isHidden = false
        blockTitle.isHidden = true
        blockImage.isHidden = true
        dayNo.isHidden = true
        blockDuration.isHidden = true
        benefitsLabel.text = "\u{2022} \(benefits)"
    }
}
