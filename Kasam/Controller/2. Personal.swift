//
//  KasamCalendar.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-05-15.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Foundation
import FirebaseDatabase
import SDWebImage
import SwiftEntryKit
import Lottie

class PersonalViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var personalFollowingLabel: UILabel!
    @IBOutlet weak var personalKasamTable: SelfSizedTableView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    
    var kasamIDforViewer = ""
    var kasamIDforHolder = ""
    var blockIDGlobal = ""
    var blockNameGlobal = ""
    var dateGlobal: Date?
    var dayToLoadGlobal: Int?
    var viewOnlyGlobal = false
    var personalTableRowHeight = CGFloat(80)
    
    let personalAnimationIcon = AnimationView()
    let animationView = AnimationView()
    
    var personalKasamCount = 0
    var motivationRefHandle: DatabaseHandle!
    var dayTrackerRefHandle: DatabaseHandle!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        personalTableRowHeight = (personalKasamTable.frame.width / 2.4) + 15
        self.getPersonalFollowing()
        setupNavBar(clean: false)                   //global function
        setupNotifications()
    }
    
    func updateScrollViewSize(){
        self.updateContentViewHeight(contentViewHeight: self.contentViewHeight, tableViewHeight: self.tableViewHeight, tableRowHeight: self.personalTableRowHeight, rowCount: SavedData.personalKasamBlocks.count, additionalHeight: 160)
    }
    
    func setupNotifications(){
        let stopLoadingAnimation = NSNotification.Name("RemovePersonalLoadingAnimation")
        NotificationCenter.default.addObserver(self, selector: #selector(PersonalViewController.stopLoadingAnimation), name: stopLoadingAnimation, object: nil)
        
        let resetPersonalKasam = NSNotification.Name("ResetPersonalKasam")
        NotificationCenter.default.addObserver(self, selector: #selector(PersonalViewController.getPersonalFollowing), name: resetPersonalKasam, object: nil)
        
        let goToCreateKasam = NSNotification.Name("GoToCreateKasam")
        NotificationCenter.default.addObserver(self, selector: #selector(PersonalViewController.goToCreateKasam), name: goToCreateKasam, object: nil)
               
        let goToNotifications = NSNotification.Name("GoToNotifications")
        NotificationCenter.default.addObserver(self, selector: #selector(PersonalViewController.goToNotifications), name: goToNotifications, object: nil)
        
        let goToDiscover = NSNotification.Name("GoToDiscover")
        NotificationCenter.default.addObserver(self, selector: #selector(PersonalViewController.goToDiscover), name: goToDiscover, object: nil)
    }
    
    @objc func goToCreateKasam(_ notification: NSNotification?) {
        NewKasam.resetKasam()
        performSegue(withIdentifier: "goToCreateKasam", sender: nil)
    }
    
    @objc func goToNotifications(){
        performSegue(withIdentifier: "goToNotifications", sender: nil)
    }
    
    //-------------------------------------------------------------------------------------------------------
    
    @objc func stopLoadingAnimation(){
        animationView.removeFromSuperview()
    }
    
    @objc func iconTapped(){
        personalAnimationIcon.play()
    }
    
    @objc func goToDiscover(){
        animateTabBarChange(tabBarController: self.tabBarController!, to: self.tabBarController!.viewControllers![0])
        self.tabBarController?.selectedIndex = 0
    }
    
    func showIconCheck(){
        DBRef.userPersonalFollowing.observeSingleEvent(of: .value) {(snap) in
            if snap.exists() {} else {
                self.personalAnimationIcon.isHidden = false
                self.personalFollowingLabel.text = "You're not in any personal kasams"
                self.personalAnimationIcon.loadingAnimation(view: self.contentView, animation: "flagmountainBG", width: 200, overlayView: nil, loop: false, buttonText: "Add a Kasam", completion: nil)
                self.personalAnimationIcon.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.iconTapped)))
                self.updateScrollViewSize()
            }
        }
    }
    
    //STEP 1
    @objc func getPersonalFollowing(){
        print("Step 1 - Get personal following hell6")
        personalKasamCount = 0
        SavedData.personalKasamBlocks.removeAll()
        showIconCheck()
        //Kasam list loaded for first time + if new kasam is added
        DBRef.userPersonalFollowing.observe(.childAdded) {(snapshot) in
            self.personalAnimationIcon.isHidden = true
            self.getPreferences(snapshot: snapshot)
        }
        //If user unfollows a kasam
        DBRef.userPersonalFollowing.observe(.childRemoved) {(snapshot) in
            if let index = SavedData.personalKasamBlocks.index(where: {($0.kasamID == snapshot.key)}) {
                self.personalKasamCount -= 1
                SavedData.personalKasamBlocks.remove(at: index)
                self.personalKasamTable.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                self.updateScrollViewSize()
                self.personalFollowingLabel.text = "You have \(SavedData.personalKasamBlocks.count.pluralUnit(unit: "kasam")) to complete"
                NotificationCenter.default.post(name: Notification.Name(rawValue: "PopDiscoverToRoot"), object: self)
            }
            self.showIconCheck()
        }
        allTrophiesAchieved()
    }
    
    //STEP 2
    func getPreferences(snapshot: DataSnapshot){
        if let value = snapshot.value as? [String: Any] {
            let preference = KasamSavedFormat(kasamID: snapshot.key, kasamName: value["Kasam Name"] as? String ?? "", joinedDate: (value["Date Joined"] as? String ?? "").stringToDate(), startTime: value["Time"] as? String ?? "", currentDay: 1, repeatDuration: value["Repeat"] as? Int ?? 30, image: nil, metricType: value["Metric"] as? String ?? "Checkmark", programDuration: value["Program Duration"] as? Int, streakInfo: (currentStreak:(value: 0,date: nil), daysWithAnyProgress:0, longestStreak:0), displayStatus: "Checkmark", percentComplete: 0.0, badgeList: nil, benefitsThresholds: nil, dayTrackerArray: nil, groupID: nil, groupStatus: nil, groupTeam: nil)
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
        dayOrder = ((Calendar.current.dateComponents([.day], from: kasam.joinedDate, to: Date()).day!) + 1)
        SavedData.kasamDict[kasam.kasamID]?.currentDay = dayOrder
        
        //OPTION 1 - Load blocks based on last completed (PROGRAM KASAMS) e.g. Insanity
        if kasam.programDuration != nil {
            DBRef.userPersonalHistory.child(kasam.kasamID).child(kasam.joinedDate.dateToString()).child(Date().dateToString()).child("BlockID").observeSingleEvent(of: .value) {(snapBlockID) in
                if snapBlockID.exists() {
                    DBRef.coachKasams.child(kasam.kasamID).child("Blocks").child(snapBlockID.value as! String).observeSingleEvent(of: .value) {(snapshot) in
                        print("Step 3 - Get Block Data hell6 Option 1A \(kasam.kasamName)")
                        self.personalKasamCount += 1
                        self.savePersonalKasamBlocks(value: snapshot.value as! Dictionary<String,Any>, dayOrder: dayOrder, kasam: kasam, dayCount: nil)
                    }
                } else {
                    var blockDayToLoad = 1
                    var dayToShow = 1
                    for date in Date.dates(from: kasam.joinedDate, to: Date()) {
                        let dateString = date.dateToString()
                        DBRef.userPersonalHistory.child(kasam.kasamID).child(kasam.joinedDate.dateToString()).child(dateString).observeSingleEvent(of: .value) {(snapCount) in
                            if dateString != Dates.getCurrentDate() && snapCount.exists() {
                                blockDayToLoad += 1               //the user has completed xx number of blocks in the past (excludes today's block)
                            } else if dateString == Dates.getCurrentDate() {
                                DBRef.coachKasams.child(kasam.kasamID).child("Timeline").observeSingleEvent(of: .value, with: {(snapshot) in
                                    if let value = snapshot.value as? [String:String] {
                                        dayToShow = blockDayToLoad
                                        if blockDayToLoad > value.count {
                                            blockDayToLoad = (blockDayToLoad % value.count) + 1
                                        }
                                        DBRef.coachKasams.child(kasam.kasamID).child("Blocks").child(value["D\(blockDayToLoad)"]!).observeSingleEvent(of: .value) {(snapshot) in
                                            print("Step 3 - Get Block Data hell6 Option 1B \(kasam.kasamName)")
                                            self.personalKasamCount += 1
                                            self.savePersonalKasamBlocks(value: snapshot.value as! Dictionary<String,Any>, dayOrder: dayOrder, kasam: kasam, dayCount: dayToShow)
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
                self.personalKasamCount += 1
                if let snapshot = snapshot.value as? Dictionary<String,Any> {
                    self.savePersonalKasamBlocks(value: snapshot, dayOrder: dayOrder, kasam: kasam, dayCount: nil)
                }
            })
        //OPTION 3 - Load single repeated block (CHALLENGE KASAMS) e.g. 200 Push-ups
        } else {
            DBRef.coachKasams.child(kasam.kasamID).child("Blocks").observeSingleEvent(of: .childAdded, with: {(snapshot) in //childAdded needed
                print("Step 3 - Get Block Data hell6 Option 3 \(kasam.kasamName)")
                self.personalKasamCount += 1
                self.savePersonalKasamBlocks(value: snapshot.value as! Dictionary<String,Any>, dayOrder: dayOrder, kasam: kasam, dayCount: nil)
            })
        }
    }
    
    //STEP 4
    func savePersonalKasamBlocks(value: Dictionary<String,Any>, dayOrder: Int, kasam: KasamSavedFormat, dayCount: Int?){
        print("Step 4 - Save Kasam Blocks hell6 \((kasam.kasamName))")
        let kasamImage = value["Image"] as! String
        SavedData.kasamDict[kasam.kasamID]?.image = kasamImage
        let block = PersonalBlockFormat(kasamID: kasam.kasamID, blockID: value["BlockID"] as? String ?? "", blockTitle: value["Title"] as! String, dayOrder: dayOrder, duration: value["Duration"] as? String, image: URL(string: kasamImage) ?? URL(string:PlaceHolders.kasamLoadingImageURL)!, dayCount: dayCount)
        if let kasamOrder = SavedData.personalKasamBlocks.index(where: {($0.kasamID == kasam.kasamID)}) {
            SavedData.personalKasamBlocks[kasamOrder] = (kasam.kasamID, block)
            if let cell = self.personalKasamTable.cellForRow(at: IndexPath(item: kasamOrder, section: 0)) as? PersonalBlockCell {
                cell.blockSubtitle.text = SavedData.personalKasamBlocks[kasamOrder].data.blockTitle
            }
        } else {
            SavedData.personalKasamBlocks.append((kasam.kasamID, block))
            self.getDayTracker(kasamID: block.kasamID)
        }
        
        //Only does the below after all Kasams loaded
        if personalKasamCount == SavedData.personalKasamBlocks.count {
            print("Step 4b - Reload Personal table with \(personalKasamCount) kasams hell6")
            self.personalFollowingLabel.text = "You have \(SavedData.personalKasamBlocks.count.pluralUnit(unit: "kasam")) to complete"
            self.personalKasamTable.reloadData()
            self.updateScrollViewSize()
        }
    }
    
    //STEP 5
    func getDayTracker(kasamID: String) {
        //for the active Kasams on the Personal page
        if let kasam = SavedData.kasamDict[kasamID] {
            print("Step 5 - Day Tracker hell6 \(kasam.kasamName)")
            //Gets the DayTracker info - only goes into this loop if the user has kasam history
            self.dayTrackerRefHandle = DBRef.userPersonalHistory.child(kasam.kasamID).child(kasam.joinedDate.dateToString()).observe(.value, with: {(snap) in
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
                        if history.key == Dates.getCurrentDate() {
                            percentComplete = dayPercent
                            if dayPercent == 1 {displayStatus = "Check"}
                            else if dayPercent < 1 && dayPercent > 0 {displayStatus = "Progress"}
                        }
                        
                        if internalCount == dayCount {
                            //DayTrackerArrayInternal adds the status of each day
                            SavedData.kasamDict[(kasam.kasamID)]?.displayStatus = displayStatus
                            SavedData.kasamDict[(kasam.kasamID)]?.percentComplete = percentComplete         //only for COMPLEX kasams
                            SavedData.kasamDict[kasam.kasamID]?.dayTrackerArray = dayTrackerArrayInternal
                            
                            if let index = SavedData.personalKasamBlocks.index(where: {($0.kasamID == kasam.kasamID)}) {
                                SavedData.kasamDict[kasam.kasamID]?.streakInfo = self.currentStreak(dictionary: dayTrackerArrayInternal, currentDay: SavedData.personalKasamBlocks[index].data.dayOrder)
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "RefreshKasamHolderBadge"), object: self)
                                self.singleKasamUpdate(kasamOrder: index, tableView: self.personalKasamTable, type: "personal")
                            }
                        }
                    }
                } else {
                    SavedData.kasamDict[kasam.kasamID]?.dayTrackerArray = nil
                    SavedData.kasamDict[(kasam.kasamID)]?.displayStatus = "Checkmark"
                    SavedData.kasamDict[kasam.kasamID]?.streakInfo = (currentStreak:(value:0, date:nil), daysWithAnyProgress:0, longestStreak:0)
                    SavedData.kasamDict[(kasam.kasamID)]?.percentComplete = 0
                    if let index = SavedData.personalKasamBlocks.index(where: {($0.kasamID == kasam.kasamID)}) {
                        self.singleKasamUpdate(kasamOrder: index, tableView: self.personalKasamTable, type: "personal")
                    }
                }
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToKasamActivityViewer" {
            let kasamViewer = segue.destination as! KasamActivityViewer
            kasamViewer.kasamID = kasamIDforViewer
            kasamViewer.blockID = blockIDGlobal
            kasamViewer.type = "personal"
            kasamViewer.blockName = blockNameGlobal
            kasamViewer.viewingOnlyCheck = viewOnlyGlobal
            kasamViewer.dateToLoad = dateGlobal
            kasamViewer.dayToLoad = dayToLoadGlobal
        } else if segue.identifier == "goToKasamHolder" {
            let kasamTransferHolder = segue.destination as! KasamHolder
            kasamTransferHolder.kasamID = kasamIDforHolder
        } else if segue.identifier == "goToNotifications" {
            //No variables to set
        }
    }
}

//TABLEVIEW-----------------------------------------------------------------------------------------------

extension PersonalViewController: UITableViewDataSource, UITableViewDelegate, TableCellDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SavedData.personalKasamBlocks.count
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
        return personalTableRowHeight
    }
    
    func goToKasamHolder(kasamOrder: Int) {
        if SavedData.personalKasamBlocks.count > kasamOrder {
            kasamIDforHolder = SavedData.personalKasamBlocks[kasamOrder].1.kasamID
        }
        self.performSegue(withIdentifier: "goToKasamHolder", sender: kasamOrder)
    }
    
    func reloadKasamBlock(kasamOrder: Int) {
        if let cell = personalKasamTable.cellForRow(at: IndexPath(item: kasamOrder, section: 0)) as? PersonalBlockCell {
            cell.statusUpdate(nil)
        }
    }
    
    func completeAndUnfollow(kasamOrder: Int) {
        let popupImage = UIImage.init(icon: .fontAwesomeSolid(.rocket), size: CGSize(width: 30, height: 30), textColor: .white)
        showPopupConfirmation(title: "Finish & Unfollow?", description: "You'll be unfollowing this Kasam, but your past progress and badges will be saved", image: popupImage, buttonText: "Finish & Unfollow", completion: {(success) in
            let kasamID = SavedData.personalKasamBlocks[kasamOrder].1.kasamID
            DBRef.userPersonalFollowing.child(kasamID).child("Status").setValue("completed")
            self.getPersonalFollowing()
        })
    }
}

//COLLECTIONVIEW------------------------------------------------------------------------

extension PersonalViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, DayTrackerCellDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if SavedData.personalKasamBlocks.count > collectionView.tag {        //ensures the kasam is loaded before reading the dayTracker
            return SavedData.kasamDict[SavedData.personalKasamBlocks[collectionView.tag].kasamID]?.repeatDuration ?? 0
        } else {
            return 10
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 37, height: 50)    //day tracker
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DayTrackerCell", for: indexPath) as! PersonalDayTrackerCell
        if SavedData.personalKasamBlocks.count > collectionView.tag {
            cell.dayTrackerDelegate = self
            let kasamBlock = SavedData.personalKasamBlocks[collectionView.tag]
            let day = indexPath.row + 1
            let today = Int(kasamBlock.data.dayOrder)
            let date = dayTrackerDateFormat(date: Date(), todayDay: today, row: indexPath.row + 1)
            cell.setBlock(kasamID: kasamBlock.kasamID, day: day, status: SavedData.kasamDict[kasamBlock.kasamID]?.dayTrackerArray?[indexPath.row + 1]?.progress ?? 0.0, date: date , today: day == today, future: day > today)
        }
        return cell
    }
    
    func dayPressed(kasamID: String, day: Int, date: Date?, metricType: String, viewOnly: Bool?) {
        if let kasamOrder = SavedData.personalKasamBlocks.index(where: {($0.kasamID == kasamID)}) {
            if metricType == "Checkmark" {
                updateKasamDayButtonPressed(kasamOrder: kasamOrder, day: day)
            } else {
                openKasamBlock(kasamOrder: kasamOrder, day: day, date: date, viewOnly: viewOnly)
            }
        }
    }
    
    func updateKasamDayButtonPressed(kasamOrder: Int, day: Int){
        let kasamID = SavedData.personalKasamBlocks[kasamOrder].data.kasamID
        let statusDate = (Calendar.current.date(byAdding: .day, value: day - SavedData.personalKasamBlocks[kasamOrder].data.dayOrder, to: Date())!).dateToString()
        if SavedData.kasamDict[kasamID]?.dayTrackerArray?[day] != nil {
            if SavedData.kasamDict[kasamID]?.dayTrackerArray?[day]?.1 == 1.0 {
                DBRef.userPersonalHistory.child(kasamID).child((SavedData.kasamDict[kasamID]?.joinedDate.dateToString())!).child(statusDate).setValue(nil)
            }
        } else {
            DBRef.userPersonalHistory.child(kasamID).child((SavedData.kasamDict[kasamID]?.joinedDate.dateToString())!).child(statusDate).setValue(1)
        }
    }
    
    func openKasamBlock(kasamOrder: Int, day: Int?, date: Date?, viewOnly: Bool?) {
        animationView.loadingAnimation(view: view, animation: "loading", width: 100, overlayView: nil, loop: true, buttonText: nil, completion: nil)
        UIApplication.shared.beginIgnoringInteractionEvents()
        let kasamID = SavedData.personalKasamBlocks[kasamOrder].kasamID
        kasamIDforViewer = kasamID
        blockIDGlobal = SavedData.personalKasamBlocks[kasamOrder].data.blockID
        blockNameGlobal = SavedData.personalKasamBlocks[kasamOrder].data.blockTitle
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
