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
    func updateKasamButtonPressed(_ sender: UIButton, kasamOrder: Int)
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
    @IBOutlet weak var checkButton: UIButton!
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
        print("hello \(block.kasamName)")
        tempBlock = block                               //tempBlock used to transfer info to the below func for displayStatus
        statusUpdate()
        kasamName.setTitle(block.kasamName, for: .normal)
        today = Int(block.dayOrder)
        if block.dayOrder > block.repeatDuration {
            dayNumber.text = "Complete!"
        } else {
            dayNumber.text = "Day \(block.dayOrder) of \(block.repeatDuration)"
        }
        kasamType = tempBlock?.kasamType ?? "Basic"
        kasamImage.sd_setImage(with: block.image)
        if kasamType == "Basic" && block.dayOrder < block.repeatDuration{
            percentComplete.isHidden = true
        }
        completionBadge.animation = Animation.named("crownMedal")
        completionBadge.loopMode = .loop
        completionBadge.play()
    }
    
    func cellFormatting(){          //called in the Today Controller on "WillDisplay"
        //Cell formatting
        statsContent.layer.cornerRadius = 16.0
        
        statsShadow.layer.cornerRadius = 16.0
        statsShadow.layer.shadowOffset = CGSize.zero
        statsShadow.layer.shadowRadius = 4
        
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
        
        let gradient = CAGradientLayer()
        gradient.frame = dayTrackerCollectionView.superview?.bounds ?? CGRect.zero
        gradient.colors = [UIColor.white.withAlphaComponent(0).cgColor, UIColor.white.cgColor, UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor]
        gradient.locations = [0.0, 0.05, 0.95, 1.0]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        dayTrackerCollectionView.superview?.layer.mask = gradient
        
        let centerCollectionView = NSNotification.Name("CenterCollectionView")
        NotificationCenter.default.addObserver(self, selector: #selector(TodayBlockCell.centerCollectionView), name: centerCollectionView, object: nil)
    }
    
    @IBAction func yesButtonPressed(_ sender: UIButton) {
        if tempBlock!.dayOrder > tempBlock!.repeatDuration {
            cellDelegate?.goToKasamHolder(sender, kasamOrder: row)
        } else {
            if kasamType == "Basic" {
                cellDelegate?.updateKasamButtonPressed(sender, kasamOrder: row)
            } else {
                cellDelegate?.openKasamBlock(sender, kasamOrder: row, day: nil)
            }
        }
        statusUpdate()
        centerCollectionView()
    }
    
    @IBAction func finishButtonPressed(_ sender: UIButton) {
        cellDelegate?.completeAndUnfollow(sender, kasamOrder: row)
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
    
    func nearestElement(value : Int, array : [String]) -> Int {
        var n = 0
        while Int(array[n]) ?? 1 < value {n+=1}
        return Int(array[n]) ?? 1
    }
    
    func statusUpdate(){
        let iconSize = CGFloat(35)
        
        //Sets badge status in Firebase based on if threshold is reached
        if SavedData.kasamDict[tempBlock!.kasamID]?.badgeThresholds != nil {
            let thresholdToHit = nearestElement(value: SavedData.kasamDict[tempBlock!.kasamID]!.badgeStreak!, array: SavedData.kasamDict[tempBlock!.kasamID]!.badgeThresholds!)
            if SavedData.kasamDict[tempBlock!.kasamID]?.badgeStreak == thresholdToHit {
                DBRef.userKasamFollowing.child(tempBlock!.kasamID).child("Badges").child(getCurrentDate()!).setValue(thresholdToHit)
            }
        }
        if tempBlock!.dayOrder >= tempBlock!.repeatDuration {                                   //Completed Kasams
            streakShadow.backgroundColor = UIColor.orange.darker
            if tempBlock?.totalDaysCompleted != nil {
                currentDayStreak.text = String(describing: tempBlock!.totalDaysCompleted!)      //Streak Info
                streakPostText.text = "days completed"
            }
            yesButton.setIcon(icon: .fontAwesomeRegular(.arrowAltCircleRight), iconSize: iconSize, color: UIColor.darkGray, forState: .normal)
            percentComplete.numberOfLines = 1
            percentComplete.text = "Extend"
            statsShadow.layer.shadowColor = UIColor.orange.darker.cgColor
            statsShadow.layer.shadowOpacity = 0.8
            completionBadge.play()
            checkHolder.isHidden = false
            checkButton.setIcon(icon: .fontAwesomeBrands(.telegram), iconSize: iconSize, color: UIColor.orange.darker, forState: .normal)
            completionBadge.isHidden = false
        } else {
            if tempBlock?.currentStreak != nil {
                currentDayStreak.text = String(describing: tempBlock!.currentStreak!)           //Streak Info
            }
            checkHolder.isHidden = true
            completionBadge.isHidden = true
            statsShadow.layer.shadowColor = UIColor.black.cgColor
            statsShadow.layer.shadowOpacity = 0.2
            //Update percentage complete for Challenge Kasams
            if kasamType == "Challenge" {
                if tempBlock?.percentComplete == nil {
                    percentComplete.text = "0%"
                } else {
                    let percent = Int(tempBlock!.percentComplete! * 100)
                    percentComplete.text = "\(percent)%"
                }
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
}
