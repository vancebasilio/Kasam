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
    @IBOutlet weak var statsPlaceholderIcon: UIImageView!
    @IBOutlet weak var statsPlaceholderIconTopMargin: NSLayoutConstraint!
    @IBOutlet weak var statsPlaceholderIconHeight: NSLayoutConstraint!
    
    func setBlock(cell: UserStatsFormat) {
        statsPlaceholderIcon.isHidden = true
        topImage.sd_setImage(with: cell.imageURL, placeholderImage: UIImage(named: "placeholder.png"))
        topImage.layer.cornerRadius = 8.0
        topImage.clipsToBounds = true
        kasamTitle.text = cell.kasamTitle
    }
    
    func setMyChalloBlock(cell: EditMyChalloFormat) {
        topImage.sd_setImage(with: cell.imageURL, placeholderImage: UIImage(named: "placeholder.png"))
        topImage.layer.cornerRadius = 8.0
        topImage.clipsToBounds = true
        kasamTitle.text = cell.kasamTitle
    }
    
    func setPlaceholder(){
        statsPlaceholderIcon.isHidden = false
        statsPlaceholderIconHeight.constant = topImage.frame.height / 2
        statsPlaceholderIconTopMargin.constant = ((topImage.frame.height / 2) - (statsPlaceholderIcon.frame.height / 2))
        topImage.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        statsPlaceholderIcon.setIcon(icon: .fontAwesomeSolid(.dice), textColor: .white, backgroundColor: .clear, size: CGSize(width: statsPlaceholderIconHeight.constant, height: statsPlaceholderIconHeight.constant))
        topImage.layer.cornerRadius = 8.0
        topImage.clipsToBounds = true
        kasamTitle.text = "Add a Challo"
    }
}
