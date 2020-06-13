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
    func updateKasamDayButtonPressed(kasamOrder: Int, day: Int, challenge: Bool)
    func openKasamBlock(_ sender: UIButton, kasamOrder: Int, day: Int?, viewOnly: Bool?)
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
    @IBOutlet weak var badge1: AnimationView!
    @IBOutlet weak var badge2: AnimationView!
    @IBOutlet weak var badge3: AnimationView!
    @IBOutlet weak var yesButton: UIButton!
    @IBOutlet weak var checkHolder: UIView!
    @IBOutlet weak var percentComplete: UILabel!
    @IBOutlet weak var dayTrackerCollectionView: UICollectionView!
    @IBOutlet weak var hideDayTrackerButton: UIButton!
    @IBOutlet weak var hideDayTrackerView: UIView!
    @IBOutlet weak var collectionTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var restartButton: UIButton!
    
    var cellDelegate: TableCellDelegate?
    var row = 0
    var tempBlock: TodayBlockFormat?
    var today: Int?
    let progress = Progress(totalUnitCount: 30)
    var hideDayTrackerDates = true
    let iconSize = CGFloat(35)
    var kasamID = ""
    
    func setCollectionViewDataSourceDelegate(dataSourceDelegate: UICollectionViewDataSource & UICollectionViewDelegate, forRow row: Int) {
        dayTrackerCollectionView.delegate = dataSourceDelegate
        dayTrackerCollectionView.dataSource = dataSourceDelegate
        dayTrackerCollectionView.tag = row
    }
    
    func setBlock(block: TodayBlockFormat) {
        kasamID = block.kasamID
        tempBlock = block
        kasamName.setTitle(SavedData.kasamDict[kasamID]?.kasamName, for: .normal)
        print("hell2 \(SavedData.kasamDict[kasamID]?.kasamName)")
        if block.dayCount != nil {today = block.dayCount!}
        else {today = Int(block.dayOrder)}
        if block.dayOrder > SavedData.kasamDict[kasamID]?.repeatDuration ?? 0 {dayNumber.text = "Complete!"}
        else if SavedData.kasamDict[kasamID]?.timelineDuration != nil {
            dayNumber.text = "\(block.blockTitle)"
            dayNumber.font = dayNumber.font.withSize(16)
        } else {dayNumber.text = "Day \(block.dayOrder) of \(SavedData.kasamDict[kasamID]!.repeatDuration)"}
        kasamImage.sd_setImage(with: block.image)
        if SavedData.kasamDict[kasamID]!.metricType == "Checkmark" && block.dayOrder < SavedData.kasamDict[kasamID]?.repeatDuration ?? 0{
            percentComplete.isHidden = true
        }
        DBRef.coachKasams.child(kasamID).child("Sequence").observeSingleEvent(of: .value) {(snap) in
            if snap.exists() {SavedData.kasamDict[self.kasamID]?.sequence = (snap.value as? String)!}
        }
    }
    
    func cellFormatting(){          //called in the Today Controller on "WillDisplay"
        print("hell2 cell formatting")
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
        
        hideDayTrackerButton.setIcon(icon: .fontAwesomeRegular(.calendar), iconSize: 15, color: UIColor.darkGray, forState: .normal)
        restartButton.setIcon(icon: .fontAwesomeSolid(.sync), iconSize: 15, color: UIColor.colorFour, forState: .normal)
        
        let centerCollectionView = NSNotification.Name("CenterCollectionView")
        NotificationCenter.default.addObserver(self, selector: #selector(TodayBlockCell.centerCollectionView), name: centerCollectionView, object: nil)
    }
    
    func collectionCoverUpdate(){
        print("hell2 collectionCoverUpdate")
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
        if tempBlock!.dayOrder > SavedData.kasamDict[(tempBlock!.kasamID)]!.repeatDuration {
            //Extend Button after kasam is completed
            cellDelegate?.goToKasamHolder(sender, kasamOrder: row)
        } else {
            if SavedData.kasamDict[tempBlock!.kasamID]!.metricType == "Checkmark" {
                cellDelegate?.updateKasamDayButtonPressed(kasamOrder: row, day: tempBlock?.dayOrder ?? 1, challenge: false)
            } else {
                cellDelegate?.openKasamBlock(sender, kasamOrder: row, day: nil, viewOnly: false)
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
    
    @IBAction func restartButtonPressed(_ sender: Any) {
        var saveTimeObserver: NSObjectProtocol?
        addKasamPopup(kasamID: kasamID, new: true, timelineDuration: SavedData.kasamDict[kasamID]?.timelineDuration, badgeThresholds: SavedData.kasamDict[kasamID]!.badgeThresholds, fullView: true)
        saveTimeObserver = NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "SaveTime\(kasamID)"), object: nil, queue: OperationQueue.main) {(notification) in
            let timeVC = notification.object as! AddKasamController
            DBRef.userKasamFollowing.child(self.kasamID).updateChildValues(["Date Joined": timeVC.formattedDate, "Repeat": timeVC.repeatDuration, "Time": timeVC.formattedTime]) {(error, reference) in
                DBRef.userKasamFollowing.child(self.kasamID).child("Past Join Dates").child(self.dateFormat(date: SavedData.kasamDict[self.kasamID]!.joinedDate)).setValue(SavedData.kasamDict[self.kasamID]?.repeatDuration)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "ResetTodayKasam"), object: self, userInfo: ["kasamID": self.kasamID])
                NotificationCenter.default.post(name: Notification.Name(rawValue: "ProfileUpdate"), object: self)
                NotificationCenter.default.removeObserver(saveTimeObserver as Any)
            }
        }
    }
    
    @IBAction func kasamNamePressed(_ sender: UIButton) {
        cellDelegate?.goToKasamHolder(sender, kasamOrder: row)
    }
    
    @objc func centerCollectionView() {
        if today != nil && tempBlock != nil {
            if tempBlock!.dayOrder < SavedData.kasamDict[(tempBlock!.kasamID)]!.repeatDuration {
                let indexPath = IndexPath(item: self.today! - 1, section: 0)
                self.dayTrackerCollectionView.collectionViewLayout.prepare()        //ensures the contentsize is accurate before centering cells
                self.dayTrackerCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            } else {
                //if the currentDay is more than the repeatDuration
                let indexPath = IndexPath(item: SavedData.kasamDict[(tempBlock!.kasamID)]!.repeatDuration - 1, section: 0)
                self.dayTrackerCollectionView.collectionViewLayout.prepare()        //ensures the contentsize is accurate before centering cells
                self.dayTrackerCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            }
        }
    }
    
    func statusUpdate(_ day: String?){
        //STEP 1 - SET THE BLOCK STATUS
        if tempBlock!.dayOrder >= SavedData.kasamDict[(tempBlock!.kasamID)]!.repeatDuration {
            //OPTION 1 - COMPLETE KASAMS
            streakShadow.backgroundColor = UIColor.orange.darker
            if SavedData.kasamDict[kasamID]?.streakInfo.daysWithAnyProgress != nil {
                currentDayStreak.text = String(describing: SavedData.kasamDict[kasamID]!.streakInfo.daysWithAnyProgress)
            }
            statsShadow.layer.shadowColor = UIColor.orange.darker.cgColor
            statsShadow.layer.shadowOpacity = 0.8
            
            if tempBlock!.dayOrder > SavedData.kasamDict[tempBlock!.kasamID]!.repeatDuration {
                //Completed kasam
                yesButton.setIcon(icon: .fontAwesomeRegular(.arrowAltCircleRight), iconSize: iconSize, color: UIColor.darkGray, forState: .normal)
            } else {
                checkmarkAndPercentageUpdate()
            }
        } else {
            //OPTION 2 - ACTIVE KASAMS
            currentDayStreak.text = String(describing: SavedData.kasamDict[kasamID]!.streakInfo.daysWithAnyProgress)
            statsShadow.layer.shadowColor = UIColor.black.cgColor
            statsShadow.layer.shadowOpacity = 0.2
            
            //Update Percentage complete and Checkmark
            checkmarkAndPercentageUpdate()
        }
        if SavedData.kasamDict[kasamID]!.streakInfo.daysWithAnyProgress == 1 {
            streakPostText.text = "day completed"
        }
        //STEP 2 - SET THE BADGE
        DispatchQueue.global(qos: .background).sync {
            if SavedData.kasamDict[kasamID]?.badgeThresholds == nil {
                DBRef.coachKasams.child(kasamID).child("Badges").observeSingleEvent(of: .value) {(snap) in
                    if snap.exists() {SavedData.kasamDict[self.kasamID]?.badgeThresholds = (snap.value as! String).components(separatedBy: ";")}
                    else {SavedData.kasamDict[self.kasamID]?.badgeThresholds = ["10","30","90"]}
                    self.blockBadge(day)
                }
            } else {
                blockBadge(day)
            }
        }
    }
    
    func blockBadge(_ day:String?){
        let badgeLevelArray = [badge1, badge2, badge3]
        var progressAchieved = 0
        var statusDate = ""
        var badgeLevel = 0
        if SavedData.kasamDict[kasamID]?.sequence == "streak" {
            if SavedData.kasamDict[kasamID]?.streakInfo.longestStreak != nil {
                progressAchieved = SavedData.kasamDict[kasamID]!.streakInfo.longestStreak
                statusDate = dateFormat(date: Calendar.current.date(byAdding: .day, value: SavedData.kasamDict[kasamID]!.streakInfo.longestStreakDay, to: SavedData.kasamDict[kasamID]!.joinedDate) ?? Date())
            }
        } else {
            if SavedData.kasamDict[kasamID]?.streakInfo.daysWithAnyProgress != nil {
                progressAchieved = SavedData.kasamDict[kasamID]!.streakInfo.daysWithAnyProgress
                statusDate = day ?? Date().dateToString()
            }
        }
        for badge in SavedData.kasamDict[kasamID]!.badgeThresholds {
            if progressAchieved == Int(badge)! {
                //Will only set the badge if the threshold is reached
                DBRef.userKasamFollowing.child(kasamID).child("Badges").child(statusDate).setValue(Int(badge))
                badgeLevelArray[badgeLevel]?.animation = Animations.kasamBadges[badgeLevel]
                badgeLevelArray[badgeLevel]!.isHidden = false
            } else {
                DBRef.userKasamFollowing.child(kasamID).child("Badges").child(statusDate).setValue(nil)
                badgeLevelArray[badgeLevel]!.isHidden = true
            }
            badgeLevel += 1
        }
        //Update the badges the user has achieved after update to the today block
        DBRef.userKasamFollowing.child(kasamID).child("Badges").observeSingleEvent(of: .value, with: {(snap) in
            SavedData.kasamDict[self.kasamID]?.badgeList = snap.value as? [String: Int]
        })
    }
    
    func checkmarkAndPercentageUpdate(){
        if SavedData.kasamDict[tempBlock!.kasamID]!.metricType != "Checkmark" {
            percentComplete.isHidden = false
            if SavedData.kasamDict[kasamID]?.percentComplete == nil {percentComplete.text = "0%"}
            else {percentComplete.text = "\(Int((SavedData.kasamDict[kasamID]?.percentComplete)! * 100))%"}
        }
        if SavedData.kasamDict[kasamID]?.displayStatus == "Checkmark" && SavedData.kasamDict[kasamID]!.metricType == "Checkmark" {
            streakShadow.backgroundColor = .colorFour
            yesButton?.setIcon(icon: .fontAwesomeRegular(.circle), iconSize: iconSize, color: UIColor.colorFour, forState: .normal)
        } else if SavedData.kasamDict[kasamID]?.displayStatus == "Checkmark" && SavedData.kasamDict[kasamID]!.metricType != "Checkmark" {
            streakShadow.backgroundColor = UIColor.colorFour
            percentComplete.textColor = .colorFive
            yesButton?.setIcon(icon: .fontAwesomeRegular(.playCircle), iconSize: iconSize, color: UIColor.colorFour, forState: .normal)
        } else if SavedData.kasamDict[kasamID]?.displayStatus == "Check" {
            streakShadow.backgroundColor = .dayYesColor
            percentComplete.textColor = .dayYesColor
            yesButton?.setIcon(icon: .fontAwesomeSolid(.checkCircle), iconSize: iconSize, color: .dayYesColor, forState: .normal)
        } else if SavedData.kasamDict[kasamID]?.displayStatus == "Progress" {
            streakShadow.backgroundColor = .dayYesColor
            percentComplete.textColor = UIColor.colorFive
            yesButton?.setIcon(icon: .fontAwesomeRegular(.playCircle), iconSize: iconSize, color: UIColor.colorFour, forState: .normal)
        }
    }
}
