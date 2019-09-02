//
//  DiscoverCategoryCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-06-10.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import SDWebImage

class DiscoverCategoryCell: UICollectionViewCell {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var kasamCreator: UILabel!
    @IBOutlet weak var categoryTitle: UILabel!
    @IBOutlet weak var topImage: UIImageView!
    
    func setBlock(cell: expertKasamFormat) {
        topImage.sd_setImage(with: cell.image, placeholderImage: UIImage(named: "placeholder.png"))
        categoryTitle.text = cell.title
        kasamCreator.text = cell.creator
    }
}
