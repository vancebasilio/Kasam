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
import SystemConfiguration

class TodayBlocksViewController: UIViewController, UIGestureRecognizerDelegate, CollectionCellDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var todaySublabel: UILabel!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var challengesTitle: UILabel!
    @IBOutlet weak var challengesColletionView: UICollectionView!
    @IBOutlet weak var challengesCollectionHeight: NSLayoutConstraint!
    @IBOutlet weak var contentView: NSLayoutConstraint!
    
    let reachability = try! Reachability()
    
    var blockURLGlobal = ""
    var dateSelected = ""
    var kasamIDforViewer = ""
    var kasamIDforHolder = ""
    var blockIDGlobal = ""
    var blockNameGlobal = ""
    var dateGlobal: Date?
    var dayToLoadGlobal: Int?
    var viewOnlyGlobal = false
    var setupCheck = 0
    var newKasamType = "basic"
    
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
        self.getKasamFollowing(nil)
        setupNavBar(clean: false)                   //global function
        setupNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setReachabilityNotifier()
    }
    
    private func setReachabilityNotifier() {
        reachability.whenReachable = { reachability in
            if reachability.connection == .wifi {print("Reachable via WiFi")}
            else {print("Reachable via Cellular")}
            SwiftEntryKit.dismiss()
        }
        reachability.whenUnreachable = { _ in
            print("Not reachable")
            self.updateContentTableHeight()
            showProcessingNote()
        }
        do {try reachability.startNotifier()}
        catch {print("Unable to start notifier")}
    }
    
    func isNetworkReachable (with flags: SCNetworkReachabilityFlags) -> Bool {
        let isReachable = flags.contains (.reachable)
        let needsConnection = flags.contains (.connectionRequired)
        let canConnectAutomatically = flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)
        let canConnectWithoutUserInteraction = canConnectAutomatically && !flags.contains (.interventionRequired)
        return isReachable && (!needsConnection || canConnectWithoutUserInteraction)
    }
    
    //Center the day Tracker to today
    override func viewDidLayoutSubviews() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "CenterCollectionView"), object: self)
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

        let resetTodayChallenges = NSNotification.Name("ResetTodayChallenges")
        NotificationCenter.default.addObserver(self, selector: #selector(TodayBlocksViewController.resetTodayChallenges), name: resetTodayChallenges, object: nil)
        
        let goToCreateKasam = NSNotification.Name("GoToCreateKasam")
        NotificationCenter.default.addObserver(self, selector: #selector(TodayBlocksViewController.goToCreateKasam), name: goToCreateKasam, object: nil)
               
       let goToNotifications = NSNotification.Name("GoToNotifications")
       NotificationCenter.default.addObserver(self, selector: #selector(TodayBlocksViewController.goToNotifications), name: goToNotifications, object: nil)
    }
    
    @objc func goToCreateKasam(_ notification: NSNotification?) {
        NewKasam.resetKasam()
        newKasamType = notification?.userInfo?["type"] as! String
        performSegue(withIdentifier: "goToCreateKasam", sender: nil)
    }
    
    @objc func goToNotifications(){
        performSegue(withIdentifier: "goToNotifications", sender: nil)
    }
    
    //Table Resizing----------------------------------------------------------------------------------------
    
    func updateContentTableHeight(){
        //Set the table row height, based on the screen size
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
        if challengeOrder != 0 {challengesCollectionHeight.constant = (challengeCellWidth * 1.3)}
        else {challengesCollectionHeight.constant = 0}
        
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
        print("step 1 inside get following hell6")
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
        print("step 2 inside get preferences hell6")
        var image: String?
        //Get Kasams from user following + their preference for each kasam
        if let value = snapshot.value as? [String: Any] {
            let currentStatus = value["Status"] as? String ?? "active"
            let repeatDuration = value["Repeat"] as? Int ?? 1
    
            var order = 0
            if kasamID != nil && new == false {
                //Reloading kasam already being followed
                order = SavedData.kasamDict[kasamID!]!.kasamOrder
                image = SavedData.kasamDict[kasamID!]?.image
            } else if kasamID != nil && new == true {
                //Adding a new kasam to the today page
                if repeatDuration > 0 {order = SavedData.kasamBlocks.count}
                else if repeatDuration == 0 {order = SavedData.challengeBlocks.count}
            }
            else {
                //Reloading all kasams
                if repeatDuration > 0 {order = kasamOrder}
                else if repeatDuration == 0 {order = challengeOrder}
            }
            
            let preference = KasamSavedFormat(kasamID: snapshot.key, kasamName: value["Kasam Name"] as? String ?? "", joinedDate: (value["Date Joined"] as? String ?? "").stringToDate(), startTime: value["Time"] as? String ?? "", currentDay: 1, repeatDuration: repeatDuration, kasamOrder: order, image: image, metricType: value["Metric"] as? String ?? "Checkmark", timeline: value["Timeline"] as? Int, currentStatus: currentStatus, pastKasamJoinDates: value["Past Join Dates"] as? [String:Int], sequence: nil, streakInfo: (currentStreak:0, currentStreakCompleteProgress:0, daysWithAnyProgress:0, daysWithCompleteProgress:0, longestStreak:0, longestStreakDay:0), displayStatus: "Checkmark", percentComplete: 0.0, badgeThresholds: 30, badgeList: value["Badges"] as? [String:Int], benefitsThresholds: nil, dayTrackerArray: nil)
            if currentStatus == "active" {
                if repeatDuration > 0 {kasamOrder += 1}
                else if repeatDuration == 0 {challengeOrder += 1}
                if (kasamID == nil && new == false) || (kasamID != nil && new == true) {
                    SavedData.todayKasamList.append(preference.kasamID)
                }
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
        print("step 3 inside get kasams hell6")
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
                
                //OPTION 1 - Load blocks based on last completed (TIMELINE KASAMS) e.g. Insanity
                if kasam.timeline != nil {
                    var blockDayToLoad = 1
                    var dayToShow = 1
                    for date in Date.dates(from: kasam.joinedDate, to: Date()) {
                        let dateString = date.dateToString()
                        DBRef.userHistory.child(kasam.kasamID).child(dateString).observeSingleEvent(of: .value) {(snapCount) in
                            if dateString != Dates.getCurrentDate() && snapCount.exists() {
                                blockDayToLoad += 1               //the user has completed xx number of blocks in the past (excludes today's block)
                            } else if dateString == Dates.getCurrentDate() {
                                DBRef.coachKasams.child(kasam.kasamID).child("Timeline").observe(.value, with: {(snapshot) in
                                    if let value = snapshot.value as? [String:String] {
                                        dayToShow = blockDayToLoad
                                        if blockDayToLoad > value.count {
                                            blockDayToLoad = (blockDayToLoad % value.count) + 1
                                        }
                                        DBRef.coachKasams.child(kasam.kasamID).child("Blocks").child(value["D\(blockDayToLoad)"]!).observeSingleEvent(of: .value) {(snapshot) in
                                            todayKasamCount += 1
                                            self.saveKasamBlocks(value: snapshot.value as! Dictionary<String,Any>, todayKasamCount: todayKasamCount, dayOrder: dayOrder, kasam: kasam, repeatMultiple: kasam.repeatDuration > 1, specificKasam: kasamID, dayCount: dayToShow)
                                        }
                                    }
                                })
                            }
                        }
                    }
                //OPTION 2 - Load Kasam as Block (BASIC KASAMS)
                } else if kasam.metricType == "Checkmark" {
                    DBRef.coachKasams.child(kasam.kasamID).observe(.value) {(snapshot) in
                        todayKasamCount += 1
                        self.saveKasamBlocks(value: snapshot.value as! Dictionary<String,Any>, todayKasamCount: todayKasamCount, dayOrder: dayOrder, kasam: kasam, repeatMultiple: kasam.repeatDuration > 1, specificKasam: kasamID, dayCount: nil)
                    }
                //OPTION 3 - Load single repeated block (CHALLENGE KASAMS) e.g. 200 Push-ups
                } else {
                    DBRef.coachKasams.child(kasam.kasamID).child("Blocks").observeSingleEvent(of: .childAdded, with: {(snapshot) in
                        todayKasamCount += 1
                        self.saveKasamBlocks(value: snapshot.value as! Dictionary<String,Any>, todayKasamCount: todayKasamCount, dayOrder: dayOrder, kasam: kasam, repeatMultiple: kasam.repeatDuration > 1, specificKasam: kasamID, dayCount: nil)
                    })
                }
            }
        }
    }
    
    //STEP 4
    func saveKasamBlocks(value: Dictionary<String,Any>, todayKasamCount: Int, dayOrder: Int, kasam: KasamSavedFormat, repeatMultiple: Bool, specificKasam: String?, dayCount: Int?){
        print("step 4 save kasam Blocks hell6")
        let kasamImage = value["Image"] as! String
        SavedData.kasamDict[kasam.kasamID]?.image = kasamImage
        let block = TodayBlockFormat(kasamOrder: kasam.kasamOrder, kasamID: kasam.kasamID, blockID: value["BlockID"] as? String ?? "", blockTitle: value["Title"] as! String, dayOrder: dayOrder, duration: value["Duration"] as? String, image: URL(string: kasamImage) ?? URL(string:PlaceHolders.kasamLoadingImageURL)!, dayCount: dayCount)
        
        if repeatMultiple == true {
            SavedData.kasamBlocks.append(block)
            SavedData.kasamBlocks = SavedData.kasamBlocks.sorted(by: {$0.kasamOrder < $1.kasamOrder})
        } else {
            SavedData.challengeBlocks.append(block)
            SavedData.challengeBlocks = SavedData.challengeBlocks.sorted(by: {$0.kasamOrder < $1.kasamOrder})
        }
        
        if specificKasam != nil {
            self.getDayTracker(kasamID: specificKasam)
            self.challengesColletionView.reloadData()
            self.updateContentTableHeight()
        } else {
            if todayKasamCount == SavedData.todayKasamList.count {
                //Only does the below after all Kasams loaded
                self.todaySublabel.text = "You have \(SavedData.kasamBlocks.count.pluralUnit(unit: "kasam")) to complete"
                self.tableView.reloadData()
                self.updateContentTableHeight()
                self.getDayTracker(kasamID: nil)
                DispatchQueue.main.async {self.challengesColletionView.reloadData()}
            }
        }
        self.tableView.hideSkeleton(transition: .crossDissolve(0.25))
    }
    
    @objc func resetTodayChallenges(){
        self.challengesColletionView.reloadData()
    }
    
    //STEP 5
    func getDayTracker(kasamID: String?) {
        print("step 5 get day Tracker hell6")
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
        //OPTION 1 - TODAY DAY TRACKER
            if kasam.repeatDuration == 0 {
                DBRef.userHistory.child(kasam.kasamID).child(Dates.getCurrentDate()).observeSingleEvent(of: .value, with: {(snap) in
                    if snap.exists(){
                        let statusPercent = self.statusPercentCalc(snapshot: snap)
                        SavedData.kasamDict[(kasam.kasamID)]?.percentComplete = statusPercent.0
                        SavedData.kasamDict[(kasam.kasamID)]?.displayStatus = statusPercent.1
                        count += 1
                        if let cell = self.challengesColletionView.cellForItem(at: IndexPath(item: kasam.kasamOrder, section: 0)) as? TodayChallengesCell {cell.statusUpdate()}
                    } else {
                        if let cell = self.challengesColletionView.cellForItem(at: IndexPath(item: kasam.kasamOrder, section: 0)) as? TodayChallengesCell {cell.statusUpdate()}
                    }
                })
        //OPTION 2 - FUN % COMPLETE TODAY
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
                    var dayCounter = 0
                    //Gets the DayTracker info - only goes into this loop if the user has kasam history
                    self.dayTrackerRefHandle = DBRef.userHistory.child(kasam.kasamID).observe(.childAdded, with: {(snap) in
                        let kasamDate = snap.key.stringToDate()
                        if kasamDate >= kasam.joinedDate {
                            dayCounter += 1
                            if SavedData.kasamDict[(kasam.kasamID)]?.timeline == nil {
                                order = (Calendar.current.dateComponents([.day], from: kasam.joinedDate, to: kasamDate)).day! + 1     //use for no gaps for days missed
//                                order += 1
                            } else {
                                order += 1
                            }
                            dayPercent = self.statusPercentCalc(snapshot: snap).0
                            
                            //DayTrackerDateArray is correct
                            dayTrackerArrayInternal[order] = (kasamDate, dayPercent)
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
                            
                            let streakInfo = self.currentStreak(kasamID: kasam.kasamID, dictionary: dayTrackerArrayInternal, currentDay: SavedData.kasamBlocks[kasamOrder].dayOrder)
                            SavedData.kasamDict[kasam.kasamID]?.streakInfo = streakInfo
                            DBRef.userHistory.child(kasam.kasamID).removeAllObservers()
                            count += 1
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "RefreshKasamHolderBadge"), object: self)
                            self.setupCheck = 1
                            if kasamID == nil {
                                //OPTION 1 - Updating all the kasams on the today page
                                self.singleKasamUpdate(kasamOrder: kasamOrder)
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
                        self.singleKasamUpdate(kasamOrder: kasamOrder)
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
            cell.statusUpdate(nil)
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
            cell.statusUpdate(nil)
            cell.centerCollectionView()
            cell.collectionCoverUpdate()
            cell.dayTrackerCollectionView.reloadData()
            self.updateContentTableHeight()
            self.tableView.endUpdates()
        }
    }
    
    //STEP 5B
    func currentStreak(kasamID: String, dictionary: [Int:(Date, Double)], currentDay: Int) -> (currentStreak:Int, currentStreakCompleteProgress:Int, daysWithAnyProgress:Int, daysWithCompleteProgress:Int, longestStreak:Int, longestStreakDay:Int) {
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
        return (currentStreak, currentStreakCompleteProgress, daysWithAnyProgress, daysWithCompleteProgress, longestStreak, longestStreakDay)
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
    
    //PART 1 - BASIC KASAM UPDATE
    func updateKasamDayButtonPressed(kasamOrder: Int, day: Int, challenge:Bool){
        let block: TodayBlockFormat?
        if challenge == true {block = SavedData.challengeBlocks[kasamOrder]}
        else {block = SavedData.kasamBlocks[kasamOrder]}
        
        //STEP 2 - STATUS UPDATE
        var status = "Checkmark"
        let statusDate = (Calendar.current.date(byAdding: .day, value: day - block!.dayOrder, to: Date())!).dateToString()
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
    
    //PART 2 - COMPLEX BASED KASAM UPDATE
    @objc func updateKasamStatus(_ notification: NSNotification) {
        if let kasamID = notification.userInfo?["kasamID"] as? String {
            let kasamOrder = (SavedData.kasamDict[kasamID]!.kasamOrder)
            var statusDate = Dates.getCurrentDate()
            if notification.userInfo?["date"] != nil {statusDate = notification.userInfo?["date"] as? String ?? Date().dateToString()}
            DBRef.userHistory.child(kasamID).child(statusDate).observe(.value, with: {(snapshot) in
                if SavedData.kasamDict[kasamID]!.repeatDuration > 0 {
                    //OPTION 1 - FOR UPDATING REPEATED KASAM
                    let kasamDate = snapshot.key.stringToDate()
                    var dayOrder = 0
                    var dayCount = 0
                    if SavedData.kasamDict[kasamID]?.timeline != nil {
                        if let day = notification.userInfo?["day"] {
                            dayOrder = day as? Int ?? 0
                        }
                    } else {
                        dayOrder = (Calendar.current.dateComponents([.day], from: SavedData.kasamDict[kasamID]!.joinedDate, to: kasamDate)).day! + 1
                    }
                    
                    //STEP 1 - Updates the DayTracker
                    var statusPercent: (Double, String)?
                    if snapshot.exists() {
                        dayCount += 1
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
                        let streak = self.currentStreak(kasamID: kasamID, dictionary: (SavedData.kasamDict[kasamID]?.dayTrackerArray!)!, currentDay: SavedData.kasamBlocks[kasamOrder].dayOrder)
                        SavedData.kasamDict[kasamID]!.streakInfo = streak
                    }
                    
                    if let cell = self.tableView.cellForRow(at: IndexPath(item: kasamOrder, section: 0)) as? TodayBlockCell {
                        self.tableView.beginUpdates()
                        cell.statusUpdate(statusDate)
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
        for kasam in SavedData.kasamDict {
            //STEP 1 - GET THE BADGE THRESHOLD IF IT'S NOT 30
            DBRef.coachKasams.child(kasam.value.kasamID).child("Badges").observeSingleEvent(of: .value) {(snap) in
                if snap.exists() {SavedData.kasamDict[kasam.value.kasamID]?.badgeThresholds = snap.value as? Int ?? 30}
                self.badgesAchieved(kasam:kasam)
            }
            DBRef.coachKasams.child(kasam.value.kasamID).child("Thresholds").observeSingleEvent(of: .value) {(snap) in
                if let dict = snap.value as? [String:String] {
                    SavedData.kasamDict[kasam.value.kasamID]!.benefitsThresholds = [(Int, String)]()
                    for value in dict {SavedData.kasamDict[kasam.value.kasamID]!.benefitsThresholds!.append((Int(value.key)!, value.value))}
                }
                SavedData.kasamDict[kasam.value.kasamID]!.benefitsThresholds = SavedData.kasamDict[kasam.value.kasamID]!.benefitsThresholds?.sorted(by: {$0.0 < $1.0})
            }
        }
    }
    
    //PART 2
    func badgesAchieved(kasam: Dictionary<String, KasamSavedFormat>.Element) {
        //STEP 2 - GET THE BADGES
        SavedData.badgesCount += kasam.value.badgeList?.count ?? 0
        if kasam.value.badgeList != nil {
            for badge in kasam.value.badgeList! {
                if SavedData.badgesAchieved[kasam.value.kasamName] == nil {
                    SavedData.badgesAchieved[kasam.value.kasamName] = [((badge.key, badge.value))]
                } else {
                    SavedData.badgesAchieved[kasam.value.kasamName]!.append((badge.key, badge.value))
                }
            }
            SavedData.badgesCount = (SavedData.badgesAchieved.values.map { $0.count }).reduce(0, { $0 + $1 })
            SavedData.badgeSubCatCount = SavedData.badgesCount + SavedData.badgesAchieved.count
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToKasamActivityViewer" {
            let kasamViewer = segue.destination as! KasamActivityViewer
            kasamViewer.kasamID = kasamIDforViewer
            kasamViewer.blockID = blockIDGlobal
            kasamViewer.blockName = blockNameGlobal
            kasamViewer.viewingOnlyCheck = viewOnlyGlobal
            kasamViewer.dateToLoad = dateGlobal
            kasamViewer.dayToLoad = dayToLoadGlobal
        } else if segue.identifier == "goToKasamHolder" {
            let kasamTransferHolder = segue.destination as! KasamHolder
            kasamTransferHolder.kasamID = kasamIDforHolder
        } else if segue.identifier == "goToCreateKasam" {
//            let segueTransferHolder = segue.destination as! NewKasamPageController
//            segueTransferHolder.kasamType = newKasamType
        } else if segue.identifier == "goToNotifications" {
            //No variables to set
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
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let height = (tableView.frame.width / 2.4) + 15
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
            let kasamJoinDate = (SavedData.kasamDict[kasamID]?.joinedDate ?? Date()).dateToString()
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
        if collectionView == challengesColletionView {
            return SavedData.challengeBlocks.count
        } else {
            //for Kasam DayTracker
            if SavedData.kasamBlocks.count > collectionView.tag {        //ensures the kasam is loaded before reading the dayTracker
                let kasamID = SavedData.kasamBlocks[collectionView.tag].kasamID
                var progressAchieved = 0
                if SavedData.kasamDict[kasamID]?.sequence == "streak" {
                    if SavedData.kasamDict[kasamID]?.streakInfo.longestStreak != nil {
                        progressAchieved = SavedData.kasamDict[kasamID]!.streakInfo.currentStreakCompleteProgress
                    }
                } else {
                    if SavedData.kasamDict[kasamID]?.streakInfo.daysWithAnyProgress != nil {
                        progressAchieved = SavedData.kasamDict[kasamID]!.streakInfo.daysWithAnyProgress
                    }
                }
                if SavedData.kasamDict[kasamID]!.repeatDuration - progressAchieved == 1 {
                    return SavedData.kasamDict[kasamID]!.repeatDuration
                } else {
                    return SavedData.kasamDict[kasamID]!.repeatDuration + SavedData.kasamDict[kasamID]!.currentDay - progressAchieved
                }
            } else {
                return 10
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == challengesColletionView{
            return CGSize(width: challengeCellWidth, height: (challengeCellWidth * 1.3) - 10)
        } else {
            return CGSize(width: 37, height: 50)    //day tracker
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == challengesColletionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TodayChallengesCell", for: indexPath) as! TodayChallengesCell
            cell.cellDelegate = self
            cell.setBlock(challenge: SavedData.challengeBlocks[indexPath.row])
            cell.row = indexPath.row
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DayTrackerCell", for: indexPath) as! TodayDayTrackerCell
            if SavedData.kasamBlocks.count > collectionView.tag {
                cell.dayTrackerDelegate = self
                let kasamBlock = SavedData.kasamBlocks[collectionView.tag]
                let day = indexPath.row + 1
                var today = Int(kasamBlock.dayOrder)
                var date: Date?
                //For timeline kasasm
                if kasamBlock.dayCount != nil {
                    today = kasamBlock.dayCount!
                    if day == today {date = Date()}                                                             //set today's date
                    else if let pastDate = SavedData.kasamDict[kasamBlock.kasamID]?.dayTrackerArray?[indexPath.row + 1]?.date {
                        date = pastDate}                                                                        //set date for past progress
                    else {date = dayTrackerDateFormat(date: Date(), todayDay: today, row: indexPath.row + 1)}   //set date for future days
                }
                //For all other types of kasam
                else {date = dayTrackerDateFormat(date: Date(), todayDay: today, row: indexPath.row + 1)}
                cell.setBlock(kasamID: kasamBlock.kasamID, kasamOrder: collectionView.tag, day: day, status: SavedData.kasamDict[kasamBlock.kasamID]?.dayTrackerArray?[indexPath.row + 1]?.progress ?? 0.0, date: date ?? Date(), today: day == today, future: day > today)
            }
            return cell
        }
    }
    
    func goToChallengeKasamHolder(_ sender: UIButton, kasamOrder: Int) {
        kasamIDforHolder = SavedData.challengeBlocks[kasamOrder].kasamID
        self.performSegue(withIdentifier: "goToKasamHolder", sender: kasamOrder)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == challengesColletionView {
            if SavedData.kasamDict[SavedData.challengeBlocks[indexPath.row].kasamID]?.metricType != "Checkmark" {
                animationView.loadingAnimation(view: view, animation: "loading", height: 100, overlayView: nil, loop: true, completion: nil)
                UIApplication.shared.beginIgnoringInteractionEvents()
                kasamIDforViewer = SavedData.challengeBlocks[indexPath.row].kasamID
                blockIDGlobal = SavedData.challengeBlocks[indexPath.row].blockID
                performSegue(withIdentifier: "goToKasamActivityViewer", sender: indexPath)
            } else {
                updateKasamDayButtonPressed(kasamOrder: SavedData.challengeBlocks[indexPath.row].kasamOrder, day: SavedData.kasamDict[SavedData.challengeBlocks[indexPath.row].kasamID]!.currentDay, challenge: true)
            }
        }
    }
    
    func dayPressed(_ sender: UIButton, kasamOrder: Int, day: Int, date: Date?, metricType: String, viewOnly: Bool?) {
        if day <= SavedData.kasamBlocks[kasamOrder].dayOrder || SavedData.kasamDict[SavedData.kasamBlocks[kasamOrder].kasamID]?.timeline != nil {
            if metricType == "Checkmark" {
                updateKasamDayButtonPressed(kasamOrder: kasamOrder, day: day, challenge: false)
            } else {
                openKasamBlock(sender, kasamOrder: kasamOrder, day: day, date: date, viewOnly: viewOnly)
            }
        }
    }
    
    func openKasamBlock(_ sender: UIButton, kasamOrder: Int, day: Int?, date: Date?, viewOnly: Bool?) {
        animationView.loadingAnimation(view: view, animation: "loading", height: 100, overlayView: nil, loop: true, completion: nil)
        UIApplication.shared.beginIgnoringInteractionEvents()
        let kasamID = SavedData.kasamBlocks[kasamOrder].kasamID
        kasamIDforViewer = kasamID
        blockIDGlobal = SavedData.kasamBlocks[kasamOrder].blockID
        blockNameGlobal = SavedData.kasamBlocks[kasamOrder].blockTitle
        dateGlobal = date
        
        //OPTION 1 - Opening a past day's block
        if day != nil {
            viewOnlyGlobal = viewOnly ?? false
            DBRef.coachKasams.child(kasamID).child("Blocks").observeSingleEvent(of: .value, with: {(blockCountSnapshot) in
                let blockCount = Int(blockCountSnapshot.childrenCount)
                var blockOrder = 1
                if SavedData.kasamDict[kasamID]?.timeline != nil {
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
    
    //COLLECTIONVIEW SKELETON----------------------------------------------------------------------
    func collectionSkeletonView(_ skeletonView: UICollectionView, cellIdentifierForItemAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return "TodayMotivationCell"
    }
    
    func collectionSkeletonView(_ skeletonView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
}
