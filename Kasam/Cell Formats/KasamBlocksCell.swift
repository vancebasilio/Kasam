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
    @IBOutlet weak var imageHolder: UIView!
    @IBOutlet weak var blockImage: UIImageView!
    @IBOutlet weak var dayNo: UILabel!
    @IBOutlet weak var blockDuration: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var challengeBenefitsLabel: UILabel!
    @IBOutlet weak var challengeBenefitsLabelTopConstraint: NSLayoutConstraint!
    
    var benefitsArray = [""]
    
    func setBlock(block: BlockFormat, single: Bool?) {
        if block.image != nil {
            blockImage.image = block.image!
        } else {
            blockImage.sd_setImage(with: block.imageURL, placeholderImage: PlaceHolders.kasamLoadingImage)
        }
        imageHolder.layer.cornerRadius = 10
        playButton.setIcon(icon: .fontAwesomeSolid(.playCircle), iconSize: 25, color: UIColor.white, backgroundColor: UIColor.clear, forState: .normal)
        blockTitle.text = block.title
        if single == true {
            if benefitsArray.count < 6 {
                dayNo.text = block.title
                dayNo.textColor = UIColor.black
                dayNo.font = dayNo.font.withSize(15)
            } else {
                dayNo.isHidden = true
                challengeBenefitsLabelTopConstraint.constant = -17
            }
            blockTitle.isHidden = true
            setChallengeBenefits()
        } else {
            dayNo.text = "DAY \(block.order)"
        }
        blockDuration.text = block.duration
    }
    
    func setBasicKasamBenefits() {
        imageHolder.isHidden = true
        dayNo.text = "Benefits:"
        dayNo.textColor = UIColor.black
        dayNo.font = dayNo.font.withSize(16)
        challengeBenefitsLabel.font = challengeBenefitsLabel.font.withSize(15)
        blockTitle.isHidden = true
        blockImage.isHidden = true
        blockDuration.isHidden = true
        setChallengeBenefits()
    }
    
    func setChallengeBenefits(){
        challengeBenefitsLabel.isHidden = false
        let bulletList = NSMutableAttributedString()
        let style = NSMutableParagraphStyle()
        style.alignment = .left
        for benefit in benefitsArray {
            let formattedString = "\u{2022} \(benefit)\n"
            let attributedString = NSMutableAttributedString(string: formattedString)
            attributedString.addAttributes([NSAttributedString.Key.paragraphStyle : style], range: NSMakeRange(0, attributedString.length))
            bulletList.append(attributedString)
        }
        challengeBenefitsLabel.attributedText = bulletList
        challengeBenefitsLabel.numberOfLines = benefitsArray.count
    }
}
