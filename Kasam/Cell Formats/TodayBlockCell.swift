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
import AMPopTip

protocol TableCellDelegate : class {
    func dayPressed(kasamID: String, day: Int, date: Date, metricType: String, viewOnly: Bool?)
    func goToKasamHolder(kasamOrder: Int, section: Int)
    func completeAndUnfollow(kasamOrder: Int)
    func reloadKasamBlock(kasamOrder: Int)
}

class TodayBlockCell: UITableViewCell {
    
    @IBOutlet weak var kasamName: UILabel!
    @IBOutlet weak var blockSubtitle: UILabel!
    @IBOutlet weak var blockSubtitleHeight: NSLayoutConstraint!
    
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
    @IBOutlet weak var dayTrackerCollectionHolderHeight: NSLayoutConstraint!
    
    @IBOutlet weak var dayTrackerCollectionTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var hideDayTrackerButton: UIButton!
    @IBOutlet weak var restartButton: UIButton!
    @IBOutlet weak var groupStatsTable: UITableView!
    
    //Loaded in values
    var rowInternal = 0
    var sectionInternal = 0
    var typeInternal = ""
    var state = ""
    
    var cellDelegate: TableCellDelegate?
    var tempBlock: TodayBlockFormat?
    var kasamID = ""
    var isDayTrackerHidden = true
    var upcomingDuration = ""
    let iconSize = CGFloat(35)
    var currentDayStat = 0
    let popTip = PopTip()
    var popTipStatus = false
    var groupStatsList = [(userID: String, name: String, status: Double)]()
    
    func setCollectionViewDataSourceDelegate(dataSourceDelegate: UICollectionViewDataSource & UICollectionViewDelegate, forRow row: Int) {
        self.dayTrackerCollectionView.delegate = dataSourceDelegate
        self.dayTrackerCollectionView.dataSource = dataSourceDelegate
        self.dayTrackerCollectionView.tag = row
    }
    
    func setBlock(block: TodayBlockFormat, row: Int, section: Int, type: String) {
        if state == "" || state == "restart" {
            print("hell1 \(block.blockTitle)")
            rowInternal = row
            sectionInternal = section
            typeInternal = type
            kasamID = block.kasamID
            tempBlock = block
            kasamName.text = SavedData.kasamDict[kasamID]?.kasamName
            kasamImage.sd_setImage(with: block.image)
            
            if type == "group" {
                setGroup()
            } else {
                levelLineBack.layer.cornerRadius = 4
                levelLineMask.layer.cornerRadius = 4
                levelLine.mask = levelLineMask
            }
            state = "loaded"
        }
    }
    
    func resetBlockName(){
        print("hell8 \(blockSubtitle.text)")
        //Show the block subtite if it's a PROGRAM kasam
        if SavedData.kasamDict[kasamID]?.programDuration != nil && tempBlock != nil {
            blockSubtitle.text = String(describing: tempBlock!.blockTitle)
        //Hide the block subtitle
        } else if SavedData.kasamDict[kasamID]?.displayStatus != "Upcoming" {
            blockSubtitleHeight.constant = 0
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
        
        dayTrackerCollectionHolderHeight.constant = 20
        
        hideDayTrackerButton.setIcon(icon: .fontAwesomeRegular(.calendar), iconSize: 15, color: UIColor.darkGray, forState: .normal)
        restartButton.setIcon(icon: .fontAwesomeSolid(.sync), iconSize: 15, color: UIColor.colorFour, forState: .normal)
    
        blockImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showBenefit)))
        kasamName.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(kasamNamePressed)))
        progressBar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideDayTracker)))
    }
    
    @objc func kasamNamePressed(){
        cellDelegate?.goToKasamHolder(kasamOrder: rowInternal, section: sectionInternal)
    }
    
    func extendButtonPressed(_ complete: Bool){
        var type = "complete"
        if complete == true {type = "completeTrophy"}
        showCenterOptionsPopup(kasamID: kasamID, title: "Kasam Completed!", subtitle: SavedData.kasamDict[kasamID]!.kasamName, text: "Go another \(SavedData.kasamDict[kasamID]!.repeatDuration) days by pressing 'Restart' or close off the kasam by pressing 'Finish'", type: type, button: "Restart") {(completion) in
            if completion == true {
                self.restartKasam()
            }
        }
    }
    
    @objc func showBenefit(){
        if typeInternal == "group" && SavedData.kasamDict[kasamID]?.groupStatus == "initiated" {
            showCenterGroupUserSearch(kasamID: kasamID) {
                //
            }
        } else {
            if SavedData.kasamDict[kasamID]?.displayStatus == "Upcoming" {
                showCenterOptionsPopup(kasamID: kasamID, title: kasamName.text, subtitle: nil, text: "This kasam starts tomorrow", type: "waiting", button: "Okay") {(completion) in}
            } else {
                if currentDayStat >= SavedData.kasamDict[(kasamID)]!.repeatDuration {
                    extendButtonPressed(currentDayStat >= SavedData.kasamDict[(kasamID)]!.repeatDuration)
                } else if SavedData.kasamDict[kasamID]?.benefitsThresholds != nil {
                    let benefit = currentDayStat.nearestElement(array: (SavedData.kasamDict[kasamID]?.benefitsThresholds)!)
                    showCenterOptionsPopup(kasamID: kasamID, title: "Day \(benefit!.0)", subtitle: nil, text: benefit?.1, type: "benefit", button: "Awesome!") {(completion) in}
                } else {
                    showCenterOptionsPopup(kasamID: kasamID, title: "Day \(currentDayStat)", subtitle: nil, text: nil, type: "benefit", button: "Done") {(completion) in}
                }
            }
        }
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
            cellDelegate?.dayPressed(kasamID: kasamID, day: tempBlock?.dayOrder ?? 1, date: Date(), metricType: SavedData.kasamDict[tempBlock!.kasamID]!.metricType, viewOnly: false)
            centerCollectionView()
        //Group kasams that haven't started yet
        } else if typeInternal == "group" {
            if SavedData.kasamDict[kasamID]?.groupAdmin == SavedData.userID {
                showCenterOptionsPopup(kasamID: nil, title: "Start your group kasam", subtitle: nil, text: "You'll be starting on \(Date().dateToShortString()) \nwith \(SavedData.kasamDict[kasamID]!.groupTeam!.count.pluralUnit(unit: "member"))", type:"startGroupKasam", button: "Start!") {(mainButtonPressed) in
                    DBRef.groupKasams.child(SavedData.kasamDict[self.kasamID]!.groupID!).child("Info").updateChildValues(["Status":"active", "Date Joined":Date().dateToString()])
                    SavedData.kasamDict[self.kasamID]?.groupStatus = "active"
                    SavedData.todayKasamBlocks["group"]![self.rowInternal].data.dayOrder = 1
                    self.cellDelegate?.reloadKasamBlock(kasamOrder: self.rowInternal)
                    self.groupStatsTable.reloadData()
                }
            } else {
                showCenterOptionsPopup(kasamID: nil, title: "Leave the kasam?", subtitle: nil, text: "You'll be permanately removing the '\(String(describing: SavedData.kasamDict[kasamID]!.kasamName))' kasam from your Group following. You'll need to be re-invited to rejoin.", type:"leaveGroupKasam", button: "Leave") {(mainButtonPressed) in
                        DBRef.groupKasams.child(SavedData.kasamDict[self.kasamID]!.groupID!).child("Info").child("Team").child(SavedData.userID).setValue(nil)
                        DBRef.userGroupFollowing.child(SavedData.kasamDict[self.kasamID]!.groupID!).setValue(nil)
                }
            }
        //Kasam hasn't started
        } else if SavedData.kasamDict[kasamID]?.displayStatus == "Upcoming" {
            showCenterOptionsPopup(kasamID: kasamID, title: kasamName.text, subtitle: nil, text: "This kasam starts \(upcomingDuration)", type: "waiting", button: "Okay") {(completion) in}
        }
    }
    
    @IBAction func hideDayTrackerDateButtonPressed(_ sender: Any) {
        hideDayTracker()
    }
    
    @objc func hideDayTracker(){
        //Show more info on day tracker
        if isDayTrackerHidden == true {
            if typeInternal != "group" {
                dayTrackerCollectionHolderHeight.constant = 50
                dayTrackerCollectionView.frame.size = CGSize(width: dayTrackerCollectionView.frame.width, height: 50)
                if kasamName.calculateMaxLines() == 2 {blockSubtitleHeight.constant = 0}
                overallLabel.isHidden = true
                isDayTrackerHidden = false
                dayTrackerCollectionView.reloadData()
                dayTrackerCollectionView.performBatchUpdates(nil, completion: nil)
                centerCollectionView()
            } else {
                dayTrackerCollectionTopConstraint.constant = 0
            }
        //Hide more info on day tracker
        } else {
            if typeInternal != "group" {
                dayTrackerCollectionHolderHeight.constant = 20
                if kasamName.calculateMaxLines() == 2 {blockSubtitleHeight.constant = 20}
                overallLabel.isHidden = false
                isDayTrackerHidden = true
                dayTrackerCollectionView.reloadData()
                dayTrackerCollectionView.performBatchUpdates(nil, completion: nil)
            } else {
                dayTrackerCollectionTopConstraint.constant = 10
            }
        }
    }
    
    @IBAction func restartButtonPressed(_ sender: Any) {
        restartKasam()
    }
    
    func restartKasam(){
        var saveTimeObserver: NSObjectProtocol?
        showBottomAddKasamPopup(kasamID: kasamID, state:"restart", duration: SavedData.kasamDict[kasamID]!.repeatDuration)
        saveTimeObserver = NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "SaveTime\(kasamID)"), object: nil, queue: OperationQueue.main) {(notification) in
            let timeVC = notification.object as! AddKasamController
            DBRef.userPersonalFollowing.child(self.kasamID).updateChildValues(["Date Joined": timeVC.formattedDate, "Repeat": timeVC.repeatDuration, "Time": timeVC.formattedTime]) {(error, reference) in
                NotificationCenter.default.removeObserver(saveTimeObserver as Any)
            }
        }
    }
    
    @objc func centerCollectionView() {
        if dayTrackerCollectionView.numberOfItems(inSection: 0) != 0 && SavedData.kasamDict[(tempBlock!.kasamID)]?.repeatDuration != nil && Int(tempBlock!.dayOrder) > 0 {
            var indexPath = IndexPath()
            if tempBlock!.dayOrder < SavedData.kasamDict[(tempBlock!.kasamID)]!.repeatDuration {
                let today = Int(tempBlock!.dayOrder)
                indexPath = IndexPath(item: today - 1, section: 0)
            } else {
                //If the currentDay is more than the repeatDuration
                indexPath = IndexPath(item: SavedData.kasamDict[(tempBlock!.kasamID)]!.repeatDuration - 1, section: 0)
            }
            self.dayTrackerCollectionView.collectionViewLayout.prepare()        //ensures the contentsize is accurate before centering cells
            self.dayTrackerCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        }
    }
    
    func statusUpdate(day: String?){
        if tempBlock != nil && SavedData.kasamDict[kasamID] != nil {
            let block = SavedData.kasamDict[kasamID]
            print("Step 5B - Block status update \(String(describing: block?.kasamName))")
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
                if typeInternal == "group" {addButton.isHidden = true}
            //STEP 1 - DAY COUNTER
                currentDayStat = block!.streakInfo.daysWithAnyProgress
                currentDayStreak.text = String(describing: currentDayStat)
                statsShadow.layer.shadowColor = UIColor.black.cgColor
                statsShadow.layer.shadowOpacity = 0.2
                
            //STEP 2 - Update Percentage complete and Checkmark
                if tempBlock?.dayOrder ?? 0 >= block!.repeatDuration {
                    //COMPLETED KASAM
                    bottomStatusButton?.setIcon(icon: .fontAwesomeSolid(.flagCheckered), iconSize: iconSize, color: UIColor.colorFour, forState: .normal)
                    blockSubtitleHeight.constant = 20
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
                } else {
                    //ONGOING KASAM
                    checkmarkAndPercentageUpdate()
                    topStatusView.isHidden = true
                    if SavedData.kasamDict[kasamID]?.displayStatus == "Check" {
                        statsShadow.layer.shadowColor = UIColor.dayYesColor.cgColor
                        statsShadow.layer.shadowOpacity = 1
                    }
                    if SavedData.kasamDict[kasamID]?.displayStatus != "Upcoming" {statsContent.backgroundColor = UIColor.white}
                    if block?.programDuration == nil && block?.displayStatus != "Upcoming" {blockSubtitleHeight.constant = 0; blockSubtitle.text = ""} else {blockSubtitleHeight.constant = 20}
                }
                
                if block!.streakInfo.daysWithAnyProgress == 1 {streakPostText.text = "day completed"} else {streakPostText.text = "days completed"}
                
            //STEP 3 - Set level line progress
                if typeInternal == "personal" {
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
        //UPCOMING KASAM
        if SavedData.kasamDict[kasamID]?.displayStatus == "Upcoming" {
            progressBar.isHidden = true
            restartButton.setIcon(icon: .fontAwesomeSolid(.sync), iconSize: 15, color: .lightGray, forState: .normal)
            let interval = -(SavedData.kasamDict[kasamID]!.joinedDate.daysBetween(date: Date()))
            if interval == 1 {upcomingDuration = "tomorrow"}
            else {upcomingDuration = "in \(interval.pluralUnit(unit: "day"))"}
            blockSubtitle.text = "Starts \(upcomingDuration)";
            streakShadow.backgroundColor = .lightGray
            bottomStatusText.isHidden = true
            statsShadow.layer.shadowColor = UIColor.lightGray.cgColor
            statsShadow.layer.shadowOpacity = 0.6
            bottomStatusButton?.setIcon(icon: .fontAwesomeSolid(.stopwatch), iconSize: iconSize, color: .lightGray, forState: .normal)
        } else {
        //ACTIVE KASAM
            progressBar.isHidden = false
            restartButton.setIcon(icon: .fontAwesomeSolid(.sync), iconSize: 15, color: UIColor.colorFour, forState: .normal)
            
            if SavedData.kasamDict[kasamID]!.metricType == "Checkmark" {
                bottomStatusButton?.setIcon(icon: .fontAwesomeRegular(.circle), iconSize: iconSize, color: .colorFour, forState: .normal)
            } else if SavedData.kasamDict[kasamID]!.metricType != "Checkmark" {
                if let percent = ((SavedData.kasamDict[kasamID]?.percentComplete)) {
                    if percent >= 0 {bottomStatusText.isHidden = false; bottomStatusText.text = "\(Int(percent * 100))%"}
                    else {bottomStatusText.isHidden = true}
                }
                bottomStatusText.textColor = .colorFive
                bottomStatusButton?.setIcon(icon: .fontAwesomeRegular(.playCircle), iconSize: iconSize, color: .colorFour, forState: .normal)
            }
            
            if SavedData.kasamDict[kasamID]?.displayStatus == "NotStarted" {
                streakShadow.backgroundColor = .colorFour
                bottomStatusText.isHidden = true
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
    }
}

//For Group Kasams only
extension TodayBlockCell: UITableViewDelegate, UITableViewDataSource {
    
    func setGroup(){
        restartButton.isHidden = true
        progressBar.isHidden = true
        groupStatsView.layer.cornerRadius = 15.0
        groupStatsTable.delegate = self
        groupStatsTable.dataSource = self
        popTip.shouldDismissOnTapOutside = true
        popTip.shouldDismissOnTap = true
        popTip.shouldDismissOnSwipeOutside = true
        popTip.bubbleColor = .darkGray
        
        //New user added to group kasam
        DBRef.groupKasams.child((SavedData.kasamDict[kasamID]?.groupID)!).child("Info").child("Team").observe(.childAdded) {(snap) in
            SavedData.kasamDict[self.kasamID]?.groupTeam?[snap.key] = snap.value as? Double
            DBRef.users.child(snap.key).child("Info").child("Name").observeSingleEvent(of: .value) {(userName) in
                self.groupStatsList.append((userID: snap.key, name: userName.value as? String ?? "", status: snap.value as? Double ?? 0.0))
                self.groupStatsList = self.groupStatsList.sorted(by: {$0.status > $1.status})
            }
            self.groupStatsTable.reloadData()
            self.statusUpdate(day: nil)
        }
        
        //To update the kasam stats table
        DBRef.groupKasams.child((SavedData.kasamDict[kasamID]?.groupID)!).child("Info").child("Team").observe(.childChanged) {(snap) in
            SavedData.kasamDict[self.kasamID]?.groupTeam?[snap.key] = snap.value as? Double
//            self.groupStatsList = SavedData.kasamDict[self.kasamID]?.groupTeam?.sorted{ $0.value > $1.value }
            self.groupStatsTable.reloadData()
        }
        
        //User removed from group kasam
        DBRef.groupKasams.child((SavedData.kasamDict[kasamID]?.groupID)!).child("Info").child("Team").observe(.childRemoved) {(snap) in
            SavedData.kasamDict[self.kasamID]?.groupTeam?[snap.key] = nil
//            self.groupStatsList = SavedData.kasamDict[self.kasamID]?.groupTeam?.sorted{ $0.value > $1.value }
            self.groupStatsTable.reloadData()
            self.statusUpdate(day: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if typeInternal == "personal" {
            return 0
        } else {
            return groupStatsList.count 
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 25
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "GroupStatsCell") as? GroupStatsCell else {return UITableViewCell()}
        let info = groupStatsList[indexPath.row]
        cell.userInitials.text = info.name.initials()
        cell.placeStanding.setTitle(String(describing: indexPath.row + 1), for: .normal)
        cell.selectionStyle = .none
        if SavedData.kasamDict[self.kasamID]?.groupStatus == "initiated" {
            if info.status == -1.0 {
                if info.userID == Auth.auth().currentUser?.uid {cell.percentProgress.text = "Invitation Pending"}
                else {cell.percentProgress.text = "Invitation Sent"}
            } else {
                cell.percentProgress.text = "Joined"
            }
            cell.percentProgress.textColor = .colorFive
        } else {
            cell.levelLineProgress.constant = CGFloat((info.status)) * (cell.levelLineHolder.frame.size.width - 40)
            cell.percentProgress.text = "\(Int(info.status * 100))%"
            cell.percentProgress.textColor = UIColor.init(hex: 0x909090)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "GroupStatsCell") as? GroupStatsCell else {return}
        let x = cell.userInitials.frame.maxX + groupStatsTable.frame.minX
        let y = tableView.rectForRow(at: indexPath).midY + groupStatsTable.frame.minY
        showPopTipName(name: groupStatsList[indexPath.row].name, x: x, y: y)
    }
    
    func showPopTipName(name: String, x: CGFloat, y: CGFloat) {
        popTip.appearHandler = {popTip in self.popTipStatus = true}
        popTip.dismissHandler = {popTip in self.popTipStatus = false}
        if popTipStatus == false {popTip.show(text: name, direction: .right, maxWidth: 200, in: groupStatsView, from: CGRect(x: x, y: y, width: 0, height: 0), duration: 2)}
        else {popTip.hide()}
    }
}
