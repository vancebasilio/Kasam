//
//  DiscoverHorizontalCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-05-27.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import SDWebImage
import Cosmos //for star rating system

class DiscoverHorizontalCell: UICollectionViewCell {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var placeholderView: UIView!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var topImage: UIImageView!
    @IBOutlet weak var kasamTitle: UILabel!
    @IBOutlet weak var kasamRating: CosmosView!
    @IBOutlet weak var kasamType: UIButton!
    
    func setBlock(cell: discoverKasamFormat) {
        containerView.isHidden = false
        placeholderView.isHidden = true
        topImage.sd_setImage(with: cell.image, placeholderImage: PlaceHolders.kasamLoadingImage)
        kasamTitle.text = cell.title
        let rating = Double(cell.rating)
        kasamRating.rating = rating ?? 0
        kasamType = kasamType.setKasamTypeIcon(kasamType: cell.genre, button: self.kasamType, location: "discover")
        topImage.layer.cornerRadius = 8.0
    }
    
    func setPlaceholder(){
        containerView.isHidden = true
        placeholderView.isHidden = false
        createButton.layer.cornerRadius = 20
    }
}
