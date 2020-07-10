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
    func openKasamBlock(_ sender: UIButton, kasamOrder: Int, day: Int?, date: Date?, viewOnly: Bool?)
    func goToKasamHolder(kasamOrder: Int)
    func completeAndUnfollow(_ sender: UIButton, kasamOrder: Int)
}

class TodayBlockCell: UITableViewCell {
    @IBOutlet weak var kasamName: UILabel!
    @IBOutlet weak var blockSubtitle: UILabel!
    @IBOutlet weak var levelLineBack: UIView!
    @IBOutlet weak var levelLine: UIView!
    @IBOutlet weak var levelLineProgress: NSLayoutConstraint!
    @IBOutlet weak var levelLinePercent: UILabel!
    @IBOutlet weak var currentDayStreak: UILabel!
    @IBOutlet weak var streakPostText: UILabel!
    @IBOutlet weak var blockContents: UIView!
    @IBOutlet weak var blockImage: UIView!
    @IBOutlet weak var kasamImage: UIImageView!
    @IBOutlet weak var statsContent: UIView!
    @IBOutlet weak var statsShadow: UIView!
    @IBOutlet weak var streakShadow: UIView!
    @IBOutlet weak var yesButton: UIButton!
    @IBOutlet weak var extendButtonView: UIView!
    @IBOutlet weak var trophyIcon: AnimationView!
    @IBOutlet weak var progressBar: UIView!
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
    var benefits = [Int:String]()
    var statusDate = ""
    var currentDayStat = 0
    
    func setCollectionViewDataSourceDelegate(dataSourceDelegate: UICollectionViewDataSource & UICollectionViewDelegate, forRow row: Int) {
        dayTrackerCollectionView.delegate = dataSourceDelegate
        dayTrackerCollectionView.dataSource = dataSourceDelegate
        dayTrackerCollectionView.tag = row
    }
    
    func setBlock(block: TodayBlockFormat) {
        kasamID = block.kasamID
        tempBlock = block
        kasamName.text = SavedData.kasamDict[kasamID]?.kasamName
        kasamName.numberOfLines = kasamName.calculateMaxLines()
        print("step 6A \(String(describing: SavedData.kasamDict[kasamID]?.kasamName)) hell2")
        
        //For timeline kasams only
        if block.dayCount != nil {today = block.dayCount!}
        else {today = Int(block.dayOrder)}
        
        //Show the block subtite if it's a timeline kasam
        if SavedData.kasamDict[kasamID]?.timeline != nil {
            blockSubtitle.text = "\(block.blockTitle)"
            blockSubtitle.font = blockSubtitle.font.withSize(16)
        //Hide the block subtitle
        } else {blockSubtitle.frame.size.height = 0}
        
        kasamImage.sd_setImage(with: block.image)
        if SavedData.kasamDict[kasamID]!.metricType == "Checkmark" && block.dayOrder < SavedData.kasamDict[kasamID]?.repeatDuration ?? 0{
            percentComplete.isHidden = true
        }
        DBRef.coachKasams.child(kasamID).child("Sequence").observeSingleEvent(of: .value) {(snap) in
            if snap.exists() {SavedData.kasamDict[self.kasamID]?.sequence = (snap.value as? String)!}
        }
        levelLineBack.layer.cornerRadius = 4
        levelLine.layer.cornerRadius = 4
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
        NotificationCenter.default.addObserver(self, selector: #selector(TodayBlockCell.centerCollectionView), name: centerCollectionView, object: nil)
    
        blockImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showBenefit)))
        levelLine.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showBenefit)))
        kasamName.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(kasamNamePressed)))
        extendButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(extendButtonPressed)))
    }
    
    @objc func kasamNamePressed(){
        cellDelegate?.goToKasamHolder(kasamOrder: row)
    }
    
    @objc func extendButtonPressed(){
        showOptionsPopup(kasamID: kasamID, title: "Kasam Completed!", subtitle: SavedData.kasamDict[kasamID]!.kasamName, text: "Congrats on completing the kasam. \nGo another \(SavedData.kasamDict[kasamID]!.repeatDuration) days by pressing 'Extend' or close off the kasam by pressing 'Finish'", type: "extend", button: "Extend")
    }
    
    @objc func showBenefit(){
        if currentDayStat >= SavedData.kasamDict[(kasamID)]!.repeatDuration {
            extendButtonPressed()
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
        centerCollectionView()
    }
    
    @IBAction func yesButtonPressed(_ sender: UIButton) {
        if tempBlock!.dayOrder > SavedData.kasamDict[(tempBlock!.kasamID)]!.repeatDuration {
            //Extend Button after kasam is completed
            cellDelegate?.goToKasamHolder(kasamOrder: row)
        } else {
            if SavedData.kasamDict[tempBlock!.kasamID]!.metricType == "Checkmark" {
                cellDelegate?.updateKasamDayButtonPressed(kasamOrder: row, day: tempBlock?.dayOrder ?? 1, challenge: false)
            } else {
                cellDelegate?.openKasamBlock(sender, kasamOrder: row, day: nil, date: nil, viewOnly: false)
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
        addKasamPopup(kasamID: kasamID, percentComplete: nil, new: true, timelineDuration: SavedData.kasamDict[kasamID]?.timeline, duration: SavedData.kasamDict[kasamID]!.repeatDuration, fullView: true)
        saveTimeObserver = NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "SaveTime\(kasamID)"), object: nil, queue: OperationQueue.main) {(notification) in
            let timeVC = notification.object as! AddKasamController
            DBRef.userKasamFollowing.child(self.kasamID).updateChildValues(["Date Joined": timeVC.formattedDate, "Repeat": timeVC.repeatDuration, "Time": timeVC.formattedTime]) {(error, reference) in
                DBRef.userKasamFollowing.child(self.kasamID).child("Past Join Dates").child(( SavedData.kasamDict[self.kasamID]!.joinedDate).dateToString()).setValue(SavedData.kasamDict[self.kasamID]?.repeatDuration)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "ResetTodayKasam"), object: self, userInfo: ["kasamID": self.kasamID])
                NotificationCenter.default.post(name: Notification.Name(rawValue: "ProfileUpdate"), object: self)
                NotificationCenter.default.removeObserver(saveTimeObserver as Any)
            }
        }
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
        if tempBlock != nil {
           //STEP 1 - DAY COUNTER
            if SavedData.kasamDict[kasamID]?.sequence == "streak" {
                currentDayStat = SavedData.kasamDict[kasamID]!.streakInfo.currentStreak.value
            } else {
                currentDayStat = SavedData.kasamDict[kasamID]!.streakInfo.daysWithAnyProgress
                statusDate = day ?? Date().dateToString()
            }
            currentDayStreak.text = String(describing: currentDayStat)
            statsShadow.layer.shadowColor = UIColor.black.cgColor
            statsShadow.layer.shadowOpacity = 0.2
            
            //Update Percentage complete and Checkmark
            checkmarkAndPercentageUpdate()
            
            //STEP 2 - COMPLETE KASAMS
            if SavedData.kasamDict[(kasamID)]!.repeatDuration - currentDayStat == 1 {
                //ONE DAY LEFT
                blockSubtitle.frame.size.height = 20
                blockSubtitle.text = "One day left!"
                streakShadow.backgroundColor = UIColor.dayYesColor
                statsShadow.layer.shadowColor = UIColor.dayYesColor.cgColor
                statsShadow.layer.shadowOpacity = 0.4
                checkmarkAndPercentageUpdate()
                extendButtonView.isHidden = true
            } else if currentDayStat >= SavedData.kasamDict[(kasamID)]!.repeatDuration {
                //COMPLETED!
                blockSubtitle.frame.size.height = 20
                blockSubtitle.text = "Complete!"
                streakShadow.backgroundColor = UIColor.dayYesColor.darker.darker
                statsShadow.layer.shadowColor = UIColor.dayYesColor.darker.darker.cgColor
                statsShadow.layer.shadowOpacity = 1
                extendButtonView.isHidden = false
                trophyIcon.animation = Animations.kasamBadges[1]
                trophyIcon.play()
            } else {
                extendButtonView.isHidden = true
                statsContent.backgroundColor = UIColor.white
                hideDayTrackerView.backgroundColor = UIColor.white
                if SavedData.kasamDict[kasamID]?.timeline == nil {blockSubtitle.frame.size.height = 0; blockSubtitle.text = ""}
            }
            
            if SavedData.kasamDict[kasamID]!.streakInfo.daysWithAnyProgress == 1 {streakPostText.text = "day completed"}
            
            //Set level line progress
            let ratio = Double(currentDayStat) / Double(SavedData.kasamDict[kasamID]!.repeatDuration)
            self.levelLineProgress.constant = self.levelLineBack.frame.size.width * CGFloat(ratio)
            levelLinePercent.text = "\(Int(ratio * 100))%"
            
            setFirebaseBadge()
        }
        dayTrackerCollectionView.fadeIn()
        blockImage.fadeIn()
        progressBar.fadeIn()
    }
    
    func setFirebaseBadge(){
        if currentDayStat >= SavedData.kasamDict[kasamID]!.repeatDuration {
            //Will only set the badge if the threshold is reached
            DBRef.userKasamFollowing.child(kasamID).child("Badges").child(SavedData.kasamDict[kasamID]!.joinedDate.dateToString()).child(String(describing:SavedData.kasamDict[kasamID]!.repeatDuration)).setValue(SavedData.kasamDict[kasamID]!.streakInfo.currentStreak.date?.dateToString() ?? Date().dateToString())
        } else {
            DBRef.userKasamFollowing.child(kasamID).child("Badges").child(SavedData.kasamDict[kasamID]!.joinedDate.dateToString()).child(String(describing:SavedData.kasamDict[kasamID]!.repeatDuration)).setValue(nil)
        }
        //Update the badges the user has achieved after update to the today block
        DBRef.userKasamFollowing.child(kasamID).child("Badges").observeSingleEvent(of: .value, with: {(snap) in
            SavedData.kasamDict[self.kasamID]?.badgeList = snap.value as? [String:[String: String]]
            self.kasamID.badgesAchieved()
            NotificationCenter.default.post(name: Notification.Name(rawValue: "ProfileUpdate"), object: self)
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
