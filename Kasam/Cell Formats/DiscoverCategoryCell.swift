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
    @IBOutlet weak var kasamGenre: UIButton!
    @IBOutlet weak var kasamGenreWidth: NSLayoutConstraint!
    @IBOutlet weak var categoryTitle: UILabel!
    @IBOutlet weak var topImage: UIImageView!
    
    func setBlock(cell: discoverKasamFormat) {
        topImage.sd_setImage(with: cell.image, placeholderImage: PlaceHolders.kasamLoadingImage)
        categoryTitle.text = cell.title
        kasamGenre.setTitle(cell.genre, for: .normal)
        kasamGenre.sizeToFit()
        kasamGenre.backgroundColor = UIColor.colorFour
        kasamGenreWidth.constant = kasamGenre.frame.size.width + 20
        kasamGenre.layer.cornerRadius = kasamGenre.frame.height / 3
    }
}
