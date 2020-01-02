//
//  KasamSquareCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-05-06.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import SDWebImage

class KasamSquareCell: UICollectionViewCell {

    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var cellTitle: UILabel!
    @IBOutlet weak var cellType: UILabel!
    @IBOutlet weak var cellDuration: UILabel!
    
    func setBlock(cell: SquareKasamFormat) {
        cellImage.sd_setImage(with: cell.image, placeholderImage: PlaceHolders.challoLoadingImage)
        cellTitle.text = cell.title
        cellType.text = cell.type
        cellDuration.text = cell.duration
        
        cellImage.layer.cornerRadius = 8.0
        cellImage.clipsToBounds = true
    }
    
}
