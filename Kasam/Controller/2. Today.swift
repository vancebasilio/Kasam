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
import SDWebImage
import SwiftEntryKit
import Lottie

class TodayViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var personalFollowingLabel: UILabel!
    @IBOutlet weak var personalKasamTable: SelfSizedTableView!
    @IBOutlet weak var addKasamButton: UIButton!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    
    //Tranfer variables
    var kasamIDforViewer = ""
    var kasamIDforHolder = ""
    var blockIDGlobal = ""
    var blockNameGlobal = ""
    var dateGlobal: Date?
    
    let type = "personal"
    var sectionHeight = CGFloat(40)
    var personalTableRowHeight = CGFloat(80)
    var personalKasamCount = 0
    
    let personalAnimationIcon = AnimationView()
    let animationView = AnimationView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loginUser()
        personalTableRowHeight = (personalKasamTable.frame.width / 3) + 15      //height of today cell
        self.getPersonalFollowing()
        setupNavBar(clean: false)                                               //global function
        setupNotifications()
        addKasamButton.setIcon(icon: .fontAwesomeSolid(.plus), iconSize: 30, color: .darkGray, backgroundColor: .clear, forState: .normal)
    }
    
    func setupNotifications(){
        let stopLoadingAnimation = NSNotification.Name("RemovePersonalLoadingAnimation")
        NotificationCenter.default.addObserver(self, selector: #selector(TodayViewController.stopLoadingAnimation), name: stopLoadingAnimation, object: nil)
        
        let refreshPersonalKasam = NSNotification.Name("RefreshPersonalKasam")
        NotificationCenter.default.addObserver(self, selector: #selector(TodayViewController.refreshPersonalKasam), name: refreshPersonalKasam, object: nil)
    }
    
    func updateScrollViewSize(){
        self.updateContentViewHeight(contentViewHeight: self.contentViewHeight, tableViewHeight: self.tableViewHeight, tableRowHeight: self.personalTableRowHeight, additionalTableHeight: sectionHeight, rowCount: SavedData.todayKasamBlocks[type]!.count + SavedData.upcomingKasamBlocks[type]!.count, additionalHeight: 100)
    }
    
    //-------------------------------------------------------------------------------------------------------
    
    @objc func stopLoadingAnimation(){
        animationView.removeFromSuperview()
    }
    
    @objc func iconTapped(){
        personalAnimationIcon.play()
    }
    
    func showIconCheck(){
        DBRef.userPersonalFollowing.observeSingleEvent(of: .value) {(snap) in
            if snap.exists() {} else {
                self.personalAnimationIcon.isHidden = false
                self.personalFollowingLabel.text = "You don't have any kasams"
                self.personalAnimationIcon.loadingAnimation(view: self.contentView, animation: "flagmountainBG", width: 200, overlayView: nil, loop: false, buttonText: nil, completion: nil)
                self.personalAnimationIcon.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.iconTapped)))
                self.updateScrollViewSize()
            }
        }
    }
    
    @objc func refreshPersonalKasam(_ kasamOrderTransfer: NSNotification?){
        if let index = kasamOrderTransfer?.userInfo?["kasamOrder"] as? Int {
            singleKasamUpdate(tableView: personalKasamTable, row: index, section: 0, reset: false)
        }
    }
    
    //STEP 1
    @objc func getPersonalFollowing(){
        print("Step 1 - Get personal following")
        SavedData.todayKasamBlocks[type] = []
        showIconCheck()
        DBRef.userPersonalFollowing.observe(.value) {(snapshot) in
            self.personalKasamCount = Int(snapshot.childrenCount)
        }
        //Kasam list loaded for first time + if new kasam is added
        DBRef.userPersonalFollowing.observe(.childAdded) {(snapshot) in
            self.personalAnimationIcon.isHidden = true
            self.getPreferences(snapshot: snapshot)
        }
        //If user unfollows a kasam
        DBRef.userPersonalFollowing.observe(.childRemoved) {(snapshot) in
            if let index = SavedData.todayKasamBlocks[self.type]!.index(where: {($0.kasamID == snapshot.key)}) {
                SavedData.todayKasamBlocks[self.type]!.remove(at: index)
                self.personalKasamTable.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                self.updateScrollViewSize()
                self.personalFollowingLabel.text = "You have \(SavedData.todayKasamBlocks[self.type]!.count.pluralUnit(unit: "kasam")) to complete"
                NotificationCenter.default.post(name: Notification.Name(rawValue: "PopDiscoverToRoot"), object: self)
            }
            self.showIconCheck()
        }
        //If restarting a kasam
        DBRef.userPersonalFollowing.observe(.childChanged) {(snapshot) in
            //If changing current kasam to start in the future
            if let index = SavedData.todayKasamBlocks[self.type]!.index(where: {($0.kasamID == snapshot.key)}) {
                if let cell = self.personalKasamTable.cellForRow(at: IndexPath(item: index, section: 0)) as? TodayBlockCell {
                    cell.state = "restart"                     //to tell the singleKasamUpdate func to reload the block
                    self.getPreferences(snapshot: snapshot)
                }
            }
            //If changing upcoing kasam to start today
            if let index = SavedData.upcomingKasamBlocks[self.type]!.index(where: {($0.kasamID == snapshot.key)}) {
                if let cell = self.personalKasamTable.cellForRow(at: IndexPath(item: index, section: 1)) as? TodayBlockCell {
                    cell.state = "restart"                    //to tell the singleKasamUpdate func to reload the block
                    self.getPreferences(snapshot: snapshot)
                }
            }
        }
    }
    
    //STEP 2
    func getPreferences(snapshot: DataSnapshot){
        if let value = snapshot.value as? [String: Any] {
            let preference = KasamSavedFormat(kasamID: snapshot.key, kasamName: value["Kasam Name"] as? String ?? "", joinedDate: (value["Date Joined"] as? String ?? "").stringToDate(), startTime: value["Time"] as? String ?? "", currentDay: 1, repeatDuration: value["Repeat"] as? Int ?? 30, image: nil, metricType: value["Metric"] as? String ?? "Checkmark", programDuration: value["Program Duration"] as? Int, streakInfo: (currentStreak:(value: 0,date: nil), daysWithAnyProgress:0, longestStreak:0), displayStatus: "NotStarted", percentComplete: 0.0, badgeList: nil, benefitsThresholds: nil, dayTrackerArray: nil, groupID: nil, groupAdmin: nil, groupStatus: nil, groupTeam: nil)
            DispatchQueue.main.async {snapshot.key.benefitThresholds()}
            print("Step 2 - Get preferences hell6 \(preference.kasamName)")
            SavedData.kasamDict[preference.kasamID] = preference
            self.getBlockDetails(kasamID: preference.kasamID)
        }
    }
    
    //STEP 3
    func getBlockDetails(kasamID: String) {
        //STEP 3 - Finds out which block should be called based on the day of the kasam the user is on
        let kasam = SavedData.kasamDict[kasamID]!
        print("Step 3 - Get Block Data \(kasam.kasamName)")
        //Seeing which blocks are needed for the day
        SavedData.kasamDict[kasam.kasamID]?.currentDay = kasam.joinedDate.daysBetween(endDate: Date()) + 1
        
        //OPTION 1 - Load blocks based on day (PROGRAM KASAMS) e.g. Insanity
        if kasam.programDuration != nil {
            DBRef.coachKasams.child(kasam.kasamID).child("Timeline").observeSingleEvent(of: .value) {(snapshot) in
                var blockDayToLoad = kasam.currentDay % Int(snapshot.childrenCount)
                if blockDayToLoad <= 0 {blockDayToLoad = Int(snapshot.childrenCount)}
                if let value = snapshot.value as? [String: String] {
                    DBRef.coachKasams.child(kasam.kasamID).child("Blocks").child(value["D\(blockDayToLoad)"] ?? "").observeSingleEvent(of: .value) {(snapshot) in
                        print("Step 3B - Get Block Data hell6 Option 1 \(kasam.kasamName)")
                        self.saveKasamBlocks(value: snapshot.value as? Dictionary<String,Any>, dayOrder: SavedData.kasamDict[kasam.kasamID]!.currentDay, kasam: kasam, type: self.type, tableView: self.personalKasamTable, kasamCount: self.personalKasamCount, followingLabel: self.personalFollowingLabel){(status) in if status == true {self.updateScrollViewSize()}}
                    }
                }
            }
        //OPTION 2 - Load Kasam as Block (BASIC KASAMS)
        } else if kasam.metricType == "Checkmark" {
            DBRef.coachKasams.child(kasam.kasamID).child("Info").observeSingleEvent(of: .value, with: {(snapshot) in
                print("Step 3B - Get Block Data Option 2 \(kasam.kasamName)")
                if let snapshot = snapshot.value as? Dictionary<String,Any> {
                    self.saveKasamBlocks(value: snapshot, dayOrder: SavedData.kasamDict[kasam.kasamID]!.currentDay, kasam: kasam, type: self.type, tableView: self.personalKasamTable, kasamCount: self.personalKasamCount, followingLabel: self.personalFollowingLabel){(status) in if status == true {self.updateScrollViewSize()}}
                }
            })
        //OPTION 3 - Load single repeated block (CHALLENGE KASAMS) e.g. 200 Push-ups
        } else {
            DBRef.coachKasams.child(kasam.kasamID).child("Blocks").observeSingleEvent(of: .childAdded, with: {(snapshot) in
                print("Step 3B - Get Block Data Option 3 \(kasam.kasamName)")
                self.saveKasamBlocks(value: snapshot.value as? Dictionary<String,Any>, dayOrder: SavedData.kasamDict[kasam.kasamID]!.currentDay, kasam: kasam, type: self.type, tableView: self.personalKasamTable, kasamCount: self.personalKasamCount, followingLabel: self.personalFollowingLabel){(status) in if status == true {self.updateScrollViewSize()}}
            })
        }
    }
    
    //---------------------------------------------------------------------------------------------------------
    
    func stopObserving(ref: AnyObject?, handle: DatabaseHandle?) {
        guard ref != nil else {
            return
        }
        ref?.removeObserver(withHandle: handle!)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func addKasamButtonPressed(_ sender: Any) {
        goToCreateNewKasam(type: "basic")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToKasamActivityViewer" {
            let kasamViewer = segue.destination as! KasamActivityViewer
            kasamViewer.kasamID = kasamIDforViewer
            kasamViewer.blockID = blockIDGlobal
            kasamViewer.type = type
            kasamViewer.blockName = blockNameGlobal
            kasamViewer.dateToLoad = dateGlobal
        } else if segue.identifier == "goToKasamHolder" {
            let kasamTransferHolder = segue.destination as! KasamHolder
            kasamTransferHolder.kasamID = kasamIDforHolder
        }
    }
}

//TABLEVIEW-----------------------------------------------------------------------------------------------

extension TodayViewController: UITableViewDataSource, UITableViewDelegate, TableCellDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return SavedData.todayKasamBlocks[type]?.count ?? 0 }
        else { return SavedData.upcomingKasamBlocks[type]!.count }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return sectionHeader(text: "Upcoming", color: .colorFive, leading: 10)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 || (section == 1 && SavedData.upcomingKasamBlocks[type]!.count == 0) {return 0}
        else {return sectionHeight}
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TodayKasamCell") as? TodayBlockCell else {return UITableViewCell()}
        cell.cellDelegate = self
        if indexPath.section == 0 {cell.setBlock(block: SavedData.todayKasamBlocks[type]![indexPath.row].data, row: indexPath.row, section: indexPath.section, type: type)}
        else {cell.setBlock(block: SavedData.upcomingKasamBlocks[type]![indexPath.row].data, row: indexPath.row, section: indexPath.section, type: type)}
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? TodayBlockCell else { return }
        DispatchQueue.main.async {
            cell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, forRow: (indexPath.section * 100) + indexPath.row)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return personalTableRowHeight
    }
    
    func goToKasamHolder(kasamOrder: Int, section: Int) {
        if SavedData.todayKasamBlocks[type]!.count > kasamOrder {
            if section == 0 {kasamIDforHolder = SavedData.todayKasamBlocks[type]![kasamOrder].1.kasamID}
            else {kasamIDforHolder = SavedData.upcomingKasamBlocks[type]![kasamOrder].1.kasamID}
        }
        self.performSegue(withIdentifier: "goToKasamHolder", sender: kasamOrder)
    }
    
    func reloadKasamBlock(kasamOrder: Int) {
        if let cell = personalKasamTable.cellForRow(at: IndexPath(item: kasamOrder, section: 0)) as? TodayBlockCell {
            cell.statusUpdate(day: nil)
        }
    }
    
    func completeAndUnfollow(kasamOrder: Int) {
        let popupImage = UIImage.init(icon: .fontAwesomeSolid(.rocket), size: CGSize(width: 30, height: 30), textColor: .colorFour)
        showCenterPopupConfirmation(title: "Finish & Unfollow?", description: "You'll be unfollowing this Kasam, but your past progress and badges will be saved", image: popupImage, buttonText: "Finish & Unfollow", completion: {(success) in
            let kasamID = SavedData.todayKasamBlocks[self.type]![kasamOrder].1.kasamID
            DBRef.userPersonalFollowing.child(kasamID).child("Status").setValue("completed")
            self.getPersonalFollowing()
        })
    }
}

//COLLECTIONVIEW------------------------------------------------------------------------

extension TodayViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let tableRow = collectionView.tag % 100
        let tableSection = (collectionView.tag - tableRow)/100
        var block = SavedData.todayKasamBlocks[type]!
        if tableSection == 1 { block = SavedData.upcomingKasamBlocks[type]!}
        if block.count > tableRow {                 //ensures kasam is loaded before reading the dayTracker
            return SavedData.kasamDict[block[tableRow].kasamID]?.repeatDuration ?? 0
        } else {
            return 10                               //in case the daytracker can't get any info
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView.frame.height > 40 {
            return CGSize(width: 36, height: 50)    //expand day tracker
        } else {
            return CGSize(width: 16, height: 20)    //shrink day tracker
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let row = collectionView.tag % 100
        let section = (collectionView.tag - row)/100
        let tableCell = self.personalKasamTable.cellForRow(at: IndexPath(item: row, section: section)) as? TodayBlockCell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DayTrackerCell", for: indexPath) as! DayTrackerCollectionCell
        var block = SavedData.todayKasamBlocks[type]!
        if section == 1 {block = SavedData.upcomingKasamBlocks[type]!}
        if block.count > row {
            cell.dayTrackerDelegate = self
            if tableCell?.isDayTrackerHidden != true {cell.cellButton.titleLabel?.layer.opacity = 100; cell.dayTrackerDate.isHidden = false}
            else {cell.cellButton.titleLabel?.layer.opacity = 0; cell.dayTrackerDate.isHidden = true}
            let day = indexPath.row + 1
            let today = Int(block[row].data.dayOrder)
            let date = dayTrackerDateFormat(date: Date(), todayDay: today, row: indexPath.row + 1)
            cell.setBlock(row: row, section: section, kasamID: block[row].kasamID, day: day, status: SavedData.kasamDict[block[row].kasamID]?.dayTrackerArray?[indexPath.row + 1]?.progress ?? 0.0, date: date , today: day == today, future: day > today)
        }
        return cell
    }
}
    
extension TodayViewController: DayTrackerCellDelegate {
    
    func dayPressed(kasamID: String, day: Int, date: Date, metricType: String, viewOnly: Bool?) {
        if let kasamOrder = SavedData.todayKasamBlocks[type]!.index(where: {($0.kasamID == kasamID)}) {
            if metricType == "Checkmark" {
                updateKasamDayButtonPressed(type: type, kasamOrder: kasamOrder, day: day)
            } else {
                openKasamBlock(type: type, kasamOrder: kasamOrder, day: day, date: date, viewOnly: viewOnly, animationView: animationView) {(blockID, blockName) in
                    self.kasamIDforViewer = kasamID
                    self.dateGlobal = date
                    self.blockIDGlobal = blockID
                    self.blockNameGlobal = blockName
                    self.performSegue(withIdentifier: "goToKasamActivityViewer", sender: kasamOrder)
                }
            }
        }
    }
    
    func unhideDayTracker(section: Int, row: Int){
        if let tableCell = self.personalKasamTable.cellForRow(at: IndexPath(item: row, section: section)) as? TodayBlockCell {
            tableCell.hideDayTracker()
        }
    }
}
