//
//  KasamFollowingCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-09-28.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import SDWebImage

class TodayChallengesCell: UICollectionViewCell {

    @IBOutlet weak var BGOutline: UIView!
    @IBOutlet weak var kasamImage: UIImageView!
    @IBOutlet weak var kasamTitle: UILabel!
    @IBOutlet weak var kasamDuration: UILabel!
    @IBOutlet weak var BG: UIView!
    @IBOutlet weak var shadow: UIView!
    
    func setBlock(challenge: TodayBlockFormat) {
        kasamImage.sd_setImage(with: challenge.image)
        kasamTitle.text = challenge.kasamName
        kasamDuration.text = challenge.duration
        kasamDuration.textColor = UIColor.colorFive
    }
    
    func cellFormatting(){
        BG.layer.cornerRadius = 20
        BG.clipsToBounds = true
        BG.layer.cornerRadius = 20
        BG.clipsToBounds = true
        BGOutline.layer.cornerRadius = 25
        BGOutline.clipsToBounds = true
        BGOutline.layer.borderWidth = 3.0
        
        shadow.layer.cornerRadius = 20
        shadow.layer.shadowColor = UIColor.black.cgColor
        shadow.layer.shadowOpacity = 0.2
        shadow.layer.shadowOffset = CGSize.zero
        shadow.layer.shadowRadius = 4
    }
}
