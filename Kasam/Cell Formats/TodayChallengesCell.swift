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
    func openKasamBlock(_ sender: UIButton, kasamOrder: Int, day: Int?, date: Date?, viewOnly: Bool?)
    func goToChallengeKasamHolder(_ sender: UIButton, kasamOrder: Int)
    func completeAndUnfollow(_ sender: UIButton, kasamOrder: Int)
}

class TodayChallengesCell: UICollectionViewCell {

    @IBOutlet weak var BGOutline: UIView!
    @IBOutlet weak var kasamImage: UIImageView!
    @IBOutlet weak var kasamImageBGColor: UIView!
    @IBOutlet weak var kasamImageBGHeight: NSLayoutConstraint!
    @IBOutlet weak var kasamTitle: UIButton!
    @IBOutlet weak var kasamDuration: UILabel!
    @IBOutlet weak var statusIcon: UIButton!
    @IBOutlet weak var statusButtonHeight: NSLayoutConstraint!
    @IBOutlet weak var percentComplete: UIButton!
    @IBOutlet weak var BG: UIView!
    @IBOutlet weak var shadow: UIView!
    
    var cellDelegate: CollectionCellDelegate?
    var row = 0
    var tempBlock: TodayBlockFormat?
    var kasamID = ""
    
    func setBlock(challenge: TodayBlockFormat) {
        print("step 6b challenge hell2  \(SavedData.kasamDict[challenge.kasamID]?.kasamName)")
        tempBlock = challenge
        kasamID = challenge.kasamID
        kasamImage.sd_setImage(with: challenge.image)
        kasamTitle.setTitle(SavedData.kasamDict[kasamID]?.kasamName, for: .normal)
        if SavedData.kasamDict[tempBlock!.kasamID]!.metricType == "Checkmark" {kasamDuration.text = "All day"}
        else {kasamDuration.text = challenge.duration}
        statusUpdate()
    }
    
    @IBAction func kasamTitleSelected(_ sender: UIButton) {
        cellDelegate?.goToChallengeKasamHolder(sender, kasamOrder: row)
    }
    
    override func awakeFromNib() {
        BG.layer.cornerRadius = 20
        BGOutline.layer.cornerRadius = 25
        BGOutline.layer.borderWidth = 3.0
        
        shadow.layer.cornerRadius = 20
        shadow.layer.shadowColor = UIColor.black.cgColor
        shadow.layer.shadowOpacity = 0.2
        shadow.layer.shadowOffset = CGSize.zero
        shadow.layer.shadowRadius = 4
        
        percentComplete.backgroundColor = UIColor.colorFour
        percentComplete.layer.cornerRadius = 8.0
        percentComplete.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
    }
    
    func statusUpdate(){
        //Update percentage complete for Challenge Kasams
        let iconSize = CGFloat(35)
        statusButtonHeight.constant = iconSize
        
        //Set percent value
        if SavedData.kasamDict[kasamID]?.percentComplete == nil {
            //No progress made
            percentComplete.setTitle("0%", for: .normal)
            kasamImageBGColor.backgroundColor = UIColor.black
        } else {
            //Progress made
            let percent = Int((SavedData.kasamDict[kasamID]?.percentComplete)! * 100)
            percentComplete.setTitle("\(percent)%", for: .normal)
            kasamImageBGHeight.constant = (CGFloat(SavedData.kasamDict[kasamID]!.percentComplete) * kasamImage.frame.height)
            if percent == 0 {
                kasamImageBGColor.backgroundColor = UIColor.black
            } else if percent == 100 {
                kasamImageBGColor.backgroundColor = UIColor.init(hex: 0x043927)
            } else {
                kasamImageBGColor.backgroundColor = UIColor.init(hex: 0x043927)
            }
        }
        
        if SavedData.kasamDict[kasamID]?.displayStatus == "Checkmark" && SavedData.kasamDict[tempBlock!.kasamID]!.metricType == "Checkmark" {
            percentComplete.backgroundColor = UIColor.colorFour
            shadow.layer.shadowColor = UIColor.black.cgColor
            shadow.layer.shadowOpacity = 0.2
            statusIcon?.setIcon(icon: .fontAwesomeRegular(.circle), iconSize: iconSize, color: UIColor.colorFour, forState: .normal)
        } else if SavedData.kasamDict[kasamID]?.displayStatus == "Checkmark" && SavedData.kasamDict[tempBlock!.kasamID]!.metricType != "Checkmark" {
            percentComplete.backgroundColor = UIColor.colorFour
            statusIcon?.setIcon(icon: .fontAwesomeRegular(.playCircle), iconSize: iconSize, color: UIColor.colorFour, forState: .normal)
        } else if SavedData.kasamDict[kasamID]?.displayStatus == "Check" {
            shadow.layer.shadowColor = UIColor.dayYesColor.cgColor
            shadow.layer.shadowOpacity = 0.6
            percentComplete.backgroundColor = .dayYesColor
            statusIcon.setIcon(icon: .fontAwesomeSolid(.checkCircle), iconSize: iconSize, color: .dayYesColor, backgroundColor: .white, forState: .normal)
            statusIcon.layer.cornerRadius = 25
        } else if SavedData.kasamDict[kasamID]?.displayStatus == "Progress" {
            shadow.layer.shadowColor = UIColor.black.cgColor
            shadow.layer.shadowOpacity = 0.2
            percentComplete.backgroundColor = UIColor.colorFour
            statusIcon?.setIcon(icon: .fontAwesomeRegular(.playCircle), iconSize: iconSize, color: UIColor.colorFour, forState: .normal)
        }
        blockBadge()
    }
    
    func blockBadge(){
        if Int(SavedData.kasamDict[kasamID]?.percentComplete ?? 0) == SavedData.kasamDict[kasamID]!.repeatDuration {
            //Will only set the badge if the threshold is reached
            DBRef.userPersonalFollowing.child(kasamID).child("Badges").child(Dates.getCurrentDate()).setValue(SavedData.kasamDict[kasamID]!.repeatDuration)
        } else {
            DBRef.userPersonalFollowing.child(kasamID).child("Badges").child(Dates.getCurrentDate()).setValue(nil)
        }
        DBRef.userPersonalFollowing.child(kasamID).child("Badges").observeSingleEvent(of: .value, with: {(snap) in
//            SavedData.kasamDict[self.kasamID]?.badgeList = snap.value as? [String: Int]
        })
    }
}
