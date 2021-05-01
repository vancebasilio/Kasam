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
import FirebaseAnalytics
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
    var userKasam = false
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
            singleKasamUpdate(row: index, section: 0, reset: false)
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
                print("Unfollowed kasam \(String(describing: SavedData.todayKasamBlocks[self.type]?[index].data.blockTitle))")
                SavedData.todayKasamBlocks[self.type]!.remove(at: index)
                if let cell = self.personalKasamTable.cellForRow(at: IndexPath(item: index, section: 0)) as? TodayBlockCell {
                    cell.state = ""                     //If a new kasam is added, setting the state to "" allows it to be reloaded
                }
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
            //If changing upcoming kasam to start today
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
            let preference = KasamSavedFormat(kasamID: snapshot.key, kasamName: value["Kasam Name"] as? String ?? "", joinedDate: (value["Date Joined"] as? String ?? "").stringToDate(), startTime: value["Time"] as? String ?? "", currentDay: 1, repeatDuration: value["Repeat"] as? Int ?? 30, image: nil, metricType: value["Metric"] as? String ?? "Checkmark", programDuration: value["Program Duration"] as? Int, streakInfo: (currentStreak:(value: 0,date: nil), daysWithAnyProgress:0, longestStreak:0), displayStatus: "NotStarted", percentComplete: 0.0, badgeList: nil, benefitsThresholds: nil, dayTrackerArray: nil, userKasam: value["User Kasam"] as? Bool ?? false, groupID: nil, groupAdmin: nil, groupStatus: nil, groupTeam: nil)
            DispatchQueue.main.async {snapshot.key.benefitThresholds()}
            print("Step 2 - Get preferences \((preference.kasamName, preference.kasamID))")
            SavedData.kasamDict[preference.kasamID] = preference
            self.getBlockDetails(kasamID: preference.kasamID)
        }
    }
    
    //STEP 3
    func getBlockDetails(kasamID: String) {
        //STEP 3 - Finds out which block should be called based on the day of the kasam the user is on
        let kasam = SavedData.kasamDict[kasamID]!
        var kasamDB = DatabaseReference()
        if kasam.userKasam == true {kasamDB = DBRef.userKasams.child(kasamID)}
        else {kasamDB = DBRef.coachKasams.child(kasamID)}
        print("Step 3 - Get Block Data \(kasam.kasamName)")
        //Seeing which blocks are needed for the day
        SavedData.kasamDict[kasam.kasamID]?.currentDay = kasam.joinedDate.daysBetween(endDate: Date()) + 1
        
        //OPTION 1 - Load blocks based on day (PROGRAM KASAMS) e.g. Insanity
        if kasam.programDuration != nil {
            kasamDB.child("Timeline").observeSingleEvent(of: .value) {(snapshot) in
                var blockDayToLoad = kasam.currentDay % Int(snapshot.childrenCount)
                if blockDayToLoad <= 0 {blockDayToLoad = Int(snapshot.childrenCount)}
                if let value = snapshot.value as? [String: String] {
                    kasamDB.child("Blocks").child(value["D\(blockDayToLoad)"] ?? "").observeSingleEvent(of: .value) {(snapshot) in
                        print("Step 3B - Get Block Data Option 1 \(kasam.kasamName)")
                        self.saveKasamBlocks(value: snapshot.value as? Dictionary<String,Any>, dayOrder: SavedData.kasamDict[kasam.kasamID]!.currentDay, kasam: kasam, type: self.type, kasamCount: self.personalKasamCount, followingLabel: self.personalFollowingLabel){(status) in if status == true {self.updateScrollViewSize()}}
                    }
                }
            }
        //OPTION 2 - Load Kasam as Block (BASIC KASAMS)
        } else if kasam.metricType == "Checkmark" {
            kasamDB.child("Info").observeSingleEvent(of: .value, with: {(snapshot) in
                print("Step 3B - Get Block Data Option 2 \(kasam.kasamName)")
                if let snapshot = snapshot.value as? Dictionary<String,Any> {
                    self.saveKasamBlocks(value: snapshot, dayOrder: SavedData.kasamDict[kasam.kasamID]!.currentDay, kasam: kasam, type: self.type, kasamCount: self.personalKasamCount, followingLabel: self.personalFollowingLabel){(status) in if status == true {self.updateScrollViewSize()}}
                }
            })
        //OPTION 3 - Load single repeated block (CHALLENGE KASAMS) e.g. 200 Push-ups
        } else {
            kasamDB.child("Blocks").observeSingleEvent(of: .childAdded, with: {(snapshot) in
                print("Step 3B - Get Block Data Option 3 \(kasam.kasamName)")
                self.saveKasamBlocks(value: snapshot.value as? Dictionary<String,Any>, dayOrder: SavedData.kasamDict[kasam.kasamID]!.currentDay, kasam: kasam, type: self.type, kasamCount: self.personalKasamCount, followingLabel: self.personalFollowingLabel){(status) in if status == true {self.updateScrollViewSize()}}
            })
        }
    }
    
    //STEP 4
    func saveKasamBlocks(value: Dictionary<String,Any>?, dayOrder: Int, kasam: KasamSavedFormat, type: String, kasamCount: Int, followingLabel: UILabel, completion: @escaping (Bool) -> ()){
        print("Step 4 - Save Kasam Blocks \((kasam.kasamName))")
        var block: TodayBlockFormat!
        if value != nil {
            //Kasam block to complete today
            SavedData.kasamDict[kasam.kasamID]?.image = value!["Image"] as! String
            block = TodayBlockFormat(kasamID: kasam.kasamID, groupID: nil, blockID: value!["BlockID"] as? String ?? "", blockTitle: value!["Title"] as! String, dayOrder: dayOrder, duration: value!["Duration"] as? String, image: URL(string: SavedData.kasamDict[kasam.kasamID]!.image))
        } else {
            //Rest Day or Upcoming Kasam
            block = TodayBlockFormat(kasamID: kasam.kasamID, groupID: nil, blockID: "Rest", blockTitle: "Rest Day", dayOrder: dayOrder, duration: nil, image: nil)
        }
        //Modifying details of a current kasam
        if let kasamOrder = SavedData.todayKasamBlocks[type]?.index(where: {($0.kasamID == kasam.kasamID)}) {
            if kasam.joinedDate.daysBetween(endDate: Date()) < 0 {
                SavedData.todayKasamBlocks[type]?.remove(at: kasamOrder)
                SavedData.upcomingKasamBlocks[type]?.append((kasam.kasamID, block))
                getDayTracker(kasamID: kasam.kasamID, type: type)
            } else {
                SavedData.todayKasamBlocks[type]?[kasamOrder] = (kasam.kasamID, block)
                if let cell = personalKasamTable.cellForRow(at: IndexPath(item: kasamOrder, section: 0)) as? TodayBlockCell {
                    if cell.state == "restart" {
                        getDayTracker(kasamID: kasam.kasamID, type: type)
                    } else {
                        print("Followed new kasam \(String(describing: SavedData.todayKasamBlocks[type]?[kasamOrder].data.blockTitle))")
                        cell.blockSubtitle.text = SavedData.todayKasamBlocks[type]?[kasamOrder].data.blockTitle
                    }
                }
            }
        //Modifying details of an upcoming kasam
        } else if let kasamOrder = SavedData.upcomingKasamBlocks[type]?.index(where: {($0.kasamID == kasam.kasamID)}) {
            if kasam.joinedDate.daysBetween(endDate: Date()) < 0 {
                SavedData.upcomingKasamBlocks[type]?.remove(at: kasamOrder)
                SavedData.upcomingKasamBlocks[type]?.append((kasam.kasamID, block))
                getDayTracker(kasamID: kasam.kasamID, type: type)
            } else {
                SavedData.upcomingKasamBlocks[type]?.remove(at: kasamOrder)
                SavedData.todayKasamBlocks[type]?.append((kasam.kasamID, block))
                getDayTracker(kasamID: kasam.kasamID, type: type)
            }
        //Adding a kasam for the first time to the Today page
        } else {
            if kasam.joinedDate.daysBetween(endDate: Date()) < 0 {
                SavedData.upcomingKasamBlocks[type]?.append((kasam.kasamID, block))
            } else {
                SavedData.todayKasamBlocks[type]?.append((kasam.kasamID, block))
            }
            getDayTracker(kasamID: kasam.kasamID, type: type)
        }
        
        if kasamCount == (SavedData.todayKasamBlocks[type]?.count ?? 0) + (SavedData.upcomingKasamBlocks[type]?.count ?? 0) {
            followingLabel.text = "You have \(SavedData.todayKasamBlocks[type]!.count.pluralUnit(unit: "kasam")) to complete"
            personalKasamTable.reloadData()
            completion(true)
        }
    }
    
    func getDayTracker(kasamID: String, type: String) {
        print("Step 5 - Get day tracker \(String(describing: SavedData.kasamDict[kasamID]?.kasamName))")
        //For the active Kasams on the Personal or Group page
        if let kasam = SavedData.kasamDict[kasamID] {
            var db = DBRef.userPersonalHistory.child(kasam.kasamID).child(kasam.joinedDate.dateToString())
            if type == "group" {db = DBRef.userKasams.child((kasam.groupID)!).child("History").child(Auth.auth().currentUser!.uid)}
            //Gets the DayTracker info - only goes into this loop if the user has kasam history
            db.observe(.value, with: {(snap) in
                if snap.exists() {
                    var displayStatus = "NotStarted"
                    var order = 0
                    var dayTrackerArrayInternal = [Int:(Date,Double)]()
                    var dayPercent = 1.0
                    var percentComplete = 0.0
                    var internalCount = 0
                    var blockDeets: (blockID: String, blockName: String)? = nil
                    var reset = false
                    
                    for history in snap.children.allObjects as! [DataSnapshot] {
                        internalCount += 1
                        if history.key != "Goal" {          //last entry in Firebase that indicates the duration of the kasam
                            let kasamDate = history.key.stringToDate()
                            order = (Calendar.current.dateComponents([.day], from: kasam.joinedDate, to: kasamDate)).day! + 1
                            dayPercent = self.statusPercentCalc(snapshot: history).0
                            dayTrackerArrayInternal[order] = (kasamDate, dayPercent)
                            
                            //Status for Current day
                            if history.key == self.getCurrentDate() {
                                percentComplete = dayPercent
                                if dayPercent == 1 {displayStatus = "Check"}
                                else if dayPercent < 1 && dayPercent > 0 {displayStatus = "Progress"}
                                //Manually set the block title and ID if the user changed it manually
                                if kasam.programDuration != nil {
                                    if let value = history.value as? [String:Any] {
                                        blockDeets = (blockID: value["BlockID"] as? String ?? "", blockName: value["Block Name"] as! String); reset = true
                                    }
                                }
                            }
                        }
                        if internalCount == snap.childrenCount {
                            //DayTrackerArrayInternal adds the status of each day
                            kasam.displayStatus = displayStatus
                            kasam.percentComplete = percentComplete         //only for COMPLEX kasams
                            kasam.dayTrackerArray = dayTrackerArrayInternal
                            
                            if let index = SavedData.todayKasamBlocks[type]?.index(where: {($0.kasamID == kasam.kasamID)}) {
                                if blockDeets != nil {SavedData.todayKasamBlocks[type]?[index].data.blockTitle = blockDeets!.blockName; SavedData.todayKasamBlocks[type]?[index].data.blockID = blockDeets!.blockID}
                                kasam.streakInfo = self.currentStreak(dictionary: dayTrackerArrayInternal, currentDay: SavedData.todayKasamBlocks[type]?[index].data.dayOrder ?? 0)
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "RefreshKasamHolderBadge"), object: self)
                                self.singleKasamUpdate(row:index, section: 0, reset: reset)
                            }
                        }
                    }
                //No kasam history
                } else {
                    var level = 0
                    kasam.dayTrackerArray = nil
                    if kasam.joinedDate.daysBetween(endDate: Date()) < 0 {
                        kasam.displayStatus = "Upcoming"
                        level = 1
                        if let index = SavedData.upcomingKasamBlocks[type]?.index(where: {($0.kasamID == kasam.kasamID)}) {
                            self.singleKasamUpdate(row:index, section: level, reset: false)
                        }
                    } else {
                        kasam.displayStatus = "NotStarted"
                        kasam.streakInfo = (currentStreak:(value:0, date:nil), daysWithAnyProgress:0, longestStreak:0)
                        kasam.percentComplete = 0
                        if let index = SavedData.todayKasamBlocks[type]?.index(where: {($0.kasamID == kasam.kasamID)}) {
                            self.singleKasamUpdate(row:index, section: level, reset: false)
                        }
                    }
                }
            })
        }
    }
    
    func singleKasamUpdate(row: Int, section: Int, reset: Bool) {
        DispatchQueue.main.async {
            if let cell = self.personalKasamTable.cellForRow(at: IndexPath(item: row, section: section)) as? TodayBlockCell {
                print("Step 5B - Single Kasam Update")
                self.personalKasamTable.beginUpdates()
                if reset == true {cell.resetBlockName()}
                cell.statusUpdate(day:nil)
                cell.updateDayTrackerCollection()
                self.personalKasamTable.endUpdates()
            }
        }
    }
    
    //STEP 6
    func currentStreak(dictionary: [Int:(Date, Double)], currentDay: Int) -> (currentStreak:(value:Int, date:Date?), daysWithAnyProgress:Int, longestStreak:Int) {
        print("Step 6 - Streak Calc")
        var daysWithAnyProgress = 0
        var currentStreak = 0
        var currentStreakDate: Date?
        var anyProgressCheck = 0
        var longestStreak = 0
        var streak = [0]
        var streakEndDate = [0]
        for day in stride(from: currentDay, through: 1, by: -1) {
            if dictionary[day] != nil {
                streak[streak.count - 1] += 1
                if dictionary[day]!.1 >= 0.0 {
                    daysWithAnyProgress += 1                                        //all days with some progress
                    if streakEndDate.count != streak.count {streakEndDate[streakEndDate.count - 1] = day}
                } else {
                    currentStreak = daysWithAnyProgress                             //current streak days with some progress
                }
            } else if day != currentDay {
                streak += [0]
                streakEndDate += [0]
                if anyProgressCheck == 0 {
                    currentStreak = daysWithAnyProgress                             //current streak days with some progress
                }
                anyProgressCheck = 1
            }
        }
        longestStreak = streak.max() ?? 0
        daysWithAnyProgress = streak.reduce(0, +)
        if anyProgressCheck == 0 {                                                  //in case all days have some progress
            currentStreak = daysWithAnyProgress
        }
        currentStreakDate = dictionary[30]?.0
        return ((currentStreak,currentStreakDate), daysWithAnyProgress, longestStreak)
    }
    
    func statusPercentCalc (snapshot: DataSnapshot) -> (percent: Double, displayStatus: String){
        var percent = 0.0
        var displayStatus = "NotStarted"
        //COMPLEX KASAM
        if let dictionary = snapshot.value as? Dictionary<String,Any> {
            if dictionary["Block Name"] as? String ?? "" == "Rest Day" {
                percent = -1.0
                displayStatus = "Rest Day"
            } else {
                percent = dictionary["Metric Percent"] as? Double ?? 0.0
                if percent < 1 {
                    displayStatus = "Progress"
                    Analytics.logEvent("working_Kasam", parameters: ["metric_percent": percent.rounded(toPlaces: 2) ])
                } else {
                    displayStatus = "Check"
                }
            }
        //SIMPLE KASAM
        } else if snapshot.value as? Int == 1 {
            displayStatus = "Check"
            percent = 1.0
            Analytics.logEvent("completed_Kasam", parameters: nil)
        } else if snapshot.value as? Int == 0 {
            percent = 0.0
            displayStatus = "NotStarted"
        }
        return (percent, displayStatus)
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
        goToCreateNewKasam()
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
            kasamTransferHolder.userKasam = userKasam
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
        if indexPath.section == 0 {
            cell.setBlock(block: SavedData.todayKasamBlocks[type]![indexPath.row].data, row: indexPath.row, section: indexPath.section, type: type)
        }
        else {
            cell.setBlock(block: SavedData.upcomingKasamBlocks[type]![indexPath.row].data, row: indexPath.row, section: indexPath.section, type: type)
        }
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
            if section == 0 {
                kasamIDforHolder = SavedData.todayKasamBlocks[type]![kasamOrder].1.kasamID
                userKasam = SavedData.kasamDict[kasamIDforHolder]?.userKasam ?? false
            } else {
                kasamIDforHolder = SavedData.upcomingKasamBlocks[type]![kasamOrder].1.kasamID
            }
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
