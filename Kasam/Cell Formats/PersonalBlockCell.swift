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
    func completeAndUnfollow(kasamOrder: Int)
    func reloadKasamBlock(kasamOrder: Int)
}

class PersonalBlockCell: UITableViewCell, UITableViewDelegate, UITableViewDataSource {
    
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
    @IBOutlet weak var addButton: UIButton!
    
    @IBOutlet weak var bottomStatusView: UIView!
    @IBOutlet weak var bottomStatusButton: UIButton!
    @IBOutlet weak var bottomStatusText: UILabel!
    
    @IBOutlet weak var topStatusView: UIView!
    @IBOutlet weak var topStatusAnimation: AnimationView!
    @IBOutlet weak var topStatusButton: UIButton!
    @IBOutlet weak var topStatusText: UILabel!
    
    @IBOutlet weak var progressBar: UIView!
    @IBOutlet weak var dayTrackerCollectionView: UICollectionView!
    @IBOutlet weak var dayTrackerCollectionHeight: NSLayoutConstraint!
    @IBOutlet weak var hideDayTrackerButton: UIButton!
    @IBOutlet weak var hideDayTrackerView: UIView!
    @IBOutlet weak var collectionTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var restartButton: UIButton!
    @IBOutlet weak var groupStatsTable: UITableView!
    
    var cellDelegate: TableCellDelegate?
    var tempBlock: PersonalBlockFormat?
    var row = 0
    var type = ""
    var hideDayTrackerDates = true
    let iconSize = CGFloat(35)
    var kasamID = ""
    var currentDayStat = 0
    var groupStatsList: [(String, Double)]?
    
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
        groupStatsTable.delegate = self
        groupStatsTable.dataSource = self
        groupStatsList = SavedData.kasamDict[kasamID]?.groupTeam?.sorted{ $0.value > $1.value }
        
        //To update the kasam stats table
        DBRef.groupKasams.child((SavedData.kasamDict[kasamID]?.groupID)!).child("Info").child("Team").observe(.childChanged) {(snap) in
            SavedData.kasamDict[self.kasamID]?.groupTeam?[snap.key] = snap.value as? Double
            self.groupStatsList = SavedData.kasamDict[self.kasamID]?.groupTeam?.sorted{ $0.value > $1.value }
            self.groupStatsTable.reloadData()
        }
        
        //New user added to group kasam
        DBRef.groupKasams.child((SavedData.kasamDict[kasamID]?.groupID)!).child("Info").child("Team").observe(.childAdded) {(snap) in
            SavedData.kasamDict[self.kasamID]?.groupTeam?[snap.key] = snap.value as? Double
            self.groupStatsList = SavedData.kasamDict[self.kasamID]?.groupTeam?.sorted{ $0.value > $1.value }
            self.groupStatsTable.reloadData()
            self.statusUpdate(nil)
        }
        
        //User removed from group kasam
        DBRef.groupKasams.child((SavedData.kasamDict[kasamID]?.groupID)!).child("Info").child("Team").observe(.childRemoved) {(snap) in
            SavedData.kasamDict[self.kasamID]?.groupTeam?[snap.key] = nil
            self.groupStatsList = SavedData.kasamDict[self.kasamID]?.groupTeam?.sorted{ $0.value > $1.value }
            self.groupStatsTable.reloadData()
            self.statusUpdate(nil)
        }
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
        showOptionsPopup(kasamID: kasamID, title: "Kasam Completed!", subtitle: SavedData.kasamDict[kasamID]!.kasamName, text: "Congrats on completing the kasam. \nGo another \(SavedData.kasamDict[kasamID]!.repeatDuration) days by pressing 'Restart' or close off the kasam by pressing 'Finish'", type: type, button: "Restart") {
            //
        }
    }
    
    @objc func showBenefit(){
        if type == "group" && SavedData.kasamDict[kasamID]?.groupStatus == "initiated" {
            showGroupUserSearch(kasamID: kasamID) {
                //
            }
        } else {
            if currentDayStat >= SavedData.kasamDict[(kasamID)]!.repeatDuration {
                extendButtonPressed(currentDayStat >= SavedData.kasamDict[(kasamID)]!.repeatDuration)
            } else if SavedData.kasamDict[kasamID]?.benefitsThresholds != nil {
                let benefit = currentDayStat.nearestElement(array: (SavedData.kasamDict[kasamID]?.benefitsThresholds)!)
                showOptionsPopup(kasamID: kasamID, title: "Day \(benefit!.0)", subtitle: nil, text: benefit?.1, type: "benefit", button: "Awesome!") {}
            } else {
                showOptionsPopup(kasamID: kasamID, title: "Day \(currentDayStat)", subtitle: nil, text: nil, type: "benefit", button: "Done") {}
            }
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
    
    @IBAction func topStatusButtonPressed(_ sender: Any) {
        if SavedData.kasamDict[kasamID]?.groupTeam?[SavedData.userID] == -1 {
            DBRef.groupKasams.child(SavedData.kasamDict[self.kasamID]!.groupID!).child("Info").child("Team").child(SavedData.userID).setValue(0)
            topStatusButton.setIcon(icon: .fontAwesomeSolid(.checkCircle), iconSize: iconSize, color: .dayYesColor, forState: .normal)
        } else if SavedData.kasamDict[kasamID]?.groupTeam?[SavedData.userID] == 0 {
            DBRef.groupKasams.child(SavedData.kasamDict[self.kasamID]!.groupID!).child("Info").child("Team").child(SavedData.userID).setValue(-1)
            topStatusButton.setIcon(icon: .fontAwesomeRegular(.checkCircle), iconSize: iconSize, color: .dayYesColor, forState: .normal)
        }
    }
    
    @IBAction func bottomStatusButtonPressed(_ sender: Any) {
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
            centerCollectionView()
        //Group kasams that haven't started yet
        } else {
            if SavedData.kasamDict[kasamID]?.groupAdmin == SavedData.userID {
                showOptionsPopup(kasamID: nil, title: "Start your group kasam", subtitle: nil, text: "You'll be starting on \(Date().dateToShortString()) \nwith \(SavedData.kasamDict[kasamID]!.groupTeam!.count.pluralUnit(unit: "member"))", type:"startGroupKasam", button: "Start!") {
                    DBRef.groupKasams.child(SavedData.kasamDict[self.kasamID]!.groupID!).child("Info").updateChildValues(["Status":"active", "Date Joined":Date().dateToString()])
                    SavedData.kasamDict[self.kasamID]?.groupStatus = "active"
                    SavedData.groupKasamBlocks[self.row].data.dayOrder = 1
                    self.cellDelegate?.reloadKasamBlock(kasamOrder: self.row)
                    self.groupStatsTable.reloadData()
                }
            } else {
                showOptionsPopup(kasamID: nil, title: "Leave the kasam?", subtitle: nil, text: "You'll be permanately removing the '\(String(describing: SavedData.kasamDict[kasamID]!.kasamName))' kasam from your Group following. You'll need to be re-invited to rejoin.", type:"leaveGroupKasam", button: "Leave") {
                        DBRef.groupKasams.child(SavedData.kasamDict[self.kasamID]!.groupID!).child("Info").child("Team").child(SavedData.userID).setValue(nil)
                        DBRef.userGroupFollowing.child(SavedData.kasamDict[self.kasamID]!.groupID!).setValue(nil)
                }
            }
        }
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
        let today = Int(tempBlock!.dayOrder)
        if tempBlock != nil && SavedData.kasamDict[(tempBlock!.kasamID)]?.repeatDuration != nil {
            if tempBlock!.dayOrder < SavedData.kasamDict[(tempBlock!.kasamID)]!.repeatDuration {
                let indexPath = IndexPath(item: today - 1, section: 0)
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
                if block?.groupAdmin == SavedData.userID {
                    addButton.isHidden = false
                    addButton.setIcon(icon: .fontAwesomeSolid(.plusCircle), iconSize: 30, color: UIColor.colorFour.darker, forState: .normal)
                    topStatusView.isHidden = true
                    topStatusText.isHidden = true
                    bottomStatusButton?.setIcon(icon: .fontAwesomeSolid(.playCircle), iconSize: iconSize, color: .darkGray, forState: .normal)
                    bottomStatusText.isHidden = false; bottomStatusText.text = "Start"; bottomStatusText.textColor = .darkGray
                } else {
                    topStatusView.isHidden = false
                    topStatusButton.setIcon(icon: .fontAwesomeRegular(.checkCircle), iconSize: iconSize, color: .dayYesColor, forState: .normal)
                    topStatusText.isHidden = false; topStatusText.text = "Accept"; topStatusText.textColor = .dayYesColor
                    bottomStatusButton.setIcon(icon: .fontAwesomeRegular(.timesCircle), iconSize: iconSize, color: .dayNoColor, forState: .normal)
                    bottomStatusText.isHidden = false; bottomStatusText.text = "Leave"; bottomStatusText.textColor = .dayNoColor
                }
                currentDayStreak.text = String(describing:block!.groupTeam?.count ?? 0)
                if block!.groupTeam?.count == 1 {streakPostText.text = "member"} else {streakPostText.text = "members"}
                statsShadow.layer.shadowColor = UIColor.colorFive.cgColor
                statsShadow.layer.shadowOpacity = 1
            } else {
                if type == "group" {addButton.isHidden = true}
            //STEP 1 - DAY COUNTER
                currentDayStat = block!.streakInfo.daysWithAnyProgress
                currentDayStreak.text = String(describing: currentDayStat)
                statsShadow.layer.shadowColor = UIColor.black.cgColor
                statsShadow.layer.shadowOpacity = 0.2
                
            //STEP 2 - Update Percentage complete and Checkmark
                if tempBlock?.dayOrder ?? 0 >= block!.repeatDuration {
                    //STEP 2 - COMPLETED KASAMS
                    bottomStatusButton?.setIcon(icon: .fontAwesomeSolid(.flagCheckered), iconSize: iconSize, color: UIColor.colorFour, forState: .normal)
                    blockSubtitle.frame.size.height = 20
                    blockSubtitle.text = "Complete!"
                    if currentDayStat == block!.repeatDuration {
                        streakShadow.backgroundColor = .dayYesColor
                        topStatusAnimation.isHidden = false; topStatusAnimation.animation = Animations.kasamBadges[1]; topStatusAnimation.backgroundBehavior = .pauseAndRestore
                        topStatusAnimation.play()
                    } else {
                        streakShadow.backgroundColor = .colorFour
                        topStatusView.isHidden = true
                    }
                    statsShadow.layer.shadowColor = UIColor.dayYesColor.darker.darker.cgColor
                    statsShadow.layer.shadowOpacity = 1
                    statsContent.backgroundColor = UIColor.init(hex: 0xf0f6e6)
                    hideDayTrackerView.backgroundColor = UIColor.init(hex: 0xf0f6e6)
                } else {
                    //ONGOING KASAM
                    checkmarkAndPercentageUpdate()
                    topStatusView.isHidden = true
                    blockSubtitle.frame.size.height = 20
                    if SavedData.kasamDict[kasamID]?.displayStatus == "Check" {
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
                if type == "personal" {
                    let ratio = Double(currentDayStat) / Double(block!.repeatDuration)
                    if ratio <= 1 {self.levelLineProgress.constant = self.levelLineBack.frame.width * CGFloat(ratio)}
                    else {self.levelLineProgress.constant = self.levelLineBack.frame.size.width * CGFloat(1)}
                    levelLinePercent.text = "\(Int(ratio * 100))%"
                }
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
            bottomStatusText.isHidden = false
            bottomStatusText.text = "\(Int((SavedData.kasamDict[kasamID]?.percentComplete ?? 0)! * 100))%"
        } else {
            bottomStatusText.isHidden = true
        }
        if SavedData.kasamDict[kasamID]?.displayStatus == "Checkmark" && SavedData.kasamDict[kasamID]!.metricType == "Checkmark" {
            streakShadow.backgroundColor = .colorFour
            bottomStatusButton?.setIcon(icon: .fontAwesomeRegular(.circle), iconSize: iconSize, color: .colorFour, forState: .normal)
        } else if SavedData.kasamDict[kasamID]?.displayStatus == "Checkmark" && SavedData.kasamDict[kasamID]!.metricType != "Checkmark" {
            streakShadow.backgroundColor = .colorFour
            bottomStatusText.textColor = .colorFive
            bottomStatusButton?.setIcon(icon: .fontAwesomeRegular(.playCircle), iconSize: iconSize, color: .colorFour, forState: .normal)
        } else if SavedData.kasamDict[kasamID]?.displayStatus == "Check" {
            streakShadow.backgroundColor = .dayYesColor
            bottomStatusText.textColor = .dayYesColor
            bottomStatusButton?.setIcon(icon: .fontAwesomeSolid(.checkCircle), iconSize: iconSize, color: .dayYesColor, forState: .normal)
        } else if SavedData.kasamDict[kasamID]?.displayStatus == "Progress" {
            streakShadow.backgroundColor = .dayYesColor
            bottomStatusText.textColor = .colorFive
            bottomStatusButton?.setIcon(icon: .fontAwesomeRegular(.playCircle), iconSize: iconSize, color: .colorFour, forState: .normal)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if type == "personal" {
            return 0
        } else {
            return groupStatsList?.count ?? 1
        }
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 25
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupStatsCell") as! GroupStatsCell
        if groupStatsList != nil {
            let userID = groupStatsList![indexPath.row].0
            DBRef.userBase.child(userID).child("Info").child("Name").observeSingleEvent(of: .value) {(username) in
                cell.userInitials.text = (username.value as? String)?.initials()
                if SavedData.kasamDict[self.kasamID]?.groupStatus == "initiated" {
                    if SavedData.kasamDict[self.kasamID]?.groupTeam?[userID] == -1.0 {
                        cell.percentProgress.text = "Invitation Sent"
                    } else {
                        cell.percentProgress.text = "Joined"
                    }
                    cell.percentProgress.textColor = .colorFive
                } else {
                    cell.levelLineProgress.constant = CGFloat((self.groupStatsList![indexPath.row].1)) * (cell.levelLineHolder.frame.size.width - 40)
                    cell.percentProgress.text = "\(Int(self.groupStatsList![indexPath.row].1 * 100))%"
                    cell.percentProgress.textColor = UIColor.init(hex: 0x909090)
                }
                cell.placeStanding.setTitle(String(describing: indexPath.row + 1), for: .normal)
            }
        }
        return cell
    }
}
