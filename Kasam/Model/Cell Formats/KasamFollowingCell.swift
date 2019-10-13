//
//  KasamFollowingCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-09-28.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import SDWebImage

class KasamFollowingCell: UICollectionViewCell {
    
    @IBOutlet weak var topImage: UIImageView!
    @IBOutlet weak var kasamTitle: UILabel!
    
    func setBlock(cell: UserStatsFormat) {
        topImage.sd_setImage(with: cell.imageURL, placeholderImage: UIImage(named: "placeholder.png"))
        topImage.layer.cornerRadius = 8.0
        topImage.clipsToBounds = true
        kasamTitle.text = cell.kasamTitle
    }
}
