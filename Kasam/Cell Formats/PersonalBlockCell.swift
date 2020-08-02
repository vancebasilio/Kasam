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
import FirebaseAuth
import Lottie

protocol TableCellDelegate : class {
    func updateKasamDayButtonPressed(kasamOrder: Int, day: Int)
    func openKasamBlock(kasamOrder: Int, day: Int?, date: Date?, viewOnly: Bool?)
    func goToKasamHolder(kasamOrder: Int)
    func completeAndUnfollow(_ sender: UIButton, kasamOrder: Int)
}

class PersonalBlockCell: UITableViewCell {
    @IBOutlet weak var kasamName: UILabel!
    @IBOutlet weak var blockSubtitle: UILabel!
    
    @IBOutlet weak var levelLineBack: UIView!
    @IBOutlet weak var levelLineMask: UIView!
    @IBOutlet weak var levelLine: UIView!
    @IBOutlet weak var levelLineHeight: NSLayoutConstraint!
    @IBOutlet weak var levelLineProgress: NSLayoutConstraint!
    @IBOutlet weak var levelLinePercent: UILabel!
    @IBOutlet weak var overallLabel: UILabel!
    
    @IBOutlet weak var currentDayStreak: UILabel!
    @IBOutlet weak var streakPostText: UILabel!
    @IBOutlet weak var blockContents: UIView!
    @IBOutlet weak var groupStatsView: UIView!
    @IBOutlet weak var blockImage: UIView!
    @IBOutlet weak var kasamImage: UIImageView!
    @IBOutlet weak var statsContent: UIView!
    @IBOutlet weak var statsShadow: UIView!
    @IBOutlet weak var streakShadow: UIView!
    @IBOutlet weak var yesButtonView: UIView!
    @IBOutlet weak var yesButton: UIButton!
    @IBOutlet weak var trophyIconView: UIView!
    @IBOutlet weak var trophyIcon: AnimationView!
    @IBOutlet weak var progressBar: UIView!
    @IBOutlet weak var percentComplete: UILabel!
    @IBOutlet weak var dayTrackerCollectionView: UICollectionView!
    @IBOutlet weak var dayTrackerCollectionHeight: NSLayoutConstraint!
    @IBOutlet weak var hideDayTrackerButton: UIButton!
    @IBOutlet weak var hideDayTrackerView: UIView!
    @IBOutlet weak var collectionTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var restartButton: UIButton!
    
    @IBOutlet weak var groupFirstName: UILabel!
    @IBOutlet weak var groupFirstLine: UIView!
    @IBOutlet weak var groupFirstLineLength: NSLayoutConstraint!
    @IBOutlet weak var groupFirstPercent: UILabel!
    
    @IBOutlet weak var groupSecondName: UILabel!
    @IBOutlet weak var groupSecondLine: UIView!
    @IBOutlet weak var groupSecondLineLength: NSLayoutConstraint!
    @IBOutlet weak var groupThirdName: UILabel!
    @IBOutlet weak var groupThirdLine: UIView!
    @IBOutlet weak var groupThirdLineLength: NSLayoutConstraint!
    
    var cellDelegate: TableCellDelegate?
    var tempBlock: PersonalBlockFormat?
    var row = 0
    var type = ""
    var today: Int?
    var hideDayTrackerDates = true
    let iconSize = CGFloat(35)
    var kasamID = ""
    var currentDayStat = 0
    
    func setCollectionViewDataSourceDelegate(dataSourceDelegate: UICollectionViewDataSource & UICollectionViewDelegate, forRow row: Int) {
        dayTrackerCollectionView.delegate = dataSourceDelegate
        dayTrackerCollectionView.dataSource = dataSourceDelegate
        dayTrackerCollectionView.tag = row
    }
    
    func setBlock(block: PersonalBlockFormat) {
        print("hell1 \(block.blockTitle)")
        kasamID = block.kasamID
        tempBlock = block
        kasamName.text = SavedData.kasamDict[kasamID]?.kasamName
        kasamName.numberOfLines = kasamName.calculateMaxLines()
        
        //For PROGRAM kasams only
        if block.dayCount != nil {today = block.dayCount!}
        else {today = Int(block.dayOrder)}
        
        //Show the block subtite if it's a PROGRAM kasam
        if SavedData.kasamDict[kasamID]?.programDuration != nil {
            blockSubtitle.text = "\(block.blockTitle)"
        //Hide the block subtitle
        } else {blockSubtitle.frame.size.height = 0}
        
        kasamImage.sd_setImage(with: block.image)
        
        if type == "group" {
            setGroup()
        } else {
            levelLineBack.layer.cornerRadius = 4
            levelLineMask.layer.cornerRadius = 4
            levelLine.mask = levelLineBack
            dayTrackerCollectionHeight.constant = 5
        }
    }
    
    func setGroup(){
        restartButton.isHidden = true
        progressBar.isHidden = true
        groupStatsView.layer.cornerRadius = 15.0
        groupFirstLine.layer.cornerRadius = 4.0
        groupSecondLine.layer.cornerRadius = 4.0
        groupThirdLine.layer.cornerRadius = 4.0
        
        let maxLength = groupStatsView.frame.width - 30 - 20
        let mySuccess: CGFloat = CGFloat(SavedData.kasamDict[kasamID]?.streakInfo.daysWithAnyProgress ?? 0) / CGFloat(SavedData.kasamDict[kasamID]!.repeatDuration)
        groupFirstLineLength.constant = mySuccess * maxLength
        groupFirstPercent.text = "\(Int(mySuccess * 100))%"
        groupFirstName.text = String((Auth.auth().currentUser?.displayName)!).initials()
    }
    
    override func awakeFromNib() {
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
        NotificationCenter.default.addObserver(self, selector: #selector(PersonalBlockCell.centerCollectionView), name: centerCollectionView, object: nil)
    
        blockImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showBenefit)))
        kasamName.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(kasamNamePressed)))
        progressBar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideDayTracker)))
    }
    
    @objc func kasamNamePressed(){
        cellDelegate?.goToKasamHolder(kasamOrder: row)
    }
    
    @objc func extendButtonPressed(_ complete: Bool){
        var type = "complete"
        if complete == true {type = "completeTrophy"}
        showOptionsPopup(kasamID: kasamID, title: "Kasam Completed!", subtitle: SavedData.kasamDict[kasamID]!.kasamName, text: "Congrats on completing the kasam. \nGo another \(SavedData.kasamDict[kasamID]!.repeatDuration) days by pressing 'Restart' or close off the kasam by pressing 'Finish'", type: type, button: "Restart")
    }
    
    @objc func showBenefit(){
        if currentDayStat >= SavedData.kasamDict[(kasamID)]!.repeatDuration {
            extendButtonPressed(currentDayStat >= SavedData.kasamDict[(kasamID)]!.repeatDuration)
        } else if SavedData.kasamDict[kasamID]?.benefitsThresholds != nil {
            let benefit = currentDayStat.nearestElement(array: (SavedData.kasamDict[kasamID]?.benefitsThresholds)!)
            showOptionsPopup(kasamID: kasamID, title: "Day \(benefit!.0)", subtitle: nil, text: benefit?.1, type: "benefit", button: "Awesome!")
        } else {
            showOptionsPopup(kasamID: kasamID, title: "Day \(currentDayStat)", subtitle: nil, text: nil, type: "benefit", button: "Done")
        }
    }
    
    func collectionCoverUpdate(){
        print("step 6A2 collectionCoverUpdate hell2")
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
    }
    
    @IBAction func yesButtonPressed(_ sender: UIButton) {
        //Completed Kasam
        if tempBlock!.dayOrder >= SavedData.kasamDict[(tempBlock!.kasamID)]!.repeatDuration {
            extendButtonPressed(currentDayStat >= SavedData.kasamDict[(kasamID)]!.repeatDuration)
        //Regular completion
        } else if tempBlock?.dayOrder ?? 0 > 0 {
            var database = SavedData.personalKasamBlocks
            if type == "group" {database = SavedData.groupKasamBlocks}
            if let kasamOrder = database.index(where: {($0.kasamID == kasamID)}) {
                if SavedData.kasamDict[tempBlock!.kasamID]!.metricType == "Checkmark" {
                    cellDelegate?.updateKasamDayButtonPressed(kasamOrder: kasamOrder, day: tempBlock?.dayOrder ?? 1)
                } else {
                    cellDelegate?.openKasamBlock(kasamOrder: kasamOrder, day: nil, date: nil, viewOnly: false)
                }
            }
        }
        centerCollectionView()
    }
    
    @IBAction func hideDayTrackerDateButtonPressed(_ sender: Any) {
        hideDayTracker()
    }
    
    @objc func hideDayTracker(){
        //Show more info on day tracker
        if hideDayTrackerDates == true {
            if type != "group" {
                dayTrackerCollectionHeight.constant = 50
                if kasamName.numberOfLines == 2 {blockSubtitle.frame.size.height = 0}
                overallLabel.isHidden = true
            }
            hideDayTrackerView.isHidden = true
            collectionTopConstraint.constant = 0
            collectionBottomConstraint.constant = 0
            hideDayTrackerDates = false
        //Hide more info on day tracker
        } else {
            if type != "group" {
                dayTrackerCollectionHeight.constant = 5
                if kasamName.numberOfLines == 2 {blockSubtitle.frame.size.height = 20}
                overallLabel.isHidden = false
            }
            hideDayTrackerView.isHidden = false
            collectionTopConstraint.constant = 5
            collectionBottomConstraint.constant = -5
            hideDayTrackerDates = true
        }
    }
    
    @IBAction func restartButtonPressed(_ sender: Any) {
        var saveTimeObserver: NSObjectProtocol?
        addKasamPopup(kasamID: kasamID, new: true, duration: SavedData.kasamDict[kasamID]!.repeatDuration, fullView: true)
        saveTimeObserver = NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "SaveTime\(kasamID)"), object: nil, queue: OperationQueue.main) {(notification) in
            let timeVC = notification.object as! AddKasamController
            DBRef.userPersonalFollowing.child(self.kasamID).updateChildValues(["Date Joined": timeVC.formattedDate, "Repeat": timeVC.repeatDuration, "Time": timeVC.formattedTime]) {(error, reference) in
                NotificationCenter.default.post(name: Notification.Name(rawValue: "ResetPersonalKasam"), object: self, userInfo: ["kasamID": self.kasamID])
                NotificationCenter.default.removeObserver(saveTimeObserver as Any)
            }
        }
    }
    
    @objc func centerCollectionView() {
        if today != nil && tempBlock != nil && SavedData.kasamDict[(tempBlock!.kasamID)]?.repeatDuration != nil {
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
        if tempBlock != nil && SavedData.kasamDict[kasamID] != nil {
            let block = SavedData.kasamDict[kasamID]
            print("Step 5 - Block status update \(String(describing: block?.kasamName))")
            if block?.groupStatus == "initiated" {
                currentDayStreak.text = String(describing:block!.groupTeam?.count ?? 0)
                if block!.groupTeam?.count == 1 {streakPostText.text = "member joined"} else {streakPostText.text = "members joined"}
                yesButton?.setIcon(icon: .fontAwesomeSolid(.playCircle), iconSize: iconSize, color: .darkGray, forState: .normal)
                percentComplete.isHidden = false; percentComplete.text = "Start"
            } else {
            //STEP 1 - DAY COUNTER
                currentDayStat = block!.streakInfo.daysWithAnyProgress
                currentDayStreak.text = String(describing: currentDayStat)
                statsShadow.layer.shadowColor = UIColor.black.cgColor
                statsShadow.layer.shadowOpacity = 0.2
                
            //STEP 2 - Update Percentage complete and Checkmark
                if tempBlock?.dayOrder ?? 0 >= block!.repeatDuration {
                    //STEP 2 - COMPLETED KASAMS
                    yesButton?.setIcon(icon: .fontAwesomeSolid(.flagCheckered), iconSize: iconSize, color: UIColor.colorFour, forState: .normal)
                    blockSubtitle.frame.size.height = 20
                    blockSubtitle.text = "Complete!"
                    if currentDayStat == block!.repeatDuration {
                        streakShadow.backgroundColor = .dayYesColor
                        trophyIconView.isHidden = false; trophyIcon.animation = Animations.kasamBadges[1]; trophyIcon.backgroundBehavior = .pauseAndRestore
                        trophyIcon.play()
                    } else {
                        streakShadow.backgroundColor = .colorFour
                        trophyIconView.isHidden = true
                    }
                    statsShadow.layer.shadowColor = UIColor.dayYesColor.darker.darker.cgColor
                    statsShadow.layer.shadowOpacity = 1
                    statsContent.backgroundColor = UIColor.init(hex: 0xf0f6e6)
                    hideDayTrackerView.backgroundColor = UIColor.init(hex: 0xf0f6e6)
                } else {
                    //ONGOING KASAM
                    checkmarkAndPercentageUpdate()
                    trophyIconView.isHidden = true
                    blockSubtitle.frame.size.height = 20
                    if block!.repeatDuration - tempBlock!.dayOrder == 1 {
                        blockSubtitle.text = "One day left!"
                        statsShadow.layer.shadowColor = UIColor.dayYesColor.cgColor
                        statsShadow.layer.shadowOpacity = 1
                    }
                    statsContent.backgroundColor = UIColor.white
                    hideDayTrackerView.backgroundColor = UIColor.white
                    if block?.programDuration == nil {blockSubtitle.frame.size.height = 0; blockSubtitle.text = ""}
                }
                
                if block!.streakInfo.daysWithAnyProgress == 1 {streakPostText.text = "day completed"} else {streakPostText.text = "days completed"}
                
            //STEP 3 - Set level line progress
                let ratio = Double(currentDayStat) / Double(block!.repeatDuration)
                if ratio <= 1 {self.levelLineProgress.constant = self.levelLineBack.frame.width * CGFloat(ratio)}
                else {self.levelLineProgress.constant = self.levelLineBack.frame.size.width * CGFloat(1)}
                levelLinePercent.text = "\(Int(ratio * 100))%"
                
            //STEP 4 - Set the Firebase badge
                if currentDayStat >= block!.repeatDuration {
                    //Will only set the badge if the threshold is reached
                    DBRef.userTrophies.child(kasamID).child(block!.joinedDate.dateToString()).child(String(describing:block!.repeatDuration)).setValue(block!.streakInfo.currentStreak.date?.dateToString() ?? Date().dateToString())
                } else {
                    DBRef.userTrophies.child(kasamID).child(block!.joinedDate.dateToString()).child(String(describing:block!.repeatDuration)).setValue(nil)
                }
                //Update the badges the user has achieved after update to the today block
                DBRef.userTrophies.child(kasamID).observeSingleEvent(of: .value, with: {(snap) in
                    block?.badgeList = snap.value as? [String:[String: String]]
                })
            }
        }
        if dayTrackerCollectionView.alpha == 0 {dayTrackerCollectionView.fadeIn()}
        if blockImage.alpha == 0 {blockImage.fadeIn()}
        if progressBar.alpha == 0 {progressBar.fadeIn()}
    }
    
    func checkmarkAndPercentageUpdate(){
        print("STEP 5C - CheckmarkAndPercentage")
        if SavedData.kasamDict[tempBlock!.kasamID]?.metricType != "Checkmark" {
            percentComplete.isHidden = false
            percentComplete.text = "\(Int((SavedData.kasamDict[kasamID]?.percentComplete ?? 0)! * 100))%"
        } else {
            percentComplete.isHidden = true
        }
        if SavedData.kasamDict[kasamID]?.displayStatus == "Checkmark" && SavedData.kasamDict[kasamID]!.metricType == "Checkmark" {
            streakShadow.backgroundColor = .colorFour
            yesButton?.setIcon(icon: .fontAwesomeRegular(.circle), iconSize: iconSize, color: .colorFour, forState: .normal)
        } else if SavedData.kasamDict[kasamID]?.displayStatus == "Checkmark" && SavedData.kasamDict[kasamID]!.metricType != "Checkmark" {
            streakShadow.backgroundColor = .colorFour
            percentComplete.textColor = .colorFive
            yesButton?.setIcon(icon: .fontAwesomeRegular(.playCircle), iconSize: iconSize, color: .colorFour, forState: .normal)
        } else if SavedData.kasamDict[kasamID]?.displayStatus == "Check" {
            streakShadow.backgroundColor = .dayYesColor
            percentComplete.textColor = .dayYesColor
            yesButton?.setIcon(icon: .fontAwesomeSolid(.checkCircle), iconSize: iconSize, color: .dayYesColor, forState: .normal)
        } else if SavedData.kasamDict[kasamID]?.displayStatus == "Progress" {
            streakShadow.backgroundColor = .dayYesColor
            percentComplete.textColor = .colorFive
            yesButton?.setIcon(icon: .fontAwesomeRegular(.playCircle), iconSize: iconSize, color: .colorFour, forState: .normal)
        }
    }
}
