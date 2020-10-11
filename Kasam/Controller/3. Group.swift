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
        allTrophiesAchieved()
     }
    
    func setupNotifications(){
        let stopLoadingAnimation = NSNotification.Name("RemoveGroupLoadingAnimation")
        NotificationCenter.default.addObserver(self, selector: #selector(GroupViewController.stopLoadingAnimation), name: stopLoadingAnimation, object: nil)
    }
    
    @objc func updateScrollViewSize(){
        self.updateContentViewHeight(contentViewHeight: self.contentViewHeight, tableViewHeight: self.groupTableHeight, tableRowHeight: self.groupTableRowHeight, additionalTableHeight: nil, rowCount: SavedData.groupKasamBlocks.count, additionalHeight: 160)
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
            if self.initialLoad == false {self.tabBarController?.selectedIndex = 1}
            if snap.exists() {} else {
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
                self.groupFollowingLabel.text = "You have \(SavedData.groupKasamBlocks.count.pluralUnit(unit: "kasam")) for today"
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
            DBRef.coachKasams.child(kasam.kasamID).child("Timeline").observeSingleEvent(of: .value) {(snapshot) in
                let blockDayToLoad = kasam.currentDay % Int(snapshot.childrenCount)
                if let value = snapshot.value as? [String: String] {
                    DBRef.coachKasams.child(kasam.kasamID).child("Blocks").child(value["D\(blockDayToLoad)"] ?? "").observeSingleEvent(of: .value) {(snapshot) in
                        print("Step 3 - Get Block Data hell6 Option 1B \(kasam.kasamName)")
                        self.groupKasamCount += 1
                        self.saveGroupKasamBlocks(value: snapshot.value as! Dictionary<String,Any>, dayOrder: dayOrder, kasam: kasam)
                    }
                }
            }
        //OPTION 2 - Load Kasam as Block (BASIC KASAMS)
        } else if kasam.metricType == "Checkmark" {
            DBRef.coachKasams.child(kasam.kasamID).child("Info").observeSingleEvent(of: .value, with: {(snapshot) in
                print("Step 3 - Get Block Data hell6 Option 2 \(kasam.kasamName)")
                self.groupKasamCount += 1
                if let snapshot = snapshot.value as? Dictionary<String,Any> {
                    self.saveGroupKasamBlocks(value: snapshot, dayOrder: dayOrder, kasam: kasam)
                }
            })
        //OPTION 3 - Load single repeated block (CHALLENGE KASAMS) e.g. 200 Push-ups
        } else {
            DBRef.coachKasams.child(kasam.kasamID).child("Blocks").observeSingleEvent(of: .childAdded, with: {(snapshot) in //childAdded needed
                print("Step 3 - Get Block Data hell6 Option 3 \(kasam.kasamName)")
                self.groupKasamCount += 1
                self.saveGroupKasamBlocks(value: snapshot.value as! Dictionary<String,Any>, dayOrder: dayOrder, kasam: kasam)
            })
        }
    }
    
    //STEP 4
    func saveGroupKasamBlocks(value: Dictionary<String,Any>, dayOrder: Int, kasam: KasamSavedFormat){
        print("Step 4 - Save Kasam Blocks hell6 \((kasam.kasamName))")
        let kasamImage = value["Image"] as! String
        SavedData.kasamDict[kasam.kasamID]?.image = kasamImage
        let block = PersonalBlockFormat(kasamID: kasam.kasamID, groupID: SavedData.kasamDict[kasam.kasamID]?.groupID, blockID: value["BlockID"] as? String ?? "", blockTitle: value["Title"] as! String, dayOrder: dayOrder, duration: value["Duration"] as? String, image: URL(string: kasamImage) ?? URL(string:PlaceHolders.kasamLoadingImageURL)!)
        if let kasamOrder = SavedData.groupKasamBlocks.index(where: {($0.kasamID == kasam.kasamID)}) {
            SavedData.groupKasamBlocks[kasamOrder] = (kasam.kasamID, block)
            if let cell = self.groupKasamTable.cellForRow(at: IndexPath(item: kasamOrder, section: 0)) as? TodayBlockCell {
                cell.blockSubtitle.text = SavedData.groupKasamBlocks[kasamOrder].data.blockTitle
            }
        } else {
            SavedData.groupKasamBlocks.append((kasam.kasamID, block))
            self.getDayTracker(kasamID: block.kasamID, tableView: groupKasamTable, type: "group")
        }
        
        //Only does the below after all Kasams loaded
        if groupKasamCount == SavedData.groupKasamBlocks.count {
            print("Step 4b - Reload Group table with \(groupKasamCount) kasams hell6")
            self.groupFollowingLabel.text = "You have \(SavedData.groupKasamBlocks.count.pluralUnit(unit: "kasam")) for today"
            self.updateScrollViewSize()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToKasamActivityViewer" {
            let kasamViewer = segue.destination as! KasamActivityViewer
            kasamViewer.kasamID = kasamIDTransfer
            kasamViewer.blockID = blockIDGlobal
            kasamViewer.type = "group"
            kasamViewer.blockName = blockNameGlobal
            kasamViewer.dateToLoad = dateGlobal
        } else if segue.identifier == "goToKasamHolder" {
            let kasamTransferHolder = segue.destination as! KasamHolder
            kasamTransferHolder.kasamID = kasamIDTransfer
        }
    }
}

//TABLEVIEW-----------------------------------------------------------------------------------------------

extension GroupViewController: UITableViewDataSource, UITableViewDelegate, TableCellDelegate {
    
    func reloadKasamBlock(kasamOrder: Int) {
        if let cell = groupKasamTable.cellForRow(at: IndexPath(item: kasamOrder, section: 0)) as? TodayBlockCell {
            cell.setBlock(block: SavedData.groupKasamBlocks[kasamOrder].data)
            cell.statusUpdate(nil)
            cell.dayTrackerCollectionView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SavedData.groupKasamBlocks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodayKasamCell") as! TodayBlockCell
        cell.row = indexPath.row
        cell.cellDelegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tableCell = cell as? TodayBlockCell else { return }
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
        let popupImage = UIImage.init(icon: .fontAwesomeSolid(.rocket), size: CGSize(width: 30, height: 30), textColor: .colorFour)
        showCenterPopupConfirmation(title: "Finish & Unfollow?", description: "You'll be unfollowing this Kasam, but your past progress and badges will be saved", image: popupImage, buttonText: "Finish & Unfollow", completion: {(success) in
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
        return CGSize(width: 36, height: 50)    //day tracker
    }
    
    func unhideDayTracker(kasamID: String) {
        //
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DayTrackerCell", for: indexPath) as! DayTrackerCollectionCell
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
    
    func dayPressed(kasamID: String, day: Int, date: Date, metricType: String, viewOnly: Bool?) {
        if day > 0 {
            if let kasamOrder = SavedData.groupKasamBlocks.index(where: {($0.kasamID == kasamID)}) {
                if metricType == "Checkmark" {
                    updateKasamDayButtonPressed(type: "group", kasamOrder: kasamOrder, day: day)
                } else {
                    openKasamBlock(type: "group", kasamOrder: kasamOrder, day: day, date: date, viewOnly: viewOnly, animationView: animationView) {(blockID, blockName) in
                        self.kasamIDTransfer = kasamID
                        self.dateGlobal = date
                        self.blockIDGlobal = blockID
                        self.blockNameGlobal = blockName
                        self.performSegue(withIdentifier: "goToKasamActivityViewer", sender: kasamOrder)
                    }
                }
            }
        }
    }
}
