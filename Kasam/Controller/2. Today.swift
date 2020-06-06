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
import SkeletonView
import Lottie

class TodayBlocksViewController: UIViewController, UIGestureRecognizerDelegate, CollectionCellDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var todayMotivationCollectionView: UICollectionView!
    @IBOutlet weak var todaySublabel: UILabel!
    @IBOutlet weak var todayCollectionHeight: NSLayoutConstraint!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var challengesTitle: UILabel!
    @IBOutlet weak var challengesColletionView: UICollectionView!
    @IBOutlet weak var challengesCollectionHeight: NSLayoutConstraint!
    @IBOutlet weak var contentView: NSLayoutConstraint!
    
    var motivationArray: [motivationFormat] = []
    var motivationBackground: [String] = []
    
    var blockURLGlobal = ""
    var dateSelected = ""
    var kasamIDforViewer = ""
    var kasamIDforHolder = ""
    var blockIDGlobal = ""
    var dayToLoadGlobal = 0
    var dayOrderGlobal = 0
    var viewOnlyGlobal = false
    var setupCheck = 0
    
    //Get Preferences Variables
    var kasamOrder = 0
    var count = 0
    var challengeOrder = 0
    var challengeCellWidth = CGFloat(0.0)
    
    var kasamFollowingRefHandle: DatabaseHandle!
    var motivationRefHandle: DatabaseHandle!
    var dayTrackerRefHandle: DatabaseHandle!
    var noKasamTracker = 0
    let animationView = AnimationView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()                   //global function
        getKasamFollowing(nil)
        getMotivationBackgrounds()
        setupNotifications()
        printLocalNotifications()
    }
    
    //Center the day Tracker to today
    override func viewDidLayoutSubviews() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "CenterCollectionView"), object: self)
    }
    
    //Starts the Animation badge playing when the view disppears and reappears
    override func viewDidAppear(_ animated: Bool) {
        for block in 0...SavedData.kasamBlocks.count {
            if let cell = self.tableView.cellForRow(at: IndexPath(item: block, section: 0)) as? TodayBlockCell {
                cell.completionBadge.play()
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        DBRef.motivationImages.removeObserver(withHandle: motivationRefHandle)
    }
    
    func setupNotifications(){
        let stopLoadingAnimation = NSNotification.Name("RemoveLoadingAnimation")
        NotificationCenter.default.addObserver(self, selector: #selector(TodayBlocksViewController.stopLoadingAnimation), name: stopLoadingAnimation, object: nil)
        
        let restTodayKasam = NSNotification.Name("ResetTodayKasam")
        NotificationCenter.default.addObserver(self, selector: #selector(TodayBlocksViewController.getKasamFollowing), name: restTodayKasam, object: nil)
        
        let updateKasamStatus = NSNotification.Name("UpdateTodayBlockStatus")
        NotificationCenter.default.addObserver(self, selector: #selector(TodayBlocksViewController.updateKasamStatus), name: updateKasamStatus, object: nil)
        
        let addKasamToday = NSNotification.Name("AddKasamToday")
        NotificationCenter.default.addObserver(self, selector: #selector(TodayBlocksViewController.addKasamToToday), name: addKasamToday, object: nil)
        
        let unfollowTodayKasam = NSNotification.Name("UnfollowTodayKasam")
        NotificationCenter.default.addObserver(self, selector: #selector(TodayBlocksViewController.removeTodayKasam), name: unfollowTodayKasam, object: nil)

        let editMotivation = NSNotification.Name("EditMotivation")
        NotificationCenter.default.addObserver(self, selector: #selector(TodayBlocksViewController.editMotivation), name: editMotivation, object: nil)
        
        let resetTodayChallenges = NSNotification.Name("ResetTodayChallenges")
        NotificationCenter.default.addObserver(self, selector: #selector(TodayBlocksViewController.resetTodayChallenges), name: resetTodayChallenges, object: nil)
    }
    
    func printLocalNotifications(){
        let center = UNUserNotificationCenter.current()
//        center.removeAllDeliveredNotifications() // To remove all delivered notifications
//        center.removeAllPendingNotificationRequests()
        center.getPendingNotificationRequests { (notifications) in
            print("Count: \(notifications.count)")
            for item in notifications {
                print(item.content.title, item.content.body, item.content)
            }
        }
    }
    
    //Table Resizing----------------------------------------------------------------------------------------
    
    func updateContentTableHeight(){
        //set the table row height, based on the screen size
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = ((view.frame.width - 30) / (2.7)) + 25
        
        //sets the height of the whole tableview, based on the numnber of rows
        var tableFrame = tableView.frame
        tableFrame.size.height = tableView.contentSize.height
        tableView.frame = tableFrame
        self.tableViewHeight.constant = self.tableView.contentSize.height
        
        //elongates the entire scrollview, based on the tableview height
        let frame = self.view.safeAreaLayoutGuide.layoutFrame
        challengeCellWidth = ((frame.size.width - CGFloat(30)) * 0.6)             //CHANGE THIS VALUE FOR COLLECTIONVIEWCELL WIDTH
        challengesCollectionHeight.constant = (challengeCellWidth * 1.3)
        
        let contentViewHeight = 105.5 + tableViewHeight.constant + 50 + challengesCollectionHeight.constant
        if contentViewHeight > frame.height {
            contentView.constant = contentViewHeight
        } else if contentViewHeight <= frame.height {
            let diff = frame.height - contentViewHeight
            contentView.constant = contentViewHeight + diff + 1
        }
    }
    
    //-------------------------------------------------------------------------------------------------------

    deinit {
        print("\(#function)")
    }
    
    @objc func stopLoadingAnimation(){
        animationView.removeFromSuperview()
    }
    
    @objc func addKasamToToday(_ notification: NSNotification?){
        if let kasamID = notification?.userInfo?["kasamID"] as? String {
            DBRef.userKasamFollowing.child(kasamID).observe(.value) {(snapshot) in
                self.getPreferences(snapshot: snapshot, kasamID: kasamID, new: true)
            }
        }
    }
    
    //STEP 1
    @objc func getKasamFollowing(_ notification: NSNotification?){
        setupCheck = 0
        print("step 1 hell6 inside get following")
        kasamOrder = 0
        challengeOrder = 0
        noKasamTracker = 0
        let kasamID = notification?.userInfo?["kasamID"] as? String
        if kasamID != nil {
            //OPTION 1 - Loading details of specific kasam
            DBRef.userKasamFollowing.child(kasamID!).observe(.value) {(snapshot) in
                self.count = 1
                self.getPreferences(snapshot: snapshot, kasamID: kasamID, new: false)
            }
        } else {
            //OPTION 2 - Loading details of all kasams the user is following
            SavedData.challengeBlocks.removeAll()
            SavedData.kasamBlocks.removeAll()
            SavedData.todayKasamList.removeAll()
            DBRef.userKasamFollowing.observeSingleEvent(of: .value, with:{(snap) in
                self.count = Int(snap.childrenCount)                 //counts number of Kasams that the user is following
                if self.count == 0 {
                    //not following any kasams
                    self.noKasamTracker = 1
                    self.tableView.reloadData()
                    self.tableView.hideSkeleton(transition: .crossDissolve(0.25))
                }
                self.kasamFollowingRefHandle = DBRef.userKasamFollowing.observe(.childAdded) {(snapshot) in
                    self.getPreferences(snapshot: snapshot, kasamID: nil, new: false)
                }
            })
        }
    }
    
    //STEP 2
    func getPreferences(snapshot: DataSnapshot, kasamID: String?, new: Bool){
        print("step 2 hell6 inside get preferences")
        //Get Kasams from user following + their preference for each kasam
        if let value = snapshot.value as? [String: Any] {
            let currentStatus = value["Status"] as? String ?? "active"
            let repeatDuration = value["Repeat"] as? Int ?? 1
    
            var order = 0
            if kasamID != nil && new == false {order = SavedData.kasamDict[kasamID!]!.kasamOrder}
            else if kasamID != nil && new == true {
                if repeatDuration > 0 {order = SavedData.kasamBlocks.count}
                else if repeatDuration == 0 {order = SavedData.challengeBlocks.count}
            }
            else {
                if repeatDuration > 0 {order = kasamOrder}
                else if repeatDuration == 0 {order = challengeOrder}
            }
            
            let preference = KasamSavedFormat(kasamID: snapshot.key, kasamName: value["Kasam Name"] as? String ?? "", joinedDate: self.stringToDate(date: value["Date Joined"] as? String ?? ""), startTime: value["Time"] as? String ?? "", currentDay: 1, repeatDuration: repeatDuration, kasamOrder: order, image: nil, metricType: value["Metric"] as? String ?? "Checkmark", timelineDuration: value["Duration"] as? Int, currentStatus: currentStatus, pastKasamJoinDates: value["Past Join Dates"] as? [String:Int], sequence: "days", streakInfo: (0,0,0,0,0), displayStatus: "Checkmark", percentComplete: 0.0, badgeThresholds: ["10","30","90"], badgeList: value["Badges"] as? [String: Int], dayTrackerArray: nil)
            if currentStatus == "active" {
                if repeatDuration > 0 {kasamOrder += 1}
                else if repeatDuration == 0 {challengeOrder += 1}
                SavedData.todayKasamList.append(preference.kasamID)
            } else {
                count -= 1
            }
            SavedData.addKasam(kasam: preference)                   //adds all kasams that the user is following
            if SavedData.todayKasamList.count == count {
                self.retrieveKasams(kasamID: nil)
                if challengeOrder == 0 {self.challengesTitle.isHidden = true}
                else {self.challengesTitle.isHidden = false}
                //update the user profile page
                NotificationCenter.default.post(name: Notification.Name(rawValue: "KasamStatsUpdate"), object: self)
                DBRef.userKasamFollowing.removeObserver(withHandle: self.kasamFollowingRefHandle)
                DispatchQueue.main.async {self.badgeThresholds()}
            } else if kasamID != nil && new == false {
                self.retrieveKasams(kasamID: kasamID)
            } else if kasamID != nil && new == true {
                self.retrieveKasams(kasamID: kasamID)
                if challengeOrder == 0 {self.challengesTitle.isHidden = true}
                else {self.challengesTitle.isHidden = false}
                //update the user profile page
                NotificationCenter.default.post(name: Notification.Name(rawValue: "KasamStatsUpdate"), object: self)
            }
        }
    }
    
    //STEP 3
    @objc func retrieveKasams(kasamID: String?) {
        print("step 3 hell6 inside get kasams")
        var todayKasamCount = 0
        if SavedData.todayKasamList.count == 0 {                   //user is following Kasams that aren't active yet
            self.noKasamTracker = 1
            self.tableView.reloadData()
            self.tableView.hideSkeleton(transition: .crossDissolve(0.25))
        }
        var kasamArray = SavedData.todayKasamList
        if let index = SavedData.todayKasamList.index(where: {($0 == kasamID)}) {
            //Updating existing kasam on the today page
            kasamArray = [SavedData.todayKasamList[index]]
            if let blockIndex = SavedData.kasamBlocks.index(where: {($0.kasamID == kasamID)}){
                SavedData.kasamBlocks.remove(at: blockIndex)
            } else if let blockIndex = SavedData.challengeBlocks.index(where: {($0.kasamID == kasamID)}){
                SavedData.challengeBlocks.remove(at: blockIndex)
            }
        } else {
            //Updating all kasams on the today page
            SavedData.kasamBlocks.removeAll()
            SavedData.challengeBlocks.removeAll()
        }
        
        //STEP 3 - Finds out which block should be called based on the day of the kasam the user is on
        for kasamIDBlock in kasamArray {
            let kasam = SavedData.kasamDict[kasamIDBlock]!
            var dayOrder = 0
            //Seeing which blocks are needed for the day
            if kasam.currentStatus == "inactive" || kasam.currentStatus == "completed" {
                todayKasamCount += 1
            } else if kasam.currentStatus == "active" {
                dayOrder = ((Calendar.current.dateComponents([.day], from: kasam.joinedDate, to: Date()).day!) + 1)
                SavedData.kasamDict[kasam.kasamID]?.currentDay = dayOrder
                
                //OPTION 1 - Load blocks based on last completed (TIMELINE KASAMS)
                if kasam.timelineDuration != nil {
                    var dayCount = 1
                    for date in Date.dates(from: kasam.joinedDate, to: Date()) {
                        let dateString = dateFormat(date: date)
                        DBRef.userHistory.child(kasam.kasamID).child(dateString).observeSingleEvent(of: .value) {(snapCount) in
                            if dateString != Dates.getCurrentDate() && snapCount.exists() {
                                dayCount += 1               //the user has completed xx number of blocks in the past (excludes today's block)
                            } else if dateString == Dates.getCurrentDate() {
                                DBRef.coachKasams.child(kasam.kasamID).child("Blocks").queryOrdered(byChild: "Order").queryEqual(toValue : "\(dayCount)").observeSingleEvent(of: .childAdded, with: {(snapshot) in
                                    todayKasamCount += 1
                                    self.saveKasamBlocks(value: snapshot.value as! Dictionary<String,Any>, todayKasamCount: todayKasamCount, dayOrder: dayOrder, kasam: kasam, repeatMultiple: kasam.repeatDuration > 1, specificKasam: kasamID, dayCount: dayCount)
                                })
                            }
                        }
                    }
                } else
                //OPTION 2 - Load Kasam as Block (BASIC KASAMS)
                if kasam.metricType == "Checkmark" {
                    DBRef.coachKasams.child(kasam.kasamID).observe(.value) {(snapshot) in
                        todayKasamCount += 1
                        self.saveKasamBlocks(value: snapshot.value as! Dictionary<String,Any>, todayKasamCount: todayKasamCount, dayOrder: dayOrder, kasam: kasam, repeatMultiple: kasam.repeatDuration > 1, specificKasam: kasamID, dayCount: nil)
                    }
                } else {
                //OPTION 3 - Load blocks based on day number (CHALLENGE KASAMS)
                    DBRef.coachKasams.child(kasam.kasamID).child("Blocks").observeSingleEvent(of: .value, with: {(blockCountSnapshot) in
                        let blockCount = Int(blockCountSnapshot.childrenCount)
                        var blockOrder = "1"
                        if dayOrder <= blockCount {blockOrder = String(dayOrder)}
                        else {blockOrder = String((blockCount / dayOrder) + 1)}
                        //Get block info for the Today Repeated Kasams
                        DBRef.coachKasams.child(kasam.kasamID).child("Blocks").queryOrdered(byChild: "Order").queryEqual(toValue : blockOrder).observeSingleEvent(of: .childAdded, with: {(snapshot) in
                            todayKasamCount += 1
                            self.saveKasamBlocks(value: snapshot.value as! Dictionary<String,Any>, todayKasamCount: todayKasamCount, dayOrder: dayOrder, kasam: kasam, repeatMultiple: kasam.repeatDuration > 1, specificKasam: kasamID, dayCount: nil)
                        })
                    })
                }
            }
        }
    }
    
    //STEP 4
    func saveKasamBlocks(value: Dictionary<String,Any>, todayKasamCount: Int, dayOrder: Int, kasam: KasamSavedFormat, repeatMultiple: Bool, specificKasam: String?, dayCount: Int?){
        print("step 4 hell6 save kasam Blocks")
        let block = TodayBlockFormat(kasamOrder: kasam.kasamOrder, kasamID: kasam.kasamID, blockID: value["BlockID"] as? String ?? "", blockTitle: value["Title"] as! String, dayOrder: dayOrder, duration: value["Duration"] as? String, image: URL(string: value["Image"] as! String) ?? URL(string:PlaceHolders.kasamLoadingImageURL)!, dayCount: dayCount)
        if repeatMultiple == true {
            SavedData.kasamBlocks.append(block)
            SavedData.kasamBlocks = SavedData.kasamBlocks.sorted(by: {$0.kasamOrder < $1.kasamOrder})
        } else {
            SavedData.challengeBlocks.append(block)
            SavedData.challengeBlocks = SavedData.challengeBlocks.sorted(by: {$0.kasamOrder < $1.kasamOrder})
        }
        if specificKasam != nil {
            self.getDayTracker(kasamID: specificKasam)
        } else {
            if todayKasamCount == SavedData.todayKasamList.count {
                //Only does the below after all Kasams loaded
                self.todaySublabel.text = "You have \(SavedData.kasamBlocks.count.pluralUnit(unit: "kasam")) to complete"
                self.tableView.reloadData()
                self.challengesColletionView.reloadData()
                self.updateContentTableHeight()
                self.getDayTracker(kasamID: nil)
            }
        }
        self.tableView.hideSkeleton(transition: .crossDissolve(0.25))
    }
    
    @objc func resetTodayChallenges(){
        self.challengesColletionView.reloadData()
    }
    
    //STEP 5
    func getDayTracker(kasamID: String?) {
        print("step 5 hell6 get day Tracker")
        //for the active Kasams on the Today page
        var count = 0
        var kasamArray = SavedData.todayKasamList
        //If specific Kasam
        if let index = SavedData.todayKasamList.index(where: {($0 == kasamID)}) {
            kasamArray = [SavedData.todayKasamList[index]]
        }
        for kasamIDBlock in kasamArray {
            let kasam = SavedData.kasamDict[kasamIDBlock]!
            var displayStatus = "Checkmark"
        //OPTION 1 - GET CHALLENGE PERCENT COMPLETE
            if kasam.repeatDuration == 0 {
                DBRef.userHistory.child(kasam.kasamID).child(Dates.getCurrentDate()).observeSingleEvent(of: .value, with: {(snap) in
                    if snap.exists(){
                        let statusPercent = self.statusPercentCalc(snapshot: snap)
                        SavedData.kasamDict[(kasam.kasamID)]?.percentComplete = statusPercent.0
                        SavedData.kasamDict[(kasam.kasamID)]?.displayStatus = statusPercent.1
                        count += 1
                        if let cell = self.challengesColletionView.cellForItem(at: IndexPath(item: kasam.kasamOrder, section: 0)) as? TodayChallengesCell {print("hell4 status update");cell.statusUpdate()}
                    } else {
                        if let cell = self.challengesColletionView.cellForItem(at: IndexPath(item: kasam.kasamOrder, section: 0)) as? TodayChallengesCell {print("hell4 status update");cell.statusUpdate()}
                    }
                })
        //OPTION 2 - GET REPEATED KASAM PERCENT COMPLETE AND DAYTRACKERS
            } else if kasam.repeatDuration > 0 {
                let kasamOrder = kasam.kasamOrder
                var dayCount = 0
                var percentComplete = 0.0
                var order = 0
                //Checks if there's kasam history
                DBRef.userHistory.child(kasam.kasamID).observeSingleEvent(of: .value, with: {(snap) in
                if snap.exists() {
                    dayCount = Int(snap.childrenCount)
                    var dayTrackerArrayInternal = [Int:(Date,Double)]()
                    var dayPercent = 1.0
                    //Gets the DayTracker info - only goes into this loop if the user has kasam history
                    self.dayTrackerRefHandle = DBRef.userHistory.child(kasam.kasamID).observe(.childAdded, with: {(snap) in
                        let kasamDate = self.stringToDate(date: snap.key)
                        if kasamDate >= kasam.joinedDate {
                            if SavedData.kasamDict[(kasam.kasamID)]?.timelineDuration == nil {
                                order = (Calendar.current.dateComponents([.day], from: kasam.joinedDate, to: kasamDate)).day! + 1
                            } else {
                                order += 1
                            }
                            dayPercent = self.statusPercentCalc(snapshot: snap).0
                            
                            //DayTrackerDateArray is correct
                            dayTrackerArrayInternal[order] = (kasamDate, dayPercent)  //places gold dots on right day in the todayBlockTracker
                        } else {
                            dayCount -= 1
                        }
                        //Status for Current day
                        if snap.key == Dates.getCurrentDate() {
                            percentComplete = dayPercent
                            if dayPercent == 1 {displayStatus = "Check"}
                            else if dayPercent < 1 && dayPercent > 0 {displayStatus = "Progress"}
                        }
                        //Daycount is the number of days the kasam has been active for the user
                        //DayTrackerArrayInternal adds the status of each day
                        if dayTrackerArrayInternal.count == dayCount && dayCount >= 0 && kasamOrder < SavedData.kasamBlocks.count {
                            SavedData.kasamDict[(kasam.kasamID)]?.displayStatus = displayStatus
                            //percent complete only captured for today to show for complex Kasams
                            SavedData.kasamDict[(kasam.kasamID)]?.percentComplete = percentComplete
                            SavedData.kasamDict[kasam.kasamID]?.dayTrackerArray = dayTrackerArrayInternal
                            
                            let streakInfo = self.currentStreak(dictionary: dayTrackerArrayInternal, currentDay: SavedData.kasamBlocks[kasamOrder].dayOrder)
                            SavedData.kasamDict[kasam.kasamID]?.streakInfo = streakInfo
                            DBRef.userHistory.child(kasam.kasamID).removeAllObservers()
                            count += 1
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "RefreshKasamHolderBadge"), object: self)
                            self.setupCheck = 1
                            if kasamID == nil {
                                //OPTION 1 - Updating all the kasams on the today page
                                self.allTodayKasamUpdate(kasamOrder: kasamOrder)
                            } else {
                                //OPTION 2 - Updating a single kasam after a preference change OR adding a new kasam
                                self.singleKasamUpdate(kasamOrder: kasamOrder)
                            }
                        }
                    })
                //No history recorded in Firebase
                } else {
                    if kasamID == nil {
                        //OPTION 1 - Updating all the kasams on the today page
                        self.allTodayKasamUpdate(kasamOrder: kasamOrder)
                    } else {
                        //OPTION 2 - Updating a single kasam after a preference change OR adding a new kasam
                        self.singleKasamUpdate(kasamOrder: kasamOrder)
                    }
                }
                })
            }
        }
    }
    
    func allTodayKasamUpdate(kasamOrder: Int) {
        self.tableView.reloadData()
        if let cell = self.tableView.cellForRow(at: IndexPath(item: kasamOrder, section: 0)) as? TodayBlockCell {
            self.tableView.beginUpdates()
            cell.statusUpdate()
            cell.updateDayTrackerCollection()
            cell.collectionCoverUpdate()
            self.tableView.endUpdates()
        }
    }
    
    func singleKasamUpdate(kasamOrder: Int) {
        self.tableView.reloadData()
        if let cell = self.tableView.cellForRow(at: IndexPath(item: kasamOrder, section: 0)) as? TodayBlockCell {
            self.tableView.beginUpdates()
            cell.setBlock(block: SavedData.kasamBlocks[kasamOrder])
            cell.statusUpdate()
            cell.centerCollectionView()
            cell.dayTrackerCollectionView.reloadData()
            self.updateContentTableHeight()
            self.tableView.endUpdates()
        }
    }
    
    //STEP 5B
    func currentStreak(dictionary: [Int:(Date, Double)], currentDay: Int) -> (Int, Int, Int, Int, Int) {
        var daysWithAnyProgress = 0
        var daysWithCompleteProgress = 0
        var currentStreak = 0
        var currentStreakCompleteProgress = 0
        var anyProgressCheck = 0
        var completeProgressCheck = 0
        var longestStreak = 0
        var longestStreakDay = 0
        var streak = [0]
        var streakEndDate = [0]
        for day in stride(from: currentDay, through: 1, by: -1) {
            if dictionary[day] != nil {
                streak[streak.count - 1] += 1
                if dictionary[day]!.1 == 1.0 {
                    daysWithCompleteProgress += 1                                   //all days with 100% progress
                    if streakEndDate.count != streak.count {streakEndDate[streakEndDate.count - 1] = day}
                } else if completeProgressCheck == 0 {
                    currentStreakCompleteProgress = daysWithCompleteProgress        //current streak days with 100% progress
                    completeProgressCheck = 1
                }
            } else if day != currentDay {
                streak += [0]
                streakEndDate += [0]
                if anyProgressCheck == 0 {
                    currentStreakCompleteProgress = daysWithCompleteProgress        //current streak days with 100% progress
                }
                anyProgressCheck = 1
            }
        }
        longestStreak = streak.max() ?? 0
        if let index = streak.index(of: longestStreak) {
            longestStreakDay = streakEndDate[index]
        }
        daysWithAnyProgress = streak.reduce(0, +)
        if anyProgressCheck == 0 {                                                  //in case all days have some progress
            currentStreak = daysWithAnyProgress
            if currentStreakCompleteProgress == 0 {
                currentStreakCompleteProgress = daysWithCompleteProgress
            }
        }
        return (currentStreak, currentStreakCompleteProgress, daysWithAnyProgress, longestStreak, longestStreakDay)
    }
    
    @objc func removeTodayKasam(_ notification: NSNotification){
//        print("hell6 inside remove today kasam")
//        let kasamID = notification.userInfo?["kasamID"] as? String
//        //STEP 1 - Remove kasam from tableview on Today page
//        self.tableView.deleteRows(at: [IndexPath(item: SavedData.kasamDict[kasamID!]!.kasamOrder, section: 0)], with: .automatic)
//        //STEP 2 - Remove kasam from Today array
//        if let index = SavedData.kasamTodayArray.index(where: {($0.kasamID == kasamID)}) {
//            SavedData.kasamTodayArray.remove(at: index)
//        }
//        if let index = SavedData.kasamBlocks.index(where: {($0.kasamID == kasamID)}) {
//            SavedData.kasamBlocks.remove(at: index)
//        }
//        self.tableView.reloadData()
    }
    
    //---------------------------------------------------------------------------------------------------------
    
    //FOR BASIC KASAM UPDATE
    func updateKasamDayButtonPressed(kasamOrder: Int, day: Int, challenge:Bool){
        let block: TodayBlockFormat?
        if challenge == true {block = SavedData.challengeBlocks[kasamOrder]}
        else {block = SavedData.kasamBlocks[kasamOrder]}
        
        //STEP 2 - STATUS UPDATE
        var status = "Checkmark"
        let statusDate = dateFormat(date: Calendar.current.date(byAdding: .day, value: day - block!.dayOrder, to: Date())!)
        if challenge == true {
            if SavedData.kasamDict[block!.kasamID]?.percentComplete == 1.0 {
                DBRef.userHistory.child(block!.kasamID).child(statusDate).setValue(nil)
            } else {
                DBRef.userHistory.child(block!.kasamID).child(statusDate).setValue(1); status = "Check"
            }
        } else {
            if SavedData.kasamDict[block!.kasamID]?.dayTrackerArray?[day] != nil {
                if SavedData.kasamDict[block!.kasamID]?.dayTrackerArray?[day]?.1 == 1.0 {
                    DBRef.userHistory.child(block!.kasamID).child(statusDate).setValue(nil)
                }
            } else {
                DBRef.userHistory.child(block!.kasamID).child(statusDate).setValue(1); status = "Check"
            }
        }
        //If the status of today is changed, update the display status
        if day == Int(block!.dayOrder) {SavedData.kasamDict[block!.kasamID]?.displayStatus = status}
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "KasamStatsUpdate"), object: self)        //Detailed Stats Update
        NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateTodayBlockStatus"), object: self, userInfo: ["kasamID": block!.kasamID, "date": statusDate])        //Execute below function
    }
    
    //FOR CHALLENGE KASAM UPDATE
    @objc func updateKasamStatus(_ notification: NSNotification) {
        if let kasamID = notification.userInfo?["kasamID"] as? String {
            let kasamOrder = (SavedData.kasamDict[kasamID]!.kasamOrder)
            var statusDate = Dates.getCurrentDate()
            if notification.userInfo?["date"] != nil {statusDate = notification.userInfo?["date"] as! String}
            DBRef.userHistory.child(kasamID).child(statusDate).observe(.value, with: {(snapshot) in
                if SavedData.kasamDict[kasamID]!.repeatDuration > 1 {
                    //OPTION 1 - FOR UPDATING REPEATED KASAM
                    let kasamDate = self.stringToDate(date: snapshot.key)
                    var dayOrder = 0
                    if SavedData.kasamDict[kasamID]?.timelineDuration != nil {
                        dayOrder = notification.userInfo?["day"] as? Int ?? 0
                    } else {
                        dayOrder = (Calendar.current.dateComponents([.day], from: SavedData.kasamDict[kasamID]!.joinedDate, to: kasamDate)).day! + 1
                    }
                    
                    //STEP 1 - Updates the DayTracker
                    var statusPercent: (Double, String)?
                    if snapshot.exists() {
                        statusPercent = self.statusPercentCalc(snapshot: snapshot)
                        SavedData.kasamDict[kasamID]?.dayTrackerArray?[dayOrder] = (kasamDate, statusPercent!.0)
                        if statusPercent?.0 == 0.0 {statusPercent?.1 = "Checkmark"}
                    } else {
                        //Removes the dayTracker for today if kasam is set to zero
                        statusPercent = (0.0, "Checkmark")
                        if let index = SavedData.kasamDict[kasamID]?.dayTrackerArray?.firstIndex(where: {$0.0 == dayOrder}) {
                            SavedData.kasamDict[kasamID]?.dayTrackerArray?.remove(at: index)
                        }
                    }
                    
                    //STEP 2 - Update today's percentage if today's activity being updated
                    if statusDate == Dates.getCurrentDate() {
                        SavedData.kasamDict[(kasamID)]?.percentComplete = statusPercent!.0
                        SavedData.kasamDict[(kasamID)]?.displayStatus = statusPercent!.1
                    }
                    
                    //STEP 3 - Get the current streak based on the updated daytracker
                    if SavedData.kasamDict[kasamID]?.dayTrackerArray != nil {
                        let streak = self.currentStreak(dictionary: (SavedData.kasamDict[kasamID]?.dayTrackerArray!)!, currentDay: SavedData.kasamBlocks[kasamOrder].dayOrder)
                        SavedData.kasamDict[kasamID]!.streakInfo = streak
                    }
                    
                    if let cell = self.tableView.cellForRow(at: IndexPath(item: kasamOrder, section: 0)) as? TodayBlockCell {
                        self.tableView.beginUpdates()
                        cell.statusUpdate()
                        cell.dayTrackerCollectionView.reloadData()
                        self.tableView.endUpdates()
                    }
                } else {
                    //OPTION 2 - FOR UPDATING CHALLENGE KASAMS
                    let statusPercent = self.statusPercentCalc(snapshot: snapshot)
                    SavedData.kasamDict[(kasamID)]?.percentComplete = statusPercent.0
                    SavedData.kasamDict[(kasamID)]?.displayStatus = statusPercent.1
                    if let cell = self.challengesColletionView.cellForItem(at: IndexPath(item: kasamOrder, section: 0)) as? TodayChallengesCell {
                        self.challengesColletionView.performBatchUpdates({cell.statusUpdate()}, completion: nil)
                    }
                }
                DBRef.userHistory.child(kasamID).child(statusDate).removeAllObservers()
            })
        }
    }
    
    func statusPercentCalc (snapshot: DataSnapshot) -> (Double, String){
        var percent = 0.0
        var displayStatus = "Checkmark"
        if let dictionary = snapshot.value as? Dictionary<String,Any> {
            percent = dictionary["Metric Percent"] as? Double ?? 0.0
            if percent < 1 {
                displayStatus = "Progress"
                Analytics.logEvent("working_Kasam", parameters: ["metric_percent": percent.rounded(toPlaces: 2) ])
            } else {
                displayStatus = "Check"
            }
        } else if snapshot.value as? Int == 1 {
            displayStatus = "Check"
            percent = 1.0
            Analytics.logEvent("completed_Kasam", parameters: nil)
        } else if snapshot.value as? Int == 0 {
            percent = 0.0
            displayStatus = "Checkmark"
        }
        return (percent, displayStatus)
    }
    
    func stopObserving(ref: AnyObject?, handle: DatabaseHandle?) {
        guard ref != nil else {
            return
        }
        ref?.removeObserver(withHandle: handle!)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    //PART 1
    func badgeThresholds(){
        SavedData.badgesCount = 0
        for kasam in SavedData.kasamDict {
            //STEP 1 - GET THE BADGE THRESHOLDS
            DBRef.coachKasams.child(kasam.value.kasamID).child("Badges").observeSingleEvent(of: .value) {(snap) in
                if snap.exists() {
                    SavedData.kasamDict[kasam.value.kasamID]?.badgeThresholds = (snap.value as! String).components(separatedBy: ";")
                }
                self.badgesAchieved(kasam:kasam)
            }
        }
    }
    
    //PART 2
    func badgesAchieved(kasam: Dictionary<String, KasamSavedFormat>.Element) {
        //STEP 2 - GET THE BADGES
        SavedData.badgesCount += kasam.value.badgeList?.count ?? 0
        if kasam.value.badgeList != nil {
            for badge in kasam.value.badgeList! {
                if let level = (kasam.value.badgeThresholds).index(of: String(badge.value)) {
                    if SavedData.badgesAchieved[kasam.value.kasamName] == nil {
                        SavedData.badgesAchieved[kasam.value.kasamName] = [((badge.key, badge.value, level))]
                    } else {
                        SavedData.badgesAchieved[kasam.value.kasamName]!.append((badge.key, badge.value, level))
                    }
                }
            }
            SavedData.badgesCount = (SavedData.badgesAchieved.values.map { $0.count }).reduce(0, { $0 + $1 })
            SavedData.badgeSubCatCount = SavedData.badgesCount + SavedData.badgesAchieved.count
        }
    }
    
//MOTIVATIONS----------------------------------------------------------------------------------------
    
    func getMotivations(){
        motivationArray.removeAll()
        let motivationRef = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Motivation")
        var motivationRefHandle: DatabaseHandle!
        motivationRef.observeSingleEvent(of: .value, with:{(snap) in
            let count = Int(snap.childrenCount)
            if count == 0 {
                self.motivationArray.append(motivationFormat(motivationID: "", motivationText: "Enter your personal motivation here!"))
                self.todayMotivationCollectionView.reloadData()
                self.todayMotivationCollectionView.hideSkeleton(transition: .crossDissolve(0.25))
            } else {
                motivationRefHandle = motivationRef.observe(.childAdded) {(snapshot) in
                    let motivation = motivationFormat(motivationID: snapshot.key, motivationText: snapshot.value as! String)
                    self.motivationArray.append(motivation)
                    if self.motivationArray.count == count {
                        self.motivationArray.append(motivationFormat(motivationID: "", motivationText: "Enter your personal motivation here!"))
                        motivationRef.removeObserver(withHandle: motivationRefHandle)
                        self.todayMotivationCollectionView.reloadData()
                        self.todayMotivationCollectionView.hideSkeleton(transition: .crossDissolve(0.25))
                    }
                }
            }
        })
    }
    
    func getMotivationBackgrounds(){
            self.motivationRefHandle = DBRef.motivationImages.observe(.childAdded) {(snap) in
            let motivationURL = snap.value as! String
            self.motivationBackground.append(motivationURL)
            self.todayMotivationCollectionView.reloadData()
        }
    }
    
    @objc func editMotivation(_ notification: NSNotification){
        if let motivationID = notification.userInfo?["motivationID"] as? String {
            changeMotivationPopup(motivationID: motivationID) { (true) in
                self.getMotivations()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToKasamActivityViewer" {
            let kasamActivityHolder = segue.destination as! KasamActivityViewer
            kasamActivityHolder.kasamID = kasamIDforViewer
            kasamActivityHolder.blockID = blockIDGlobal
            kasamActivityHolder.dayToLoad = dayToLoadGlobal
            kasamActivityHolder.dayOrder = dayOrderGlobal
            kasamActivityHolder.viewingOnlyCheck = viewOnlyGlobal
        } else if segue.identifier == "goToKasamHolder" {
            let kasamTransferHolder = segue.destination as! KasamHolder
            kasamTransferHolder.kasamID = kasamIDforHolder
        }
    }
}

//TABLEVIEW-----------------------------------------------------------------------------------------------

extension TodayBlocksViewController: SkeletonTableViewDataSource, UITableViewDataSource, UITableViewDelegate, TableCellDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if noKasamTracker == 1 {
            return 1
        } else {
            return SavedData.kasamBlocks.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodayKasamCell") as! TodayBlockCell
        if noKasamTracker == 1 {
            //set placeholder
        } else {
            cell.row = indexPath.row
            cell.cellDelegate = self
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tableCell = cell as? TodayBlockCell else { return }
        tableCell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.row)
        tableCell.cellFormatting()
        tableCell.setBlock(block: SavedData.kasamBlocks[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let height = UITableView.automaticDimension
        return height
    }
    
    func goToKasamHolder(_ sender: UIButton, kasamOrder: Int) {
        if SavedData.kasamBlocks.count > kasamOrder {
            kasamIDforHolder = SavedData.kasamBlocks[kasamOrder].kasamID
        }
        self.performSegue(withIdentifier: "goToKasamHolder", sender: kasamOrder)
    }
    
    func completeAndUnfollow(_ sender: UIButton, kasamOrder: Int) {
        let popupImage = UIImage.init(icon: .fontAwesomeSolid(.rocket), size: CGSize(width: 30, height: 30), textColor: .white)
        showPopupConfirmation(title: "Finish & Unfollow?", description: "You'll be unfollowing this Kasam, but your past progress and badges will be saved", image: popupImage, buttonText: "Finish & Unfollow", completion: {(success) in
            let kasamID = SavedData.kasamBlocks[kasamOrder].kasamID
            let kasamJoinDate = self.dateFormat(date: SavedData.kasamDict[kasamID]?.joinedDate ?? Date())
            DBRef.userKasamFollowing.child(kasamID).child("Past Join Dates").child(kasamJoinDate).setValue(SavedData.kasamDict[kasamID]?.repeatDuration)
            DBRef.userKasamFollowing.child(kasamID).child("Status").setValue("completed")
            self.getKasamFollowing(nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "ProfileUpdate"), object: self)
        })
    }
    
    //TABLEVIEW SKELETON----------------------------------------------------------------------
    func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return "TodayKasamCell"
    }
}

//COLLECTIONVIEW------------------------------------------------------------------------

extension TodayBlocksViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, SkeletonCollectionViewDataSource, DayTrackerCellDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == todayMotivationCollectionView {
            return motivationArray.count
        } else if collectionView == challengesColletionView {
            return SavedData.challengeBlocks.count
        } else {
            //for Kasam DayTracker
            if SavedData.kasamBlocks.count > collectionView.tag {        //ensures the kasam is loaded before reading the dayTracker
                return SavedData.kasamDict[SavedData.kasamBlocks[collectionView.tag].kasamID]!.repeatDuration
            } else {
                return 10
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == todayMotivationCollectionView {
            todayCollectionHeight.constant = (view.bounds.size.width * (2/5))
            return CGSize(width: (view.frame.size.width - 30), height: view.frame.size.width * (2/5))
        } else if collectionView == challengesColletionView{
            return CGSize(width: challengeCellWidth, height: challengeCellWidth * 1.3)
        } else {
            return CGSize(width: 37, height: 50)    //day tracker
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let collectionViewCell = cell as? TodayChallengesCell {
            collectionViewCell.setBlock(challenge: SavedData.challengeBlocks[indexPath.row])
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == todayMotivationCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TodayMotivationCell", for: indexPath) as! TodayMotivationCell
            if indexPath.row < motivationBackground.count  {
                cell.backgroundImage.sd_setImage(with: URL(string: motivationBackground[indexPath.row]))
            } else {
                cell.backgroundImage.image = PlaceHolders.motivationPlaceholder
            }
            cell.motivationText.text = motivationArray[indexPath.row].motivationText
            cell.motivationID["motivationID"] = motivationArray[indexPath.row].motivationID
            return cell
        } else if collectionView == challengesColletionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TodayChallengesCell", for: indexPath) as! TodayChallengesCell
            cell.cellDelegate = self
            cell.row = indexPath.row
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DayTrackerCell", for: indexPath) as! TodayDayTrackerCell
            if SavedData.kasamBlocks.count > collectionView.tag {
                cell.dayTrackerDelegate = self
                let kasamBlock = SavedData.kasamBlocks[collectionView.tag]
                let day = indexPath.row + 1
                var today = Int(kasamBlock.dayOrder)
                if kasamBlock.dayCount != nil {today = kasamBlock.dayCount!}
                cell.setBlock(kasamID: kasamBlock.kasamID, kasamOrder: collectionView.tag, day: day, status: SavedData.kasamDict[kasamBlock.kasamID]?.dayTrackerArray?[indexPath.row + 1]?.1 ?? 0.0, date: dayTrackerDateFormat(date: Date(), todayDay: today, row: indexPath.row + 1), today: day == today, future: day > today)
            }
            return cell
        }
    }
    
    func goToChallengeKasamHolder(_ sender: UIButton, kasamOrder: Int) {
        kasamIDforHolder = SavedData.challengeBlocks[kasamOrder].kasamID
        self.performSegue(withIdentifier: "goToKasamHolder", sender: kasamOrder)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView == todayMotivationCollectionView {
            return UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        } else if collectionView == challengesColletionView {
            return UIEdgeInsets(top: 0, left: 10, bottom: 10, right: 10)
        } else {
            return UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == todayMotivationCollectionView {
            let motivationID = motivationArray[indexPath.row].motivationID
            changeMotivationPopup(motivationID: motivationID) {(true) in
                self.getMotivations()
            }
        } else if collectionView == challengesColletionView {
            if SavedData.kasamDict[SavedData.challengeBlocks[indexPath.row].kasamID]?.metricType != "Checkmark" {
                loadingAnimation(animationView: animationView, animation: "loading", height: 100, overlayView: nil, loop: true, completion: nil)
                UIApplication.shared.beginIgnoringInteractionEvents()
                kasamIDforViewer = SavedData.challengeBlocks[indexPath.row].kasamID
                blockIDGlobal = SavedData.challengeBlocks[indexPath.row].blockID
                dayOrderGlobal = SavedData.challengeBlocks[indexPath.row].dayOrder
                performSegue(withIdentifier: "goToKasamActivityViewer", sender: indexPath)
            } else {
                updateKasamDayButtonPressed(kasamOrder: SavedData.challengeBlocks[indexPath.row].kasamOrder, day: SavedData.kasamDict[SavedData.challengeBlocks[indexPath.row].kasamID]!.currentDay, challenge: true)
            }
        }
    }
    
    func dayPressed(_ sender: UIButton, kasamOrder: Int, day: Int, metricType: String, viewOnly: Bool?) {
        if day <= SavedData.kasamBlocks[kasamOrder].dayOrder || SavedData.kasamDict[SavedData.kasamBlocks[kasamOrder].kasamID]?.timelineDuration != nil {
            if metricType == "Checkmark" {
                updateKasamDayButtonPressed(kasamOrder: kasamOrder, day: day, challenge: false)
            } else {
                openKasamBlock(sender, kasamOrder: kasamOrder, day: day, viewOnly: viewOnly)
            }
        }
    }
    
    func openKasamBlock(_ sender: UIButton, kasamOrder: Int, day: Int?, viewOnly: Bool?) {
        loadingAnimation(animationView: animationView, animation: "loading", height: 100, overlayView: nil, loop: true, completion: nil)
        UIApplication.shared.beginIgnoringInteractionEvents()
        let kasamID = SavedData.kasamBlocks[kasamOrder].kasamID
        kasamIDforViewer = kasamID
        blockIDGlobal = SavedData.kasamBlocks[kasamOrder].blockID
        dayOrderGlobal = SavedData.kasamBlocks[kasamOrder].dayOrder
        if day != nil {
            viewOnlyGlobal = viewOnly ?? false
            //Opening a past day's block
            DBRef.coachKasams.child(kasamID).child("Blocks").observeSingleEvent(of: .value, with: {(blockCountSnapshot) in
                let blockCount = Int(blockCountSnapshot.childrenCount)
                var blockOrder = "1"
                if day! <= blockCount {
                    blockOrder = String(day!)
                } else {
                    blockOrder = String((blockCount / day!) + 1)
                }
                if blockCount > 1 {
                    //OPTION 1 - Day in past, so find the correct block to show
                    DBRef.coachKasams.child(kasamID).child("Blocks").queryOrdered(byChild: "Order").queryEqual(toValue : blockOrder).observeSingleEvent(of: .childAdded, with: {(snapshot) in
                        let value = snapshot.value as! Dictionary<String,Any>
                        self.blockIDGlobal = value["BlockID"] as? String ?? SavedData.kasamBlocks[kasamOrder].blockID
                        self.dayToLoadGlobal = day!
                        self.performSegue(withIdentifier: "goToKasamActivityViewer", sender: kasamOrder)
                    })
                } else {
                    //OPTION 2 - Day in past and Kasam has only 1 block, so no point finding the correct block
                    self.dayToLoadGlobal = day!
                    self.performSegue(withIdentifier: "goToKasamActivityViewer", sender: kasamOrder)
                }
            })
        } else {
            //OPTION 3 - Open Today's block
            self.dayToLoadGlobal = self.dayOrderGlobal
            self.performSegue(withIdentifier: "goToKasamActivityViewer", sender: kasamOrder)
        }
    }
    
    //COLLECTIONVIEW SKELETON----------------------------------------------------------------------
    func collectionSkeletonView(_ skeletonView: UICollectionView, cellIdentifierForItemAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return "TodayMotivationCell"
    }
    
    func collectionSkeletonView(_ skeletonView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
}
