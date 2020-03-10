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

class TodayBlocksViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var todayMotivationCollectionView: UICollectionView!
    @IBOutlet weak var todayCollectionHeight: NSLayoutConstraint!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var challengesColletionView: UICollectionView!
    @IBOutlet weak var challengesCollectionHeight: NSLayoutConstraint!
    @IBOutlet weak var contentView: NSLayoutConstraint!
    
    var kasamBlocks: [TodayBlockFormat] = []
    var challengeBlocks: [TodayBlockFormat] = []
    var motivationArray: [motivationFormat] = []
    var motivationBackground: [String] = []
    var blockURLGlobal = ""
    var dateSelected = ""
    var kasamIDGlobal = ""
    var blockIDGlobal = ""
    var dayOrderGlobal = ""
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
        getMotivations()
        setupNotifications()
        printLocalNotifications()
    }
    
    //Center the day Tracker to today
    override func viewDidAppear(_ animated: Bool) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "CenterCollectionView"), object: self)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        DBRef.motivationImages.removeObserver(withHandle: motivationRefHandle)
    }
    
    func setupNotifications(){
        let stopLoadingAnimation = NSNotification.Name("RemoveLoadingAnimation")
        NotificationCenter.default.addObserver(self, selector: #selector(TodayBlocksViewController.stopLoadingAnimation), name: stopLoadingAnimation, object: nil)
        
        let retrieveKasams = NSNotification.Name("RetrieveTodayKasams")
        NotificationCenter.default.addObserver(self, selector: #selector(TodayBlocksViewController.getPreferences), name: retrieveKasams, object: nil)
        
        let updateKasamStatus = NSNotification.Name("UpdateTodayBlockStatus")
        NotificationCenter.default.addObserver(self, selector: #selector(TodayBlocksViewController.updateKasamStatus), name: updateKasamStatus, object: nil)
        
        let editMotivation = NSNotification.Name("EditMotivation")
        NotificationCenter.default.addObserver(self, selector: #selector(TodayBlocksViewController.editMotivation), name: editMotivation, object: nil)
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
        
            //35 is the additional space from the bottom
        let challengeCollectionPadding: CGFloat =  30
        let collectionViewSize = frame.size.width - challengeCollectionPadding
        collectionViewHeight = (collectionViewSize/2)
        let lenghtMultiplier = (Double(challengeBlocks.count) / 2.0).rounded()
        challengesCollectionHeight.constant = (collectionViewHeight * CGFloat(lenghtMultiplier)) + 40
        
        let contentViewHeight = tableViewHeight.constant + (challengesCollectionHeight.constant + 60) + 210 + 35
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
                    let kasamID = snapshot.key
                    let kasamName = value["Kasam Name"] as? String ?? ""
                    let currentDateJoined = self.stringToDate(date: value["Date Joined"] as? String ?? "")
                    let currentStartTime = value["Time"] as? String ?? ""
                    let currentEndDate = Calendar.current.date(byAdding: .day, value: 30, to: currentDateJoined)!
                        var currentStatus = "active"
                        if Date() < currentDateJoined {currentStatus = "inactive"}
                        if Date() >= currentEndDate {currentStatus = "completed"}
                    let pastKasamsCompleted = value["Past Join Dates"] as? [String: String]
                    var pastKasamDates = [String]()
                    if pastKasamsCompleted?.count != nil {
                        pastKasamDates = Array(pastKasamsCompleted!.keys)
                    }
                    let kasamType = value["Type"] as? String ?? ""
                    var order = 0
                    if kasamType == "Basic" {
                        order = kasamOrder
                    } else if kasamType == "Challenge" {
                        order = challengeOrder
                    }
                    let preference = KasamSavedFormat(kasamID: kasamID, kasamName: kasamName, joinedDate: currentDateJoined, endDate: currentEndDate, startTime: currentStartTime, kasamOrder: order, image: nil, metricType: nil, currentStatus: currentStatus, pastKasamJoinDates: pastKasamDates, type: kasamType)
                    if currentStatus == "active" {
                        if kasamType == "Basic" {
                            kasamOrder += 1
                        } else if kasamType == "Challenge" {
                            challengeOrder += 1
                        }
                        SavedData.kasamTodayArray.append(preference)
                    } else {
                        count -= 1
                    }
                    SavedData.addKasam(kasam: preference)                   //adds all kasams that the user is following
                    if SavedData.kasamTodayArray.count == count {
                        self.retrieveKasams()
                        self.getDayTracker()
                        //update the user profile page
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "KasamStatsUpdate"), object: self)
                        DBRef.userKasamFollowing.removeObserver(withHandle: self.kasamFollowingRefHandle)
                    }
                }
            }
        })
    }
    
    @objc func retrieveKasams() {
        self.kasamBlocks.removeAll()
        self.challengeBlocks.removeAll()
        var todayKasamCount = 0
        if SavedData.kasamTodayArray.count == 0 {                   //user is following Kasams that aren't active yet
            self.noKasamTracker = 1
            self.tableView.reloadData()
            self.tableView.hideSkeleton(transition: .crossDissolve(0.25))
        }
        for kasam in SavedData.kasamTodayArray {
            var dayOrder = 0
            //Seeing which blocks are needed for the day
            if kasam.currentStatus == "inactive" || kasam.currentStatus == "completed" {
                todayKasamCount += 1
            } else if kasam.currentStatus == "active" {
                todayKasamCount += 1
                dayOrder = ((Calendar.current.dateComponents([.day], from: kasam.joinedDate, to: Date()).day!) + 1)
                //Finds out which block should be called based on the day of the kasam the user is on
                DBRef.coachKasams.child(kasam.kasamID).child("Blocks").observeSingleEvent(of: .value, with: {(blockCountSnapshot) in
                    let blockCount = Int(blockCountSnapshot.childrenCount)
                    var blockOrder = "1"
                    if dayOrder <= blockCount {
                        blockOrder = String(dayOrder)
                    } else {
                        blockOrder = String((blockCount / dayOrder) + 1)
                    }
                    if kasam.type == "Basic" {
                        //it's a Basic Kasam
                        DBRef.coachKasams.child(kasam.kasamID).observe(.value) {(snapshot) in
                            if let value = snapshot.value as? [String: Any] {
                                let block = TodayBlockFormat(kasamOrder: kasam.kasamOrder, kasamID: kasam.kasamID, blockID: "", kasamName: kasam.kasamName, title: kasam.kasamName, dayOrder: String(dayOrder), duration: nil, image: URL(string: value["Image"] as? String ?? PlaceHolders.kasamLoadingImageURL)!, statusType: "", displayStatus: "Checkmark", dayTrackerArray: nil, currentStreak: nil)
                                self.kasamBlocks.append(block)
                                self.kasamBlocks = self.kasamBlocks.sorted(by: {$0.kasamOrder < $1.kasamOrder})
                                SavedData.kasamTodayArray = SavedData.kasamTodayArray.sorted(by: { $0.kasamOrder < $1.kasamOrder })
                                if todayKasamCount == SavedData.kasamTodayArray.count {
                                    self.tableView.reloadData()
                                    self.updateContentTableHeight()
                                    self.tableView.hideSkeleton(transition: .crossDissolve(0.25))
                                }
                            }
                        }
                    } else {
                        //It's a Challenge Kasam, so get the blockdata after the block order day is calculated
                        DBRef.coachKasams.child(kasam.kasamID).child("Blocks").queryOrdered(byChild: "Order").queryEqual(toValue : blockOrder).observeSingleEvent(of: .childAdded, with: {(snapshot) in
                            let value = snapshot.value as! Dictionary<String,Any>
                            let block = TodayBlockFormat(kasamOrder: kasam.kasamOrder, kasamID: kasam.kasamID, blockID: value["BlockID"] as? String ?? "", kasamName: kasam.kasamName, title: value["Title"] as! String, dayOrder: String(dayOrder), duration: value["Duration"] as? String, image: URL(string: value["Image"] as! String) ?? URL(string:PlaceHolders.kasamLoadingImageURL)!, statusType: "", displayStatus: "Checkmark", dayTrackerArray: nil, currentStreak: nil)
                            self.challengeBlocks.append(block)
                            self.challengeBlocks = self.challengeBlocks.sorted(by: {$0.kasamOrder < $1.kasamOrder})
                            SavedData.kasamTodayArray = SavedData.kasamTodayArray.sorted(by: { $0.kasamOrder < $1.kasamOrder })
                            if todayKasamCount == SavedData.kasamTodayArray.count {
                                self.challengesColletionView.reloadData()
                                self.updateContentTableHeight()
                                self.tableView.hideSkeleton(transition: .crossDissolve(0.25))
                            }
                        })
                    }
                })
            }
        }
    }
    
    func getDayTracker() {
        //for the active Kasams on the Today page
        for kasam in SavedData.kasamTodayArray {
            let kasamOrder = kasam.kasamOrder
            let currentDate = self.getCurrentDate()
            var dayCount = 0

            //Checks if there's kasam history
            DBRef.userHistory.child(kasam.kasamID).observeSingleEvent(of: .value, with: {(snap) in
                dayCount = Int(snap.childrenCount)
                var dayTrackerArrayInternal = [Int:(Int, Bool)]()
                    //Gets the DayTracker info - only goes into this loop if the user has kasam history
                    self.dayTrackerRefHandle = DBRef.userHistory.child(kasam.kasamID).observe(.childAdded, with: {(snap) in
                        let kasamDate = self.stringToDate(date: snap.key)
                        let status = snap.value as? Int == 1
                        if kasamDate >= kasam.joinedDate {
                            let order = (Calendar.current.dateComponents([.day], from: kasam.joinedDate, to: kasamDate)).day! + 1
                            self.dayTrackerDateArray[order] = snap.key              //to save the Kasam date and order
                            //dayTrackerDateArray is correct
                            SavedData.dayTrackerDict[kasam.kasamID] = self.dayTrackerDateArray      //saves the progress for detailed stats
                            dayTrackerArrayInternal[order] = (order, status)       //places the gold dots on the right day in the today block tracker
                        } else {
                            dayCount -= 1
                        }
                        //Checks if user has completed Kasam for the current day
                        var displayStatus = "Checkmark"
                        if snap.key == currentDate {
                            if snap.value as? Int == 1 {
                                displayStatus = "Check"
                            } else {
                                displayStatus = "Uncheck"
                            }
                            //for challenges
                            if let dictionary = snap.value as? Dictionary<String,Any> {
                                let value = dictionary["Metric Percent"] as? Double
                                if value ?? 0.0 < 1 {
                                    displayStatus = "Progress"         //Kasam has been started, but not completed
                                }
                            }
                        }
                    if kasam.type == "Challenge" {
                        if dayTrackerArrayInternal.count == dayCount && dayCount > 0 && kasamOrder <= self.kasamBlocks.count {
                            self.challengeBlocks[kasamOrder].displayStatus = displayStatus
                            //dayTrackerArrayInternal records in an array which days a kasam was completed e.g. [2,5,6,7,8]
                            self.challengeBlocks[kasamOrder].dayTrackerArray = dayTrackerArrayInternal
                            self.challengeBlocks[kasamOrder].currentStreak = self.currentStreak(dictionary: dayTrackerArrayInternal)
                            self.dayTrackerDateArray.removeAll()
                            DBRef.userHistory.child(kasam.kasamID).removeAllObservers()
                            self.tableView.reloadData()
                        }
                    } else {
                        if dayTrackerArrayInternal.count == dayCount && dayCount > 0 && kasamOrder < self.kasamBlocks.count {
                            self.kasamBlocks[kasamOrder].displayStatus = displayStatus
                            self.kasamBlocks[kasamOrder].dayTrackerArray = dayTrackerArrayInternal
                            self.kasamBlocks[kasamOrder].currentStreak = self.currentStreak(dictionary: dayTrackerArrayInternal)
                            self.dayTrackerDateArray.removeAll()
                            DBRef.userHistory.child(kasam.kasamID).removeAllObservers()
                            self.tableView.reloadData()
                        }
                    }
                })
            })
        }
        //for the inactive kasams that are completed
        for kasam in SavedData.kasamArray {
            if kasam.currentStatus == "inactive" {
                let dayTrackerKasamRef = DBRef.userHistory.child(kasam.kasamID)
                var dayCount = 0
                //Checks if there's kasam history
                DBRef.userHistory.child(kasam.kasamID).observeSingleEvent(of: .value, with: {(snap) in
                    var dayTrackerArray = [Int]()
                    dayCount = Int(snap.childrenCount)
                    //Gets the DayTracker info - only goes into this loop if the user has kasam history
                    self.dayTrackerRefHandle = dayTrackerKasamRef.observe(.childAdded, with: {(snap) in
                        let kasamDate = self.stringToDate(date: snap.key)
                        if kasamDate >= kasam.joinedDate {
                            let order = (Calendar.current.dateComponents([.day], from: kasam.joinedDate, to: kasamDate)).day! + 1
                            self.dayTrackerDateArray[order] = snap.key      //to save the kasam date and order
                            dayTrackerArray.append(order)              //gets the order to display what day it is for each kasam
                        } else {
                            dayCount -= 1
                        }
                        if dayTrackerArray.count == dayCount && dayCount > 0 {
                            SavedData.dayTrackerDict[kasam.kasamID] = self.dayTrackerDateArray
                            dayTrackerKasamRef.removeAllObservers()
                        }
                    })
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
    
    func currentStreak(dictionary: [Int:(Int, Bool)]) -> Int {
        var currentStreak = 0
        let sortedArray = dictionary.sorted{ $0.key < $1.key }
        for arrayValue in sortedArray.reversed() {
            if arrayValue.value.1 == false {
                break
            } else {
                currentStreak += 1
            }
        }
        return currentStreak
    }
    
    //When the Today Block checkmarks are pressed
    func updateKasamButtonPressed(_ sender: UIButton, kasamOrder: Int){
        let block = kasamBlocks[kasamOrder]
        let statusDate = getCurrentDate()
        if sender.tag == 1 {
            if block.displayStatus == "Check" {
                DBRef.userHistory.child(block.kasamID ).child(statusDate ?? "StatusDate").setValue(nil)
            } else {
                DBRef.userHistory.child(block.kasamID).child(statusDate ?? "StatusDate").setValue(1)
            }
        } else if sender.tag == 0 {
            if block.displayStatus == "Uncheck" {
                DBRef.userHistory.child(block.kasamID ).child(statusDate ?? "StatusDate").setValue(nil)
            } else {
                DBRef.userHistory.child(block.kasamID).child(statusDate ?? "StatusDate").setValue(0)
                
            }
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateTodayBlockStatus"), object: self, userInfo: ["kasamID": block.kasamID])
    }
    
    //When the Today Block DayTracker Day Buttons are pressed
    func updateKasamDayButtonPressed(_sender: UIButton, kasamOrder: Int, day: Int){
        let block = kasamBlocks[kasamOrder]
        let daydiff = Int(block.dayOrder)! - day
        var status = "Checkmark"
        let dateToUpdate = Calendar.current.date(byAdding: .day, value: -daydiff, to: Date())!
        let statusDate = dateFormat(date: dateToUpdate)
        if self.kasamBlocks[kasamOrder].dayTrackerArray![day] != nil {
            if self.kasamBlocks[kasamOrder].dayTrackerArray?[day]?.1 == true {
                DBRef.userHistory.child(block.kasamID).child(statusDate).setValue(0)
                status = "Uncheck"
            } else {
                DBRef.userHistory.child(block.kasamID).child(statusDate).setValue(nil)
            }
        } else {
            DBRef.userHistory.child(block.kasamID).child(statusDate).setValue(1)
            status = "Check"
        }
        //if the status of today is changed, update the display status
        if day == Int(block.dayOrder) {block.displayStatus = status}
        NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateTodayBlockStatus"), object: self, userInfo: ["kasamID": block.kasamID, "date": statusDate])
    }
    
    @objc func updateKasamStatus(_ notification: NSNotification) {
        //only updates the kasam where progress was made from KasamView
        var displayStatus = "Checkmark"
        if let kasamID = notification.userInfo?["kasamID"] as? String {
            let kasam = SavedData.kasamDict[kasamID]
            let kasamOrder = (SavedData.kasamDict[kasamID]!.kasamOrder)
            var statusDate = getCurrentDate() ?? ""
            if notification.userInfo?["date"] != nil {
                statusDate = notification.userInfo?["date"] as! String
            }
            let updateDayTrackerRef = DBRef.userHistory.child(kasamID).child(statusDate)
            updateDayTrackerRef.observe(.value, with: {(snapshot) in
                let kasamDate = self.stringToDate(date: snapshot.key)
                let dayOrder = (Calendar.current.dateComponents([.day], from: kasam!.joinedDate, to: kasamDate)).day! + 1
               
                if snapshot.exists() {
                    //STEP 1 - Updates the KasamStatus
                    if notification.userInfo?["date"] == nil {          //ensures displayStatus is only updated if TODAY's status is updated
                        if let dictionary = snapshot.value as? Dictionary<String,Any> {
                            let value = dictionary["Metric Percent"] as? Double
                            if value ?? 0.0 < 1 {
                                displayStatus = "Progress"         //Kasam has been started, but not completed
                                Analytics.logEvent("working_Kasam", parameters: ["metric_percent": value?.rounded(toPlaces: 2) ?? 0.0])
                            }
                        } else if snapshot.value as! Int == 1 {
                            displayStatus = "Check"
                            Analytics.logEvent("completed_Kasam", parameters: nil)
                        } else if snapshot.value as! Int == 0 {
                            displayStatus = "Uncheck"
                        }
                    }
                    
                    //STEP 2 - Updates the DayTracker
                    let status = (snapshot.value as? Int == 1)
                    self.kasamBlocks[kasamOrder].dayTrackerArray?[dayOrder] = (dayOrder, status)
                    
                } else {
                    //removes the dayTracker for today if kasam is set to zero
                    if let index = self.kasamBlocks[kasamOrder].dayTrackerArray?.firstIndex(where: {$0.0 == dayOrder}) {
                        self.kasamBlocks[kasamOrder].dayTrackerArray?.remove(at: index)
                    }
                }
                //get the current streak based on the updated daytracker
                if self.kasamBlocks[kasamOrder].dayTrackerArray != nil {
                    self.kasamBlocks[kasamOrder].currentStreak = self.currentStreak(dictionary: self.kasamBlocks[kasamOrder].dayTrackerArray!)
                }
                if notification.userInfo?["date"] == nil {self.kasamBlocks[kasamOrder].displayStatus = displayStatus}
                SavedData.dayTrackerDict[kasamID]?[dayOrder] = snapshot.key
                self.tableView.reloadData()
                updateDayTrackerRef.removeAllObservers()
            })
        }
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
        motivationRef.observeSingleEvent(of: .value, with:{ (snap) in
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
            kasamActivityHolder.kasamID = kasamIDGlobal
            kasamActivityHolder.blockID = blockIDGlobal
            kasamActivityHolder.dayOrder = dayOrderGlobal
        }
    }
}

//TableView-----------------------------------------------------------------------------------------------

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
            let block = kasamBlocks[indexPath.row]
            cell.row = indexPath.row
            cell.delegate = self
            cell.cellDelegate = self
            cell.setBlock(block: block)
            cell.reloadCollectionView()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tableViewCell = cell as? TodayBlockCell else { return }
        tableViewCell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let height = UITableView.automaticDimension
        return height
    }
    
    //Skeleton View----------------------------------------------------------------------
    func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return "TodayKasamCell"
    }
}

extension TodayBlocksViewController: TodayCellDelegate {
    func clickedButton(kasamID: String, blockID: String, status: String) {
        let statusDateTime = getCurrentDateTime()
        let statusDate = getCurrentDate()
        //Adds the status data as a subset of the Status
        if status == "Check" { Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("History").child(kasamID).child(statusDate ?? "StatusDate").updateChildValues(["Block Completed": blockID, "Time": statusDateTime ?? "StatusTime"]) {(error, reference) in}
        } else {
            Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("History").child(kasamID).child(statusDate ?? "StatusDateTime").removeValue()
        }
    }
}

//CollectionView------------------------------------------------------------------------

extension TodayBlocksViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, SkeletonCollectionViewDataSource, DayTrackerCellDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == todayMotivationCollectionView {
            return motivationArray.count
        } else if collectionView == challengesColletionView {
            return challengeBlocks.count
        } else {
            if self.kasamBlocks.count > collectionView.tag {        //ensures the kasam is loaded before reading the dayTracker
                let ratio: Double = ((Double(self.kasamBlocks[collectionView.tag].dayOrder)!) / 30.0).rounded(.up)
                return (Int(30 * ratio))
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
            //for the day tracker
            return CGSize(width: 30, height: 30)
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
            cell.cellFormatting()
            cell.setBlock(challenge: block)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DayTrackerCell", for: indexPath) as! TodayDayTrackerCell
            if self.kasamBlocks.count > collectionView.tag {
                cell.dayTrackerDelegate = self
                let day = indexPath.row + 1
                let today = Int(self.kasamBlocks[collectionView.tag].dayOrder)
                let future = day > today!
                cell.cellFormatting(today: day == today, future: future)
                if self.kasamBlocks[collectionView.tag].dayTrackerArray?[indexPath.row + 1] != nil {
                    let block = self.kasamBlocks[collectionView.tag].dayTrackerArray![indexPath.row + 1]
                    //set green and organe dots for day tracker
                    cell.setBlock(kasamOrder: collectionView.tag, day: day, status: block?.1)
                } else {
                    //grey out day tracker
                    cell.setBlock(kasamOrder: collectionView.tag, day: day, status: nil)
                }
            }
            return cell
        }
    }
    
    func dayPressed(_ sender: UIButton, kasamOrder: Int, day: Int) {
        if day > Int(self.kasamBlocks[kasamOrder].dayOrder)! {
            //do nothing, it's a future date so you can't click it to change status
        } else {
            updateKasamDayButtonPressed(_sender: sender, kasamOrder: kasamOrder, day: day)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView == todayMotivationCollectionView {
            return UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        } else if collectionView == challengesColletionView {
            return UIEdgeInsets(top: 0, left: 10, bottom: 10, right: 10)
        } else {
            return UIEdgeInsets(top: 0, left: 10, bottom: 10, right: 10)
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
            kasamIDGlobal = challengeBlocks[indexPath.row].kasamID
            blockIDGlobal = challengeBlocks[indexPath.row].blockID
            dayOrderGlobal = challengeBlocks[indexPath.row].dayOrder
            performSegue(withIdentifier: "goToKasamActivityViewer", sender: indexPath)
        }
    }
    
    //Skeleton View----------------------------------------------------------------------
    func collectionSkeletonView(_ skeletonView: UICollectionView, cellIdentifierForItemAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return "TodayMotivationCell"
    }
    
    func collectionSkeletonView(_ skeletonView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
}
