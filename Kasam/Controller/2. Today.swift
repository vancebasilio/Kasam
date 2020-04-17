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
    
    var kasamBlocks: [TodayBlockFormat] = []
    var challengeBlocks: [TodayBlockFormat] = []
    var motivationArray: [motivationFormat] = []
    var motivationBackground: [String] = []
    
    var blockURLGlobal = ""
    var dateSelected = ""
    var kasamIDforViewer = ""
    var kasamIDforHolder = ""
    var blockIDGlobal = ""
    var dayToLoadGlobal = 0
    var dayOrderGlobal = 0
    
    let semaphore = DispatchSemaphore(value: 1)
    var collectionViewHeight = CGFloat(0.0)
    
    var kasamFollowingRefHandle: DatabaseHandle!
    var motivationRefHandle: DatabaseHandle!
    var dayTrackerRefHandle: DatabaseHandle!
    
    var dayTrackerDateArray = [Int:String]()
    var noKasamTracker = 0
    let animationView = AnimationView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.showAnimatedSkeleton()
        setupNavBar()                   //global function
        getPreferences()
        getMotivationBackgrounds()
//        getMotivations()
        setupNotifications()
        printLocalNotifications()
    }
    
    //Center the day Tracker to today
    override func viewDidLayoutSubviews() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "CenterCollectionView"), object: self)
    }
    
    //Starts the Animation badge playing when the view disppears and reappears
    override func viewDidAppear(_ animated: Bool) {
        for block in 0...kasamBlocks.count {
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
        
        let resetAllTodayKasams = NSNotification.Name("ResetAllTodayKasams")
        NotificationCenter.default.addObserver(self, selector: #selector(TodayBlocksViewController.getPreferences), name: resetAllTodayKasams, object: nil)
        
        let restTodayKasam = NSNotification.Name("ResetTodayKasam")
        NotificationCenter.default.addObserver(self, selector: #selector(TodayBlocksViewController.retrieveKasams), name: restTodayKasam, object: nil)
        
        let updateKasamStatus = NSNotification.Name("UpdateTodayBlockStatus")
        NotificationCenter.default.addObserver(self, selector: #selector(TodayBlocksViewController.updateKasamStatus), name: updateKasamStatus, object: nil)

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
        let challengeCollectionPadding: CGFloat =  30
        let collectionViewSize = frame.size.width - challengeCollectionPadding
        collectionViewHeight = (collectionViewSize/2)
        let lenghtMultiplier = (Double(challengeBlocks.count) / 2.0).rounded()
        challengesCollectionHeight.constant = (collectionViewHeight * CGFloat(lenghtMultiplier)) + 110
        
        let contentViewHeight = tableViewHeight.constant + (challengesCollectionHeight.constant) + 70
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
    
    //STEP 1
    @objc func getPreferences(){
        SavedData.kasamTodayArray.removeAll()           //kasamTodayArray is used for populating the Today page
        SavedData.kasamArray.removeAll()                //kasamArray is used for userProfile with all Kasams in it
        noKasamTracker = 0
        DBRef.userKasamFollowing.observeSingleEvent(of: .value, with:{(snap) in
            var kasamOrder = 0
            var challengeOrder = 0
            var count = Int(snap.childrenCount)                 //counts number of Kasams that the user is following
            if count == 0 {
                //not following any kasams
                self.noKasamTracker = 1
                self.tableView.reloadData()
                self.tableView.hideSkeleton(transition: .crossDissolve(0.25))
            }
            self.kasamFollowingRefHandle = DBRef.userKasamFollowing.observe(.childAdded) {(snapshot) in
                //Get Kasams from user following + their preference for each kasam
                if let value = snapshot.value as? [String: Any] {
                    let currentDateJoined = self.stringToDate(date: value["Date Joined"] as? String ?? "")
                    let badgeList = value["Badges"] as? [String: Int]
                    let currentStatus = value["Status"] as? String ?? "active"
                    let pastKasamDates = value["Past Join Dates"] as? [String:Int]
                    let repeatDuration = value["Repeat"] as? Int ?? 1
                    var order = 0
                    if repeatDuration > 1 {
                        order = kasamOrder
                    } else if repeatDuration == 1 {
                        order = challengeOrder
                    }
                    let preference = KasamSavedFormat(kasamID: snapshot.key, kasamName: value["Kasam Name"] as? String ?? "", joinedDate: currentDateJoined, startTime: value["Time"] as? String ?? "", currentDay: 1, repeatDuration: repeatDuration, kasamOrder: order, image: nil, metricType: nil, currentStatus: currentStatus, pastKasamJoinDates: pastKasamDates, type: value["Type"] as? String ?? "", badgeStreak: nil, badgeThresholds: nil, badgeList: badgeList)
                    if currentStatus == "active" {
                        if repeatDuration > 1 {
                            kasamOrder += 1
                        } else if repeatDuration == 1 {
                            challengeOrder += 1
                        }
                        SavedData.kasamTodayArray.append(preference)
                    } else {
                        count -= 1
                    }
                    SavedData.addKasam(kasam: preference)                   //adds all kasams that the user is following
                    if SavedData.kasamTodayArray.count == count {
                        self.retrieveKasams(nil)
                        if challengeOrder == 0 {self.challengesTitle.isHidden = true} else {self.challengesTitle.isHidden = false}
                        //update the user profile page
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "KasamStatsUpdate"), object: self)
                        DBRef.userKasamFollowing.removeObserver(withHandle: self.kasamFollowingRefHandle)
                    }
                }
            }
        })
    }
    
    //STEP 2
    @objc func retrieveKasams(_ notification: NSNotification?) {
        var todayKasamCount = 0
        if SavedData.kasamTodayArray.count == 0 {                   //user is following Kasams that aren't active yet
            self.noKasamTracker = 1
            self.tableView.reloadData()
            self.tableView.hideSkeleton(transition: .crossDissolve(0.25))
        }
        var kasamArray = SavedData.kasamTodayArray
        let kasamID = notification?.userInfo?["kasamID"] as? String
        if let index = SavedData.kasamTodayArray.index(where: {($0.kasamID == kasamID)}) {
            //updating existing kasam on the today page
            kasamArray = [SavedData.kasamTodayArray[index]]
            if let blockIndex = self.kasamBlocks.index(where: {($0.kasamID == kasamID)}){
                self.kasamBlocks.remove(at: blockIndex)
            } else if let blockIndex = self.challengeBlocks.index(where: {($0.kasamID == kasamID)}){
                self.challengeBlocks.remove(at: blockIndex)
            }
        } else {
            //updating all kasams on the today page
            self.kasamBlocks.removeAll()
            self.challengeBlocks.removeAll()
        }
        for kasam in kasamArray {
            var dayOrder = 0
            //Seeing which blocks are needed for the day
            if kasam.currentStatus == "inactive" || kasam.currentStatus == "completed" {
                todayKasamCount += 1
            } else if kasam.currentStatus == "active" {
                dayOrder = ((Calendar.current.dateComponents([.day], from: kasam.joinedDate, to: Date()).day!) + 1)
                SavedData.kasamDict[kasam.kasamID]?.currentDay = dayOrder
                //Finds out which block should be called based on the day of the kasam the user is on
                DBRef.coachKasams.child(kasam.kasamID).child("Blocks").observeSingleEvent(of: .value, with: {(blockCountSnapshot) in
                    let blockCount = Int(blockCountSnapshot.childrenCount)
                    var blockOrder = "1"
                    if dayOrder <= blockCount {
                        blockOrder = String(dayOrder)
                    } else {
                        blockOrder = String((blockCount / dayOrder) + 1)
                    }
                    if kasam.repeatDuration > 1 {
                        //Get block info for the Today Repeated Kasams
                        if kasam.type == "Basic" {
                            DBRef.coachKasams.child(kasam.kasamID).observe(.value) {(snapshot) in
                                todayKasamCount += 1
                                let value = snapshot.value as! Dictionary<String,Any>
                                self.saveKasamBlocks(value: value, todayKasamCount: todayKasamCount, dayOrder: dayOrder, kasam: kasam, repeatMultiple: true, specificKasam: kasamID)
                            }
                        } else if kasam.type == "Challenge" {
                            DBRef.coachKasams.child(kasam.kasamID).child("Blocks").queryOrdered(byChild: "Order").queryEqual(toValue : blockOrder).observeSingleEvent(of: .childAdded, with: {(snapshot) in
                                todayKasamCount += 1
                                let value = snapshot.value as! Dictionary<String,Any>
                                self.saveKasamBlocks(value: value, todayKasamCount: todayKasamCount, dayOrder: dayOrder, kasam: kasam, repeatMultiple: true, specificKasam: kasamID)
                            })
                        }
                    } else if kasam.repeatDuration == 1 {
                        //One-time Kasam
                        DBRef.coachKasams.child(kasam.kasamID).child("Blocks").queryOrdered(byChild: "Order").queryEqual(toValue : blockOrder).observeSingleEvent(of: .childAdded, with: {(snapshot) in
                            todayKasamCount += 1
                            let value = snapshot.value as! Dictionary<String,Any>
                            self.saveKasamBlocks(value: value, todayKasamCount: todayKasamCount, dayOrder: dayOrder, kasam: kasam, repeatMultiple: false, specificKasam: kasamID)
                        })
                    }
                })
            }
            
        }
    }
    
    //STEP 3
    func saveKasamBlocks(value: Dictionary<String,Any>, todayKasamCount: Int, dayOrder: Int, kasam: KasamSavedFormat, repeatMultiple: Bool, specificKasam: String?){
        let block = TodayBlockFormat(kasamOrder: kasam.kasamOrder, kasamID: kasam.kasamID, blockID: value["BlockID"] as? String ?? "", kasamName: kasam.kasamName, blockTitle: value["Title"] as! String, dayOrder: dayOrder, duration: value["Duration"] as? String, repeatDuration: kasam.repeatDuration, image: URL(string: value["Image"] as! String) ?? URL(string:PlaceHolders.kasamLoadingImageURL)!, kasamType: kasam.type, displayStatus: "Checkmark", dayTrackerArray: nil, currentStreak: nil, totalDaysCompleted: nil, percentComplete: nil, kasamLevel: value["Level"] as? String ?? "Beginner")
        if repeatMultiple == true {
            self.kasamBlocks.append(block)
            self.kasamBlocks = self.kasamBlocks.sorted(by: {$0.kasamOrder < $1.kasamOrder})
            SavedData.kasamTodayArray = SavedData.kasamTodayArray.sorted(by: { $0.kasamOrder < $1.kasamOrder })
        } else {
            self.challengeBlocks.append(block)
            self.challengeBlocks = self.challengeBlocks.sorted(by: {$0.kasamOrder < $1.kasamOrder})
            SavedData.kasamTodayArray = SavedData.kasamTodayArray.sorted(by: { $0.kasamOrder < $1.kasamOrder })
        }
        if specificKasam != nil {
            self.getDayTracker(kasamID: specificKasam)
        } else {
            if todayKasamCount == SavedData.kasamTodayArray.count {
                //only does the below after all Kasams loaded
                self.todaySublabel.text = "You have \(self.kasamBlocks.count) kasams to complete"
                self.getDayTracker(kasamID: nil)
                self.tableView.reloadData()
                self.challengesColletionView.reloadData()
                self.updateContentTableHeight()
            }
        }
        self.tableView.hideSkeleton(transition: .crossDissolve(0.25))
    }
    
    @objc func resetTodayChallenges(){
        self.challengesColletionView.reloadData()
    }
    
    //STEP 4
    func getDayTracker(kasamID: String?) {
        //for the active Kasams on the Today page
        var count = 0
        var kasamArray = SavedData.kasamTodayArray
        if let index = SavedData.kasamTodayArray.index(where: {($0.kasamID == kasamID)}) {
            kasamArray = [SavedData.kasamTodayArray[index]]
        }
        for kasam in kasamArray {
            var displayStatus = "Checkmark"
            if kasam.repeatDuration == 1 {
                //GET CHALLENGE PERCENT COMPLETE
                let kasamOrder = kasam.kasamOrder
                DBRef.userHistory.child(kasam.kasamID).child(self.getCurrentDate()!).observeSingleEvent(of: .value, with: {(snap) in
                    let statusPercent = self.statusPercentCalc(snapshot: snap)
                    self.challengeBlocks[kasamOrder].percentComplete = statusPercent.0
                    self.challengeBlocks[kasamOrder].displayStatus = statusPercent.1
                    count += 1
                })
            } else if kasam.repeatDuration > 1 {
                //GET REPEATED KASAM PERCENT COMPLETE AND DAYTRACKERS
                let kasamOrder = kasam.kasamOrder
                var dayCount = 0
                var percentComplete = 0.0
                //Checks if there's kasam history
                DBRef.userHistory.child(kasam.kasamID).observeSingleEvent(of: .value, with: {(snap) in
                    if snap.exists() {
                        dayCount = Int(snap.childrenCount)
                        var dayTrackerArrayInternal = [Int:(Int, Double)]()
                        var dayPercent = 1.0
                        //Gets the DayTracker info - only goes into this loop if the user has kasam history
                        self.dayTrackerRefHandle = DBRef.userHistory.child(kasam.kasamID).observe(.childAdded, with: {(snap) in
                            let kasamDate = self.stringToDate(date: snap.key)
                            if kasamDate >= kasam.joinedDate {
                                let order = (Calendar.current.dateComponents([.day], from: kasam.joinedDate, to: kasamDate)).day! + 1
                                self.dayTrackerDateArray[order] = snap.key              //to save the Kasam date and order
                                let statusPercent = self.statusPercentCalc(snapshot: snap)
                                dayPercent = statusPercent.0
                                
                                //dayTrackerDateArray is correct
                                SavedData.dayTrackerDict[kasam.kasamID] = self.dayTrackerDateArray      //saves the progress for detailed stats
                                dayTrackerArrayInternal[order] = (order, dayPercent)  //places gold dots on right day in the todayBlockTracker
                            } else {
                                dayCount -= 1
                            }
                            //Status for Current day
                            if snap.key == self.getCurrentDate() {
                                percentComplete = dayPercent
                                if dayPercent == 1 {displayStatus = "Check"}
                                else if dayPercent < 1 && dayPercent > 0 {displayStatus = "Progress"}
                            }
                            //Daycount is the number of days the kasam has been active for the user
                            //DayTrackerArrayInternal adds the status of each day
                            if dayTrackerArrayInternal.count == dayCount && dayCount >= 0 && kasamOrder < self.kasamBlocks.count {
                                self.kasamBlocks[kasamOrder].displayStatus = displayStatus
                                //percent complete only captured for today to show for complex Kasams
                                self.kasamBlocks[kasamOrder].percentComplete = percentComplete
                                self.kasamBlocks[kasamOrder].dayTrackerArray = dayTrackerArrayInternal
                                let streakInfo = self.currentStreak(dictionary: dayTrackerArrayInternal, currentDay: self.kasamBlocks[kasamOrder].dayOrder)
                                self.kasamBlocks[kasamOrder].currentStreak = streakInfo.0
                                self.kasamBlocks[kasamOrder].totalDaysCompleted = streakInfo.2
                                SavedData.kasamDict[kasam.kasamID]?.badgeStreak = streakInfo.1
                                self.dayTrackerDateArray.removeAll()
                                DBRef.userHistory.child(kasam.kasamID).removeAllObservers()
                                count += 1
                                
                                //refreshes tableview once all kasam day trackers are loaded
                                if kasamID == nil {
                                    //updating all the kasams on the today page
                                    if count == SavedData.kasamTodayArray.count {
                                        self.tableView.reloadData()
                                        self.challengesColletionView.reloadData()
                                        self.updateContentTableHeight()
                                    }
                                } else {
                                    //updating a single kasam after a preference change
                                    if let cell = self.tableView.cellForRow(at: IndexPath(item: kasamOrder, section: 0)) as? TodayBlockCell {
                                        cell.setBlock(block: self.kasamBlocks[kasamOrder])
                                        cell.dayTrackerCollectionView.reloadData()
                                        self.updateContentTableHeight()
                                    } else if let cell = self.challengesColletionView.cellForItem(at: IndexPath(item: kasamOrder, section: 0)) as? TodayChallengesCell {
                                        cell.setBlock(challenge: self.challengeBlocks[kasamOrder])
                                        self.updateContentTableHeight()
                                    }
                                }
                
                            }
                        })
                    } else {
                        //no history recorded in Firebase
                        if kasamOrder < self.kasamBlocks.count {
                            count += 1
                            self.kasamBlocks[kasamOrder].displayStatus = "Checkmark"
                            self.kasamBlocks[kasamOrder].dayTrackerArray = [0: (0,0.0)]
                            self.kasamBlocks[kasamOrder].currentStreak = self.currentStreak(dictionary: [0:(0,0.0)], currentDay: self.kasamBlocks[kasamOrder].dayOrder).0
                            self.dayTrackerDateArray.removeAll()
                            if count == SavedData.kasamTodayArray.count {
                                self.tableView.reloadData()
                                self.challengesColletionView.reloadData()
                            }
                        }
                    }
                })
            }
        }
    }
    
    func longestStreak(dictionary: [Int:(Int, Bool)]) -> Int {
        var streak = [0]
        var currentValue = 0
        var pastValue: Int?
        let sortedArray = dictionary.sorted{ $0.key < $1.key }
        for arrayValue in sortedArray {
            pastValue = currentValue
            currentValue = arrayValue.value.0
            if (currentValue - pastValue! == 1) && arrayValue.value.1 == true {
                streak[streak.count - 1] += 1
            } else {
                streak += [0]
            }
        }
        let longestStreak = streak.max() ?? 0
        return longestStreak
    }
    
    //STEP 4B
    func currentStreak(dictionary: [Int:(Int, Double)], currentDay: Int) -> (Int, Int, Int) {
        var daysWithAnyProgress = 0
        var daysWithCompleteProgress = 0
        var currentStreak = 0
        var currentStreakCompleteProgress = 0
        var anyProgressCheck = 0
        var completeProgressCheck = 0
        //currentStreak
        for day in stride(from: currentDay, through: 1, by: -1) {
            if dictionary[day] != nil {
                daysWithAnyProgress += 1
                if dictionary[day]!.1 == 1.0 {
                    daysWithCompleteProgress += 1                                   //all days with 100% progress
                } else if completeProgressCheck == 0 {
                    currentStreakCompleteProgress = daysWithCompleteProgress        //current streak days with 100% progress
                    completeProgressCheck = 1
                }
            } else if day != currentDay {
                if anyProgressCheck == 0 {
                    currentStreak = daysWithAnyProgress
                    currentStreakCompleteProgress = daysWithCompleteProgress        //current streak days with 100% progress
                }
                anyProgressCheck = 1
            }
        }
        if anyProgressCheck == 0 {                                                  //in case all days have some progress
            currentStreak = daysWithAnyProgress
            if currentStreakCompleteProgress == 0 {
                currentStreakCompleteProgress = daysWithCompleteProgress
            }
        }
        return (currentStreak, currentStreakCompleteProgress, daysWithAnyProgress)
    }
    
    //---------------------------------------------------------------------------------------------------------
    
    //When the Today Block checkmark buttons are pressed
    func updateKasamButtonPressed(_ sender: UIButton, kasamOrder: Int){
        let block = kasamBlocks[kasamOrder]
        let statusDate = getCurrentDate()!
        if sender.tag == 1 {
            if block.displayStatus == "Check" {
                DBRef.userHistory.child(block.kasamID ).child(statusDate).setValue(nil)
            } else {
                DBRef.userHistory.child(block.kasamID).child(statusDate).setValue(1)
            }
        } else if sender.tag == 0 {
            if block.displayStatus == "Uncheck" {
                DBRef.userHistory.child(block.kasamID ).child(statusDate).setValue(nil)
            } else {
                DBRef.userHistory.child(block.kasamID).child(statusDate).setValue(0)
                
            }
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "KasamStatsUpdate"), object: self)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateTodayBlockStatus"), object: self, userInfo: ["kasamID": block.kasamID])
    }
    
    //BASIC KASAMS - When the Today Block DayTracker Day Buttons are pressed
    func updateKasamDayButtonPressed(_sender: UIButton, kasamOrder: Int, day: Int){
        let block = kasamBlocks[kasamOrder]
        if SavedData.kasamDict[block.kasamID]?.badgeThresholds == nil {
            DBRef.coachKasams.child(block.kasamID).child("Badges").observeSingleEvent(of: .value) {(snap) in
                if snap.exists() {SavedData.kasamDict[block.kasamID]?.badgeThresholds = (snap.value as? String)?.components(separatedBy: ";")} else {
                    SavedData.kasamDict[block.kasamID]?.badgeThresholds = ["10","30","90"]
                }
            }
        }
        let daydiff = block.dayOrder - day
        var status = "Checkmark"
        let dateToUpdate = Calendar.current.date(byAdding: .day, value: -daydiff, to: Date())!
        let statusDate = dateFormat(date: dateToUpdate)
        if self.kasamBlocks[kasamOrder].dayTrackerArray![day] != nil {
            if self.kasamBlocks[kasamOrder].dayTrackerArray?[day]?.1 == 1.0 {
                DBRef.userHistory.child(block.kasamID).child(statusDate).setValue(nil)
            }
        } else {
            DBRef.userHistory.child(block.kasamID).child(statusDate).setValue(1)
            status = "Check"
        }
        //if the status of today is changed, update the display status
        if day == Int(block.dayOrder) {
            block.displayStatus = status
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "KasamStatsUpdate"), object: self)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateTodayBlockStatus"), object: self, userInfo: ["kasamID": block.kasamID, "date": statusDate])
    }
    
    //CHALLENGE KASAMS - only updates the kasam where progress was made from KasamViewer
    @objc func updateKasamStatus(_ notification: NSNotification) {
        if let kasamID = notification.userInfo?["kasamID"] as? String {
            let kasamOrder = (SavedData.kasamDict[kasamID]!.kasamOrder)
            var statusDate = getCurrentDate()!
            if notification.userInfo?["date"] != nil {statusDate = notification.userInfo?["date"] as! String}
            let updateDayTrackerRef = DBRef.userHistory.child(kasamID).child(statusDate)
            updateDayTrackerRef.observe(.value, with: {(snapshot) in
                if SavedData.kasamDict[kasamID]?.repeatDuration ?? 2 > 1 {
                    //FOR UPDATING REPEATED KASAM
                    let kasamDate = self.stringToDate(date: snapshot.key)
                    let dayOrder = (Calendar.current.dateComponents([.day], from: SavedData.kasamDict[kasamID]!.joinedDate, to: kasamDate)).day! + 1
                   
                    //STEP 1 - Updates the DayTracker
                    if snapshot.exists() {
                        let statusPercent = self.statusPercentCalc(snapshot: snapshot)
                        self.kasamBlocks[kasamOrder].dayTrackerArray?[dayOrder] = (dayOrder, statusPercent.0)
                        
                        //Update today's percentage if today's activity being updated
                        if statusDate == self.getCurrentDate()! {
                            self.kasamBlocks[kasamOrder].percentComplete = statusPercent.0
                            self.kasamBlocks[kasamOrder].displayStatus = statusPercent.1
                        }
                    } else {
                        //removes the dayTracker for today if kasam is set to zero
                        if let index = self.kasamBlocks[kasamOrder].dayTrackerArray?.firstIndex(where: {$0.0 == dayOrder}) {
                            self.kasamBlocks[kasamOrder].dayTrackerArray?.remove(at: index)
                        }
                    }
                    //STEP 2 - Get the current streak based on the updated daytracker
                    if self.kasamBlocks[kasamOrder].dayTrackerArray != nil {
                        let streak = self.currentStreak(dictionary: self.kasamBlocks[kasamOrder].dayTrackerArray!, currentDay: self.kasamBlocks[kasamOrder].dayOrder)
                        self.kasamBlocks[kasamOrder].currentStreak = streak.0
                        SavedData.kasamDict[kasamID]!.badgeStreak = streak.1
                        self.kasamBlocks[kasamOrder].totalDaysCompleted = streak.2
                    }
                    SavedData.dayTrackerDict[kasamID]?[dayOrder] = snapshot.key
                    if let cell = self.tableView.cellForRow(at: IndexPath(item: kasamOrder, section: 0)) as? TodayBlockCell {
                        self.tableView.beginUpdates()
                        cell.statusUpdate()
                        cell.dayTrackerCollectionView.reloadData()
                        self.tableView.endUpdates()
                    }
                    updateDayTrackerRef.removeAllObservers()
                } else {
                    //FOR UPDATING CHALLENGE KASAMS
                    let statusPercent = self.statusPercentCalc(snapshot: snapshot)
                    self.challengeBlocks[kasamOrder].percentComplete = statusPercent.0
                    self.challengeBlocks[kasamOrder].displayStatus = statusPercent.1
                    if let cell = self.challengesColletionView.cellForItem(at: IndexPath(item: kasamOrder, section: 0)) as? TodayChallengesCell {
                        cell.statusUpdate()
                    }
                }
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
            displayStatus = "Uncheck"
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
            return kasamBlocks.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodayKasamCell") as! TodayBlockCell
        if noKasamTracker == 1 {
            cell.setPlaceholder()
        } else {
            cell.removePlaceholder()
            cell.row = indexPath.row
            cell.cellDelegate = self
            let block = kasamBlocks[indexPath.row]
            cell.setBlock(block: block)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tableViewCell = cell as? TodayBlockCell else { return }
        tableViewCell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.row)
        tableViewCell.cellFormatting()
        tableViewCell.completionBadge.play()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let height = UITableView.automaticDimension
        return height
    }
    
    func goToKasamHolder(_ sender: UIButton, kasamOrder: Int) {
        kasamIDforHolder = kasamBlocks[kasamOrder].kasamID
        self.performSegue(withIdentifier: "goToKasamHolder", sender: kasamOrder)
    }
    
    func completeAndUnfollow(_ sender: UIButton, kasamOrder: Int) {
        let popupImage = UIImage.init(icon: .fontAwesomeSolid(.rocket), size: CGSize(width: 30, height: 30), textColor: .white)
        showPopupConfirmation(title: "Complete & Unfollow?", description: "You'll be unfollowing this Kasam, but your past progress will be saved", image: popupImage, buttonText: "Complete & Unfollow", completion: {(success) in
            let kasamID = self.kasamBlocks[kasamOrder].kasamID
            let kasamJoinDate = self.dateFormat(date: SavedData.kasamDict[kasamID]?.joinedDate ?? Date())
            DBRef.userKasamFollowing.child(kasamID).child("Past Join Dates").child(kasamJoinDate).setValue(SavedData.kasamDict[kasamID]?.repeatDuration)
            DBRef.userKasamFollowing.child(kasamID).child("Status").setValue("completed")
            self.getPreferences()
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
            return challengeBlocks.count
        } else {
            //for Kasam DayTracker
            if self.kasamBlocks.count > collectionView.tag {        //ensures the kasam is loaded before reading the dayTracker
                return self.kasamBlocks[collectionView.tag].repeatDuration
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
            return CGSize(width: collectionViewHeight, height: collectionViewHeight)
        } else {
            return CGSize(width: 30, height: 50)
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
            let block = challengeBlocks[indexPath.row]
            cell.cellDelegate = self
            cell.row = indexPath.row
            cell.cellFormatting()
            cell.setBlock(challenge: block)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DayTrackerCell", for: indexPath) as! TodayDayTrackerCell
            if self.kasamBlocks.count > collectionView.tag {
                cell.dayTrackerDelegate = self
                let kasamBlock = self.kasamBlocks[collectionView.tag]
                let day = indexPath.row + 1
                let today = Int(kasamBlock.dayOrder)
                let future = day > today
                let date = dayTrackerDateFormat(date: Date(), todayDay: today, row: indexPath.row + 1)
                if kasamBlock.dayTrackerArray?[indexPath.row + 1] != nil {
                    let block = kasamBlock.dayTrackerArray![indexPath.row + 1]
                    //set green and black dots for day tracker
                    cell.setBlock(kasamOrder: collectionView.tag, day: day, status: block?.1 ?? 0.0, date: date, type: kasamBlock.kasamType, today: day == today, future: future)
                } else {
                    //grey out day tracker
                    cell.setBlock(kasamOrder: collectionView.tag, day: day, status: 0.0, date: date, type: kasamBlock.kasamType, today: day == today, future: future)
                }
            }
            return cell
        }
    }
    
    func goToChallengeKasamHolder(_ sender: UIButton, kasamOrder: Int) {
        kasamIDforHolder = challengeBlocks[kasamOrder].kasamID
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
            loadingAnimation(animationView: animationView, animation: "loading", height: 100, overlayView: nil, loop: true, completion: nil)
            UIApplication.shared.beginIgnoringInteractionEvents()
            kasamIDforViewer = challengeBlocks[indexPath.row].kasamID
            blockIDGlobal = challengeBlocks[indexPath.row].blockID
            dayOrderGlobal = challengeBlocks[indexPath.row].dayOrder
            performSegue(withIdentifier: "goToKasamActivityViewer", sender: indexPath)
        }
    }
    
    func dayPressed(_ sender: UIButton, kasamOrder: Int, day: Int, type: String) {
        if day <= self.kasamBlocks[kasamOrder].dayOrder {
            if type == "Basic" {
                updateKasamDayButtonPressed(_sender: sender, kasamOrder: kasamOrder, day: day)
            } else {
                openKasamBlock(sender, kasamOrder: kasamOrder, day: day)
            }
        }
    }
    
    func openKasamBlock(_ sender: UIButton, kasamOrder: Int, day: Int?) {
        loadingAnimation(animationView: animationView, animation: "loading", height: 100, overlayView: nil, loop: true, completion: nil)
        UIApplication.shared.beginIgnoringInteractionEvents()
        let kasamID = kasamBlocks[kasamOrder].kasamID
        kasamIDforViewer = kasamID
        blockIDGlobal = kasamBlocks[kasamOrder].blockID
        dayOrderGlobal = kasamBlocks[kasamOrder].dayOrder
        if day != nil {
            //opening a past day's block
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
                        self.blockIDGlobal = value["BlockID"] as? String ?? self.kasamBlocks[kasamOrder].blockID
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
