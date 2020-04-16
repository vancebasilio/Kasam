//
//  KasamFollowingCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-09-28.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import SDWebImage

protocol CollectionCellDelegate : class {
    func updateKasamButtonPressed(_ sender: UIButton, kasamOrder: Int)
    func openKasamBlock(_ sender: UIButton, kasamOrder: Int, day: Int?)
    func goToChallengeKasamHolder(_ sender: UIButton, kasamOrder: Int)
    func completeAndUnfollow(_ sender: UIButton, kasamOrder: Int)
}

class TodayChallengesCell: UICollectionViewCell {

    @IBOutlet weak var BGOutline: UIView!
    @IBOutlet weak var kasamImage: UIImageView!
    @IBOutlet weak var kasamTitle: UIButton!
    @IBOutlet weak var kasamDuration: UILabel!
    @IBOutlet weak var statusIcon: UIButton!
    @IBOutlet weak var statusButtonHeight: NSLayoutConstraint!
    @IBOutlet weak var percentComplete: UIButton!
    @IBOutlet weak var BG: UIView!
    @IBOutlet weak var shadow: UIView!
    
    var cellDelegate: CollectionCellDelegate?
    var row = 0
    var kasamType = ""
    var tempBlock: TodayBlockFormat?
    
    func setBlock(challenge: TodayBlockFormat) {
        tempBlock = challenge
        kasamImage.sd_setImage(with: challenge.image)
        kasamImage.alpha = 0.7
        kasamTitle.setTitle(challenge.kasamName, for: .normal)
        kasamDuration.text = challenge.duration
        kasamDuration.textColor = UIColor.colorFive
        kasamType = challenge.kasamType
        statusUpdate()
    }
    
    @IBAction func kasamTitleSelected(_ sender: UIButton) {
        cellDelegate?.goToChallengeKasamHolder(sender, kasamOrder: row)
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
        
        percentComplete.backgroundColor = UIColor.black
        percentComplete.layer.cornerRadius = 8.0
        percentComplete.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
    }
    
    func statusUpdate(){
        //Update percentage complete for Challenge Kasams
        let iconSize = CGFloat(35)
        statusButtonHeight.constant = iconSize
        if kasamType == "Challenge" {
            if tempBlock?.percentComplete == nil {
                percentComplete.setTitle("0%", for: .normal)
            } else {
                let percent = Int(tempBlock!.percentComplete! * 100)
                percentComplete.setTitle("\(percent)%", for: .normal)
            }
        }
        if tempBlock?.displayStatus == "Checkmark" && kasamType == "Basic" {
            statusIcon?.setIcon(icon: .fontAwesomeRegular(.circle), iconSize: iconSize, color: UIColor.colorFour, forState: .normal)
        } else if tempBlock?.displayStatus == "Checkmark" && kasamType == "Challenge" {
            percentComplete.backgroundColor = UIColor.colorFour
            statusIcon?.setIcon(icon: .fontAwesomeRegular(.playCircle), iconSize: iconSize, color: UIColor.colorFour, forState: .normal)
        } else if tempBlock?.displayStatus == "Check" {
            shadow.layer.shadowColor = UIColor.dayYesColor.cgColor
            shadow.layer.shadowOpacity = 0.6
            percentComplete.backgroundColor = .dayYesColor
            statusIcon.setIcon(icon: .fontAwesomeSolid(.checkCircle), iconSize: iconSize, color: .dayYesColor, backgroundColor: .white, forState: .normal)
            statusIcon.layer.cornerRadius = statusIcon.frame.height
        } else if tempBlock?.displayStatus == "Uncheck" {
            shadow.backgroundColor = .dayNoColor
            statusIcon?.setIcon(icon: .fontAwesomeRegular(.circle), iconSize: iconSize, color: .dayYesColor, forState: .normal)
        } else if tempBlock?.displayStatus == "Progress" {
            shadow.backgroundColor = .dayYesColor
            percentComplete.backgroundColor = UIColor.colorFour
            statusIcon?.setIcon(icon: .fontAwesomeRegular(.playCircle), iconSize: iconSize, color: UIColor.colorFour, forState: .normal)
        }
    }
}
