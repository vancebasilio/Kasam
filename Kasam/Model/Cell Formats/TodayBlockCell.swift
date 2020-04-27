//
//  BlocksCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-05-05.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import SDWebImage
import SwiftIcons
import Lottie

protocol TableCellDelegate : class {
    func updateKasamDayButtonPressed(_ sender: UIButton, kasamOrder: Int, day: Int)
    func openKasamBlock(_ sender: UIButton, kasamOrder: Int, day: Int?)
    func goToKasamHolder(_ sender: UIButton, kasamOrder: Int)
    func completeAndUnfollow(_ sender: UIButton, kasamOrder: Int)
}

class TodayBlockCell: UITableViewCell {
    @IBOutlet weak var kasamName: UIButton!
    @IBOutlet weak var dayNumber: UILabel!
    @IBOutlet weak var currentDayStreak: UILabel!
    @IBOutlet weak var streakPostText: UILabel!
    @IBOutlet weak var blockContents: UIView!
    @IBOutlet weak var kasamImage: UIImageView!
    @IBOutlet weak var statsContent: UIView!
    @IBOutlet weak var statsShadow: UIView!
    @IBOutlet weak var streakShadow: UIView!
    @IBOutlet weak var completionBadge: AnimationView!
    @IBOutlet weak var blockPlaceholderView: UIStackView!
    @IBOutlet weak var blockPlaceholderBG: UIView!
    @IBOutlet weak var blockPlaceholderAdd: UIImageView!
    @IBOutlet weak var yesButton: UIButton!
    @IBOutlet weak var checkHolder: UIView!
    @IBOutlet weak var percentComplete: UILabel!
    @IBOutlet weak var dayTrackerCollectionView: UICollectionView!
    @IBOutlet weak var hideDayTrackerButton: UIButton!
    @IBOutlet weak var hideDayTrackerView: UIView!
    @IBOutlet weak var collectionTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionBottomConstraint: NSLayoutConstraint!
    
    var cellDelegate: TableCellDelegate?
    var row = 0
    var kasamType = "Basic"
    var tempBlock: TodayBlockFormat?
    var today: Int?
    let progress = Progress(totalUnitCount: 30)
    var hideDayTrackerDates = true
    let iconSize = CGFloat(35)
    var kasamID = ""
    var setupCheck = 0
    
    func setCollectionViewDataSourceDelegate(dataSourceDelegate: UICollectionViewDataSource & UICollectionViewDelegate, forRow row: Int) {
        dayTrackerCollectionView.delegate = dataSourceDelegate
        dayTrackerCollectionView.dataSource = dataSourceDelegate
        dayTrackerCollectionView.tag = row
        dayTrackerCollectionView.reloadData()
    }
    
    func setPlaceholder() {
        blockPlaceholderView.isHidden = false
        blockContents.isHidden = true
        statsShadow.backgroundColor = UIColor(patternImage: PlaceHolders.kasamHeaderPlaceholderImage!)
        blockPlaceholderView.isHidden = false
        blockPlaceholderAdd.setIcon(icon: .fontAwesomeSolid(.plus), textColor: .white, backgroundColor: .lightGray, size: CGSize(width: 25, height: 25))
        blockPlaceholderBG.layer.cornerRadius = blockPlaceholderBG.frame.width / 2
        blockPlaceholderBG.clipsToBounds = true
    }
    
    func removePlaceholder(){
        blockContents.isHidden = false
        blockPlaceholderView.isHidden = true
    }
    
    func setBlock(block: TodayBlockFormat) {
        if setupCheck == 0 {
            print("hello set block \(block.kasamName)")
            cellFormatting()
            kasamID = block.kasamID
            tempBlock = block                               //tempBlock used to transfer info to the below func for displayStatus
            kasamName.setTitle(block.kasamName, for: .normal)
            today = Int(block.dayOrder)
            if block.dayOrder > block.repeatDuration {
                dayNumber.text = "Complete!"
            } else {
                dayNumber.text = "Day \(block.dayOrder) of \(block.repeatDuration)"
            }
            kasamType = block.kasamType
            kasamImage.sd_setImage(with: block.image)
            if kasamType == "Basic" && block.dayOrder < block.repeatDuration{
                percentComplete.isHidden = true
            }
            setupCheck = 1
        }
    }
    
    func cellFormatting(){          //called in the Today Controller on "WillDisplay"
        print("hello cell formatting")
        //Cell formatting
        statsContent.layer.cornerRadius = 16.0
        
        statsShadow.layer.cornerRadius = 16.0
        statsShadow.layer.shadowOffset = CGSize.zero
        statsShadow.layer.shadowRadius = 4
        statsShadow.layer.shadowOpacity = 0.2
        statsShadow.layer.shadowColor = UIColor.black.cgColor
        
        kasamImage.layer.cornerRadius = 16.0
        kasamImage.layer.shadowColor = UIColor.black.cgColor
        kasamImage.layer.shadowOpacity = 0.2
        kasamImage.layer.shadowOffset = CGSize.zero
        kasamImage.layer.shadowRadius = 4
        
        streakShadow.layer.cornerRadius = 16.0
        streakShadow.layer.shadowColor = UIColor.black.cgColor
        streakShadow.layer.shadowOpacity = 0.2
        streakShadow.layer.shadowOffset = CGSize.zero
        streakShadow.layer.shadowRadius = 4
        
        hideDayTrackerButton.setIcon(icon: .fontAwesomeRegular(.calendar), iconSize: 15, color: UIColor.colorFour, forState: .normal)
        
        let centerCollectionView = NSNotification.Name("CenterCollectionView")
        NotificationCenter.default.addObserver(self, selector: #selector(TodayBlockCell.centerCollectionView), name: centerCollectionView, object: nil)
    }
    
    func collectionCoverUpdate(){
        let gradient = CAGradientLayer()
        gradient.frame = dayTrackerCollectionView.superview?.bounds ?? CGRect.zero
        gradient.colors = [UIColor.white.withAlphaComponent(0).cgColor, UIColor.white.cgColor, UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor]
        gradient.locations = [0.0, 0.05, 0.95, 1.0]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        dayTrackerCollectionView.superview?.layer.mask = gradient
    }
    
    func updateDayTrackerCollection(){
        dayTrackerCollectionView.reloadData()
        centerCollectionView()
    }
    
    @IBAction func yesButtonPressed(_ sender: UIButton) {
        if tempBlock!.dayOrder > tempBlock!.repeatDuration {
            //Extend Button after kasam is completed
            cellDelegate?.goToKasamHolder(sender, kasamOrder: row)
        } else {
            if kasamType == "Basic" {
                cellDelegate?.updateKasamDayButtonPressed(sender, kasamOrder: row, day: tempBlock?.dayOrder ?? 1)
            } else {
                cellDelegate?.openKasamBlock(sender, kasamOrder: row, day: nil)
            }
        }
        centerCollectionView()
    }
    
    @IBAction func hideDayTrackerDateButtonPressed(_ sender: Any) {
        if hideDayTrackerDates == true {
            hideDayTrackerView.isHidden = true
            collectionTopConstraint.constant = 0
            collectionBottomConstraint.constant = 0
            hideDayTrackerDates = false
        } else {
            hideDayTrackerView.isHidden = false
            collectionTopConstraint.constant = 5
            collectionBottomConstraint.constant = -5
            hideDayTrackerDates = true
        }
    }
    
    @IBAction func kasamNamePressed(_ sender: UIButton) {
        cellDelegate?.goToKasamHolder(sender, kasamOrder: row)
    }
    
    @objc func centerCollectionView() {
        if today != nil {
            if tempBlock!.dayOrder < tempBlock!.repeatDuration {
                let indexPath = IndexPath(item: self.today! - 1, section: 0)
                self.dayTrackerCollectionView.collectionViewLayout.prepare()        //ensures the contentsize is accurate before centering cells
                self.dayTrackerCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            } else {
                //if the currentDay is more than the repeatDuration
                let indexPath = IndexPath(item: tempBlock!.repeatDuration - 1, section: 0)
                self.dayTrackerCollectionView.collectionViewLayout.prepare()        //ensures the contentsize is accurate before centering cells
                self.dayTrackerCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            }
        }
    }
    
    func statusUpdate(){
        print("hello status update \(String(describing: tempBlock?.kasamName))")
        //STEP 1 - SET THE BLOCK STATUS
        if tempBlock!.dayOrder >= tempBlock!.repeatDuration {
            //OPTION 1 - COMPLETE KASAMS
            streakShadow.backgroundColor = UIColor.orange.darker
            if SavedData.kasamDict[kasamID]?.streakInfo.daysWithAnyProgress != nil {
                currentDayStreak.text = "\(SavedData.kasamDict[kasamID]!.streakInfo.daysWithAnyProgress)"  //Streak for completed kasams
                streakPostText.text = "days completed"
            }
            statsShadow.layer.shadowColor = UIColor.orange.darker.cgColor
            statsShadow.layer.shadowOpacity = 0.8
            
            if tempBlock!.dayOrder > tempBlock!.repeatDuration {
                //Completed kasam
                yesButton.setIcon(icon: .fontAwesomeRegular(.arrowAltCircleRight), iconSize: iconSize, color: UIColor.darkGray, forState: .normal)
            } else {
                checkMarkAndPercentageUpdate()
            }
        } else {
            //OPTION 2 - ACTIVE KASAMS
            currentDayStreak.text = String(describing: SavedData.kasamDict[kasamID]!.streakInfo.currentStreak)
            statsShadow.layer.shadowColor = UIColor.black.cgColor
            statsShadow.layer.shadowOpacity = 0.2
            
            //Update Percentage complete and Checkmark
            checkMarkAndPercentageUpdate()
        }
        //STEP 2 - SET THE BADGE
        DispatchQueue.global(qos: .background).sync {
            if SavedData.kasamDict[kasamID]?.badgeThresholds == nil {
                DBRef.coachKasams.child(kasamID).child("Badges").observeSingleEvent(of: .value) {(snap) in
                    if snap.exists() {SavedData.kasamDict[self.kasamID]?.badgeThresholds = (snap.value as? String)?.components(separatedBy: ";")}
                    else {SavedData.kasamDict[self.kasamID]?.badgeThresholds = ["10","30","90"]}
                    self.blockBadge()
                }
            } else {
                blockBadge()
            }
        }
    }
    
    func blockBadge(){
        if SavedData.kasamDict[kasamID]?.badgeThresholds != nil {
            let thresholdToHit = self.nearestElement(value: SavedData.kasamDict[kasamID]!.streakInfo.longestStreak, array: SavedData.kasamDict[kasamID]!.badgeThresholds!)
            let longestStreakDate = dateFormat(date: Calendar.current.date(byAdding: .day, value: SavedData.kasamDict[kasamID]!.streakInfo.longestStreakDay, to: SavedData.kasamDict[kasamID]!.joinedDate) ?? Date())
            if SavedData.kasamDict[kasamID]?.streakInfo.longestStreak == thresholdToHit.value {
                //Will only set the badge if the threshold is reached
                DBRef.userKasamFollowing.child(kasamID).child("Badges").child(longestStreakDate).setValue(thresholdToHit.value)
                //Show the completion badge animation
                completionBadge.animation = Animations.kasamBadges[thresholdToHit.level]
                completionBadge.loopMode = .loop
                completionBadge.play()
                DispatchQueue.main.async {self.completionBadge.isHidden = false}
            } else {
                DBRef.userKasamFollowing.child(kasamID).child("Badges").child(longestStreakDate).setValue(nil)
                self.completionBadge.isHidden = true
            }
            DBRef.userKasamFollowing.child(kasamID).child("Badges").observeSingleEvent(of: .value, with: {(snap) in
                SavedData.kasamDict[self.kasamID]?.badgeList = snap.value as? [String: Int]
            })
        }
    }
    
    func checkMarkAndPercentageUpdate(){
        if kasamType == "Challenge" {
            percentComplete.isHidden = false
            if tempBlock?.percentComplete == nil {percentComplete.text = "0%"}
            else {percentComplete.text = "\(Int(tempBlock!.percentComplete! * 100))%"}
        }
        if tempBlock?.displayStatus == "Checkmark" && kasamType == "Basic" {
            streakShadow.backgroundColor = UIColor.colorFour
            yesButton?.setIcon(icon: .fontAwesomeRegular(.circle), iconSize: iconSize, color: UIColor.colorFour, forState: .normal)
        } else if tempBlock?.displayStatus == "Checkmark" && kasamType == "Challenge" {
            streakShadow.backgroundColor = UIColor.colorFour
            percentComplete.textColor = UIColor.colorFive
            yesButton?.setIcon(icon: .fontAwesomeRegular(.playCircle), iconSize: iconSize, color: UIColor.colorFour, forState: .normal)
        } else if tempBlock?.displayStatus == "Check" {
            streakShadow.backgroundColor = .dayYesColor
            percentComplete.textColor = .dayYesColor
            yesButton?.setIcon(icon: .fontAwesomeSolid(.checkCircle), iconSize: iconSize, color: .dayYesColor, forState: .normal)
        } else if tempBlock?.displayStatus == "Uncheck" {
            streakShadow.backgroundColor = .dayNoColor
            yesButton?.setIcon(icon: .fontAwesomeRegular(.circle), iconSize: iconSize, color: .dayYesColor, forState: .normal)
        } else if tempBlock?.displayStatus == "Progress" {
            streakShadow.backgroundColor = .dayYesColor
            percentComplete.textColor = UIColor.colorFive
            yesButton?.setIcon(icon: .fontAwesomeRegular(.playCircle), iconSize: iconSize, color: UIColor.colorFour, forState: .normal)
        }
    }
}
