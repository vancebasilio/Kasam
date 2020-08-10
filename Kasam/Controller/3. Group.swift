//
//  KasamCalendar.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-05-15.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Foundation
import Firebase
import FirebaseDatabase
import FirebaseAuth
import SDWebImage
import SwiftEntryKit
import Lottie

class GroupViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var groupFollowingLabel: UILabel!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    @IBOutlet weak var groupKasamTable: SelfSizedTableView!
    @IBOutlet weak var groupTableHeight: NSLayoutConstraint!
    
    var kasamIDTransfer = ""
    var blockIDGlobal = ""
    var blockNameGlobal = ""
    var dateGlobal: Date?
    var dayToLoadGlobal: Int?
    var viewOnlyGlobal = false
    var groupTableRowHeight = CGFloat(80)
    var initialLoad = false
    
    let groupAnimationIcon = AnimationView()
    let animationView = AnimationView()
    
    var groupKasamCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loginUser()
        setupNavBar(clean: false)                   //global function
        groupTableRowHeight = (groupKasamTable.frame.width / 1.8) + 15
        getGroupFollowing()
        setupNotifications()
     }
    
    func setupNotifications(){
        let stopLoadingAnimation = NSNotification.Name("RemoveGroupLoadingAnimation")
        NotificationCenter.default.addObserver(self, selector: #selector(GroupViewController.stopLoadingAnimation), name: stopLoadingAnimation, object: nil)
    }
    
    func updateScrollViewSize(){
        self.updateContentViewHeight(contentViewHeight: self.contentViewHeight, tableViewHeight: self.groupTableHeight, tableRowHeight: self.groupTableRowHeight, rowCount: SavedData.groupKasamBlocks.count, additionalHeight: 160)
        self.initialLoad = true
    }
    
    @objc func iconTapped(){
        groupAnimationIcon.play()
    }
    
    @objc func stopLoadingAnimation(){
        animationView.removeFromSuperview()
    }
    
    //-------------------------------------------------------------------------------------------------------
    
    func showIconCheck(){
        DBRef.userGroupFollowing.observeSingleEvent(of: .value) {(snap) in
            if snap.exists() {} else {
                if self.initialLoad == false {
                    self.tabBarController?.selectedIndex = 1
                }
                self.groupAnimationIcon.isHidden = false
                self.groupFollowingLabel.text = "You're not in any group kasams"
                self.groupAnimationIcon.loadingAnimation(view: self.contentView, animation: "crownSeptors", width: 200, overlayView: nil, loop: false, buttonText: "Add a Kasam", completion: nil)
                self.groupAnimationIcon.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.iconTapped)))
                self.updateScrollViewSize()
            }
        }
    }
    
    //STEP 1
    func getGroupFollowing(){
        groupKasamCount = 0
        SavedData.groupKasamBlocks.removeAll()
        showIconCheck()
        
        DBRef.userGroupFollowing.observe(.childAdded) {(groupID) in
            self.groupAnimationIcon.isHidden = true
            DBRef.groupKasams.child(groupID.key).child("Info").observeSingleEvent(of: .value, with: {(snapshot) in
                self.getPreferences(snapshot: snapshot, groupID: groupID.key, reminderTime: (groupID.value as? [String:String])?["Time"] ?? "")
            })
        }
        //If user unfollows a group kasam
        DBRef.userGroupFollowing.observe(.childRemoved) {(snapshot) in
            print("hell9 group kasam unfollowed")
            if let index = SavedData.groupKasamBlocks.index(where: {($0.data.groupID == snapshot.key)}) {
                self.groupKasamCount -= 1
                SavedData.groupKasamBlocks.remove(at: index)
                self.groupKasamTable.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                self.groupFollowingLabel.text = "You have \(SavedData.groupKasamBlocks.count.pluralUnit(unit: "kasam")) to complete"
            }
            self.showIconCheck()
        }
    }
    
    //STEP 2
    func getPreferences(snapshot: DataSnapshot, groupID: String, reminderTime: String){
        if let value = snapshot.value as? [String: Any] {
            let preference = KasamSavedFormat(kasamID: value["KasamID"] as? String ?? "", kasamName: value["Kasam Name"] as? String ?? "", joinedDate: (value["Date Joined"] as? String ?? "").stringToDate(), startTime: reminderTime, currentDay: 1, repeatDuration: value["Repeat"] as? Int ?? 30, image: nil,  metricType: value["Metric"] as? String ?? "Checkmark", programDuration: value["Program Duration"] as? Int, streakInfo: (currentStreak:(value: 0,date: nil), daysWithAnyProgress:0, longestStreak:0), displayStatus: "Checkmark", percentComplete: 0.0, badgeList: nil, benefitsThresholds: nil, dayTrackerArray: nil, groupID: groupID, groupAdmin: value["Admin"] as? String, groupStatus: value["Status"] as? String, groupTeam: value["Team"] as? [String:Double])
            DispatchQueue.main.async {snapshot.key.benefitThresholds()}
            print("Step 2 - Get preferences hell6 \(preference.kasamName)")
            SavedData.addKasam(kasam: preference)
            self.getBlockDetails(kasamID: preference.kasamID)
        }
    }
    
    //STEP 3
    func getBlockDetails(kasamID: String) {
        //STEP 3 - Finds out which block should be called based on the day of the kasam the user is on
        let kasam = SavedData.kasamDict[kasamID]!
        print("Step 3 - Get Block Data hell6 \(kasam.kasamName)")
        var dayOrder = 0
        //Seeing which blocks are needed for the day
        if kasam.groupStatus != "initiated" {
            dayOrder = ((Calendar.current.dateComponents([.day], from: kasam.joinedDate, to: Date()).day!) + 1)
        }
        SavedData.kasamDict[kasam.kasamID]?.currentDay = dayOrder
        
        //OPTION 1 - Load blocks based on last completed (PROGRAM KASAMS) e.g. Insanity
        if kasam.programDuration != nil {
            DBRef.userPersonalHistory.child(kasam.kasamID).child(kasam.joinedDate.dateToString()).child(Date().dateToString()).child("BlockID").observeSingleEvent(of: .value) {(snapBlockID) in
                if snapBlockID.exists() {
                    DBRef.coachKasams.child(kasam.kasamID).child("Blocks").child(snapBlockID.value as! String).observeSingleEvent(of: .value) {(snapshot) in
                        print("Step 3 - Get Block Data hell6 Option 1A \(kasam.kasamName)")
                        self.groupKasamCount += 1
                        self.saveGroupKasamBlocks(value: snapshot.value as! Dictionary<String,Any>, dayOrder: dayOrder, kasam: kasam, dayCount: nil)
                    }
                } else {
                    var blockDayToLoad = 1
                    var dayToShow = 1
                    for date in Date.dates(from: kasam.joinedDate, to: Date()) {
                        let dateString = date.dateToString()
                        DBRef.userPersonalHistory.child(kasam.kasamID).child(kasam.joinedDate.dateToString()).child(dateString).observeSingleEvent(of: .value) {(snapCount) in
                            if dateString != self.getCurrentDate() && snapCount.exists() {
                                blockDayToLoad += 1               //the user has completed xx number of blocks in the past (excludes today's block)
                            } else if dateString == self.getCurrentDate() {
                                DBRef.coachKasams.child(kasam.kasamID).child("Timeline").observeSingleEvent(of: .value, with: {(snapshot) in
                                    if let value = snapshot.value as? [String:String] {
                                        dayToShow = blockDayToLoad
                                        if blockDayToLoad > value.count {
                                            blockDayToLoad = (blockDayToLoad % value.count) + 1
                                        }
                                        DBRef.coachKasams.child(kasam.kasamID).child("Blocks").child(value["D\(blockDayToLoad)"]!).observeSingleEvent(of: .value) {(snapshot) in
                                            print("Step 3 - Get Block Data hell6 Option 1B \(kasam.kasamName)")
                                            self.groupKasamCount += 1
                                            self.saveGroupKasamBlocks(value: snapshot.value as! Dictionary<String,Any>, dayOrder: dayOrder, kasam: kasam, dayCount: dayToShow)
                                        }
                                    }
                                })
                            }
                        }
                    }
                }
            }
        //OPTION 2 - Load Kasam as Block (BASIC KASAMS)
        } else if kasam.metricType == "Checkmark" {
            DBRef.coachKasams.child(kasam.kasamID).observeSingleEvent(of: .value, with: {(snapshot) in
                print("Step 3 - Get Block Data hell6 Option 2 \(kasam.kasamName)")
                self.groupKasamCount += 1
                if let snapshot = snapshot.value as? Dictionary<String,Any> {
                    self.saveGroupKasamBlocks(value: snapshot, dayOrder: dayOrder, kasam: kasam, dayCount: nil)
                }
            })
        //OPTION 3 - Load single repeated block (CHALLENGE KASAMS) e.g. 200 Push-ups
        } else {
            DBRef.coachKasams.child(kasam.kasamID).child("Blocks").observeSingleEvent(of: .childAdded, with: {(snapshot) in //childAdded needed
                print("Step 3 - Get Block Data hell6 Option 3 \(kasam.kasamName)")
                self.groupKasamCount += 1
                self.saveGroupKasamBlocks(value: snapshot.value as! Dictionary<String,Any>, dayOrder: dayOrder, kasam: kasam, dayCount: nil)
            })
        }
    }
    
    //STEP 4
    func saveGroupKasamBlocks(value: Dictionary<String,Any>, dayOrder: Int, kasam: KasamSavedFormat, dayCount: Int?){
        print("Step 4 - Save Kasam Blocks hell6 \((kasam.kasamName))")
        let kasamImage = value["Image"] as! String
        SavedData.kasamDict[kasam.kasamID]?.image = kasamImage
        let block = PersonalBlockFormat(kasamID: kasam.kasamID, groupID: SavedData.kasamDict[kasam.kasamID]?.groupID, blockID: value["BlockID"] as? String ?? "", blockTitle: value["Title"] as! String, dayOrder: dayOrder, duration: value["Duration"] as? String, image: URL(string: kasamImage) ?? URL(string:PlaceHolders.kasamLoadingImageURL)!, dayCount: dayCount)
        if let kasamOrder = SavedData.groupKasamBlocks.index(where: {($0.kasamID == kasam.kasamID)}) {
            SavedData.groupKasamBlocks[kasamOrder] = (kasam.kasamID, block)
            if let cell = self.groupKasamTable.cellForRow(at: IndexPath(item: kasamOrder, section: 0)) as? PersonalBlockCell {
                print("hell1 subtitle to \(SavedData.groupKasamBlocks[kasamOrder].data.blockTitle)")
                cell.blockSubtitle.text = SavedData.groupKasamBlocks[kasamOrder].data.blockTitle
            }
        } else {
            SavedData.groupKasamBlocks.append((kasam.kasamID, block))
            self.getDayTracker(kasamID: block.kasamID)
        }
        
        //Only does the below after all Kasams loaded
        if groupKasamCount == SavedData.groupKasamBlocks.count {
            print("Step 4b - Reload Group table with \(groupKasamCount) kasams hell6")
            self.groupFollowingLabel.text = "You have \(SavedData.groupKasamBlocks.count.pluralUnit(unit: "kasam")) to complete"
            self.groupKasamTable.reloadData()
            self.updateScrollViewSize()
        }
    }
    
    //STEP 5
    func getDayTracker(kasamID: String) {
        //For the active Kasams on the Group page
        if let kasam = SavedData.kasamDict[kasamID] {
            print("Step 5 - Day Tracker hell6 \(kasam.kasamName)")
            //Gets the DayTracker info - only goes into this loop if the user has kasam history
            DBRef.groupKasams.child((SavedData.kasamDict[kasamID]?.groupID)!).child("History").child(Auth.auth().currentUser!.uid).observe(.value, with: {(snap) in
                if SavedData.kasamDict[kasamID]?.programDuration != nil {self.getBlockDetails(kasamID: kasamID)}    //Only for updates to timeline kasams
                if snap.exists() {
                    var displayStatus = "Checkmark"
                    var order = 0
                    var dayTrackerArrayInternal = [Int:(Date,Double)]()
                    var dayPercent = 1.0
                    var percentComplete = 0.0
                    let dayCount = snap.childrenCount
                    var internalCount = 0
                    
                    for history in snap.children.allObjects as! [DataSnapshot] {
                        let kasamDate = history.key.stringToDate()
                        internalCount += 1
                        order = (Calendar.current.dateComponents([.day], from: kasam.joinedDate, to: kasamDate)).day! + 1
                        dayPercent = self.statusPercentCalc(snapshot: history).0
                        dayTrackerArrayInternal[order] = (kasamDate, dayPercent)
                        
                        //Status for Current day
                        if history.key == self.getCurrentDate() {
                            percentComplete = dayPercent
                            if dayPercent == 1 {displayStatus = "Check"}
                            else if dayPercent < 1 && dayPercent > 0 {displayStatus = "Progress"}
                        }
                        
                        if internalCount == dayCount {
                            //DayTrackerArrayInternal adds the status of each day
                            SavedData.kasamDict[(kasam.kasamID)]?.displayStatus = displayStatus
                            SavedData.kasamDict[(kasam.kasamID)]?.percentComplete = percentComplete         //only for COMPLEX kasams
                            SavedData.kasamDict[kasam.kasamID]?.dayTrackerArray = dayTrackerArrayInternal
                            
                            if let index = SavedData.groupKasamBlocks.index(where: {($0.kasamID == kasam.kasamID)}) {
                                SavedData.kasamDict[kasam.kasamID]?.streakInfo = self.currentStreak(dictionary: dayTrackerArrayInternal, currentDay: SavedData.groupKasamBlocks[index].data.dayOrder)
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "RefreshKasamHolderBadge"), object: self)
                                self.singleKasamUpdate(kasamOrder: index, tableView: self.groupKasamTable, type: "group")
                            }
                        }
                    }
                } else {
                    SavedData.kasamDict[kasam.kasamID]?.dayTrackerArray = nil
                    SavedData.kasamDict[(kasam.kasamID)]?.displayStatus = "Checkmark"
                    SavedData.kasamDict[kasam.kasamID]?.streakInfo = (currentStreak:(value:0, date:nil), daysWithAnyProgress:0, longestStreak:0)
                    SavedData.kasamDict[(kasam.kasamID)]?.percentComplete = 0
                    if let index = SavedData.groupKasamBlocks.index(where: {($0.kasamID == kasam.kasamID)}) {
                        self.singleKasamUpdate(kasamOrder: index, tableView: self.groupKasamTable, type: "group")
                    }
                }
            })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToKasamActivityViewer" {
            let kasamViewer = segue.destination as! KasamActivityViewer
            kasamViewer.kasamID = kasamIDTransfer
            kasamViewer.blockID = blockIDGlobal
            kasamViewer.type = "group"
            kasamViewer.blockName = blockNameGlobal
            kasamViewer.viewingOnlyCheck = viewOnlyGlobal
            kasamViewer.dateToLoad = dateGlobal
            kasamViewer.dayToLoad = dayToLoadGlobal
        } else if segue.identifier == "goToKasamHolder" {
            let kasamTransferHolder = segue.destination as! KasamHolder
            kasamTransferHolder.kasamID = kasamIDTransfer
        } else if segue.identifier == "goToNotifications" {
            //No variables to set
        }
    }
}

//TABLEVIEW-----------------------------------------------------------------------------------------------

extension GroupViewController: UITableViewDataSource, UITableViewDelegate, TableCellDelegate {
    
    func reloadKasamBlock(kasamOrder: Int) {
        if let cell = groupKasamTable.cellForRow(at: IndexPath(item: kasamOrder, section: 0)) as? PersonalBlockCell {
            cell.setBlock(block: SavedData.groupKasamBlocks[kasamOrder].data)
            cell.statusUpdate(nil)
            cell.dayTrackerCollectionView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SavedData.groupKasamBlocks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PersonalKasamCell") as! PersonalBlockCell
        cell.row = indexPath.row
        cell.cellDelegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tableCell = cell as? PersonalBlockCell else { return }
        tableCell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return groupTableRowHeight
    }
    
    func goToKasamHolder(kasamOrder: Int) {
        if SavedData.groupKasamBlocks.count > kasamOrder {
            kasamIDTransfer = SavedData.groupKasamBlocks[kasamOrder].1.kasamID
        }
        self.performSegue(withIdentifier: "goToKasamHolder", sender: kasamOrder)
    }
    
    func completeAndUnfollow(kasamOrder: Int) {
        let popupImage = UIImage.init(icon: .fontAwesomeSolid(.rocket), size: CGSize(width: 30, height: 30), textColor: .white)
        showPopupConfirmation(title: "Finish & Unfollow?", description: "You'll be unfollowing this Kasam, but your past progress and badges will be saved", image: popupImage, buttonText: "Finish & Unfollow", completion: {(success) in
            let kasamID = SavedData.groupKasamBlocks[kasamOrder].1.kasamID
            DBRef.userGroupFollowing.child(kasamID).child("Status").setValue("completed")
            self.getGroupFollowing()
        })
    }
}

//COLLECTIONVIEW------------------------------------------------------------------------

extension GroupViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, DayTrackerCellDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if SavedData.groupKasamBlocks.count > collectionView.tag {        //ensures the kasam is loaded before reading the dayTracker
            return SavedData.kasamDict[SavedData.groupKasamBlocks[collectionView.tag].kasamID]?.repeatDuration ?? 0
        } else {
            return 10
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 37, height: 50)    //day tracker
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DayTrackerCell", for: indexPath) as! PersonalDayTrackerCell
        if SavedData.groupKasamBlocks.count > collectionView.tag {
            cell.dayTrackerDelegate = self
            let kasamBlock = SavedData.groupKasamBlocks[collectionView.tag]
            let day = indexPath.row + 1
            var today = Int(kasamBlock.data.dayOrder)
            if SavedData.kasamDict[SavedData.groupKasamBlocks[collectionView.tag].kasamID]?.groupStatus == "initiated" {today = 1}
            let date = dayTrackerDateFormat(date: Date(), todayDay: today, row: indexPath.row + 1)
            cell.setBlock(kasamID: kasamBlock.kasamID, day: day, status: SavedData.kasamDict[kasamBlock.kasamID]?.dayTrackerArray?[indexPath.row + 1]?.progress ?? 0.0, date: date , today: day == today, future: day > today)
        }
        return cell
    }
    
    func dayPressed(kasamID: String, day: Int, date: Date?, metricType: String, viewOnly: Bool?) {
        if day > 0 {
            if let kasamOrder = SavedData.groupKasamBlocks.index(where: {($0.kasamID == kasamID)}) {
                if metricType == "Checkmark" {
                    updateKasamDayButtonPressed(kasamOrder: kasamOrder, day: day)
                } else {
                    openKasamBlock(kasamOrder: kasamOrder, day: day, date: date, viewOnly: viewOnly)
                }
            }
        }
    }
    
    func updateKasamDayButtonPressed(kasamOrder: Int, day: Int){
        let kasamID = SavedData.groupKasamBlocks[kasamOrder].data.kasamID
        var newPercent = (SavedData.kasamDict[kasamID]?.groupTeam?[Auth.auth().currentUser!.uid] ?? 0)
        let statusDate = (Calendar.current.date(byAdding: .day, value: day - SavedData.groupKasamBlocks[kasamOrder].data.dayOrder, to: Date())!).dateToString()
        if SavedData.kasamDict[kasamID]?.dayTrackerArray?[day] != nil {
            if SavedData.kasamDict[kasamID]?.dayTrackerArray?[day]?.1 == 1.0 {
                DBRef.groupKasams.child((SavedData.kasamDict[kasamID]?.groupID)!).child("History").child(Auth.auth().currentUser!.uid).child(statusDate).setValue(nil)
                newPercent -= (1.0 / Double(SavedData.kasamDict[kasamID]?.repeatDuration ?? 30))
            }
        } else {
            DBRef.groupKasams.child((SavedData.kasamDict[kasamID]?.groupID)!).child("History").child(Auth.auth().currentUser!.uid).child(statusDate).setValue(1)
             newPercent += (1.0 / Double(SavedData.kasamDict[kasamID]?.repeatDuration ?? 30))
            
        }
        DBRef.groupKasams.child((SavedData.kasamDict[kasamID]?.groupID)!).child("Info").child("Team").child(Auth.auth().currentUser!.uid).setValue(newPercent.rounded(toPlaces: 2))
    }
    
    func openKasamBlock(kasamOrder: Int, day: Int?, date: Date?, viewOnly: Bool?) {
        animationView.loadingAnimation(view: view, animation: "loading", width: 100, overlayView: nil, loop: true, buttonText: nil, completion: nil)
        UIApplication.shared.beginIgnoringInteractionEvents()
        let kasamID = SavedData.groupKasamBlocks[kasamOrder].kasamID
        kasamIDTransfer = kasamID
        blockIDGlobal = SavedData.groupKasamBlocks[kasamOrder].data.blockID
        blockNameGlobal = SavedData.groupKasamBlocks[kasamOrder].data.blockTitle
        dateGlobal = date
        
        //OPTION 1 - Opening a past day's block
        if day != nil {
            viewOnlyGlobal = viewOnly ?? false
            DBRef.coachKasams.child(kasamID).child("Blocks").observeSingleEvent(of: .value, with: {(blockCountSnapshot) in
                let blockCount = Int(blockCountSnapshot.childrenCount)
                var blockOrder = 1
                if SavedData.kasamDict[kasamID]?.programDuration != nil {
                    //OPTION 1A - Day in past, so find the correct block to show
                    if day! <= blockCount {blockOrder = day!}
                    else {blockOrder = (day! % blockCount) + 1}
                    DBRef.coachKasams.child(kasamID).child("Timeline").observe(.value, with: {(snapshot) in
                        if let value = snapshot.value as? [String:String] {
                            self.blockIDGlobal = value["D\(blockOrder)"]!
                            self.definesPresentationContext = true
                            self.performSegue(withIdentifier: "goToKasamActivityViewer", sender: kasamOrder)
                        }
                    })
                } else {
                    //OPTION 1B - Day in past and Kasam has only 1 block, so no point finding the correct block
                    if day! <= blockCount {blockOrder = day!}
                    else {blockOrder = (blockCount / day!) + 1}
                    self.performSegue(withIdentifier: "goToKasamActivityViewer", sender: kasamOrder)
                }
                self.dayToLoadGlobal = day
            })
        //OPTION 2 - Open Today's block
        } else {
            self.performSegue(withIdentifier: "goToKasamActivityViewer", sender: kasamOrder)
        }
    }
}
