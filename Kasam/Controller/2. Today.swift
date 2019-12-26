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
    @IBOutlet weak var contentView: NSLayoutConstraint!
    
    var kasamBlocks: [TodayBlockFormat] = []
    var motivationArray: [motivationFormat] = []
    var motivationBackground: [String] = []
    var blockURLGlobal = ""
    var dateSelected = ""
    var kasamIDGlobal = ""
    var blockIDGlobal = ""
    var dayOrderGlobal = ""
    let semaphore = DispatchSemaphore(value: 1)
    var kasamFollowingRef: DatabaseReference! = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Kasam-Following")
    var kasamFollowingRefHandle: DatabaseHandle!
    let motivationRef = Database.database().reference().child("Assets").child("Motivation Images")
    var motivationRefHandle: DatabaseHandle!
    let dayTrackerRef = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("History")
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
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        motivationRef.removeObserver(withHandle: motivationRefHandle)
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
    
    //Table Resizing----------------------------------------------------------------------------------------
    
    func updateContentTableHeight(){
        //set the table row height, based on the screen size
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150
        
        //sets the height of the whole tableview, based on the numnber of rows
        tableView.frame = CGRect(x: tableView.frame.origin.x, y: tableView.frame.origin.y, width: tableView.frame.size.width, height: tableView.contentSize.height)
         self.tableViewHeight.constant = self.tableView.contentSize.height
        
        //elongates the entire scrollview, based on the tableview height
        let frame = self.view.safeAreaLayoutGuide.layoutFrame
        let contentViewHeight = tableViewHeight.constant + 210 + 35         //25 is the additional space from the bottom
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
        kasamFollowingRef.observeSingleEvent(of: .value, with:{(snap) in
            var kasamOrder = 0
            var count = Int(snap.childrenCount)
            if count == 0 {
                //not following any kasams
                self.noKasamTracker = 1
                self.tableView.reloadData()
                self.tableView.hideSkeleton(transition: .crossDissolve(0.25))
            }
            self.kasamFollowingRefHandle = self.kasamFollowingRef.observe(.childAdded) {(snapshot) in
                //Get Kasams from user following + their preference for each kasam
                if let value = snapshot.value as? [String: Any] {
                    let kasamID = snapshot.key
                    let kasamName = value["Kasam Name"] as? String ?? ""
                    let dateJoined = self.stringToDate(date: value["Date Joined"] as? String ?? "")
                    let startTime = value["Time"] as? String ?? ""
                    let kasamEndDate = Calendar.current.date(byAdding: .day, value: 30, to: dateJoined)!
                        var status = "active"
                        if Date() < dateJoined {status = "inactive"}
                        if Date() >= kasamEndDate {status = "completed"}
                    let preference = KasamSavedFormat(kasamID: kasamID, kasamName: kasamName, joinedDate: dateJoined, endDate: kasamEndDate, startTime: startTime, kasamOrder: kasamOrder, image: nil, metricType: nil, status: status)
                    if status == "active" {
                        kasamOrder += 1
                        SavedData.kasamTodayArray.append(preference)
                    } else {
                        count -= 1
                    }
                    SavedData.addKasam(kasam: preference)
                    if SavedData.kasamTodayArray.count == count {
                        self.retrieveKasams()
                        self.getDayTracker()
                        //update the user profile page
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "ChalloStatsUpdate"), object: self)
                        self.kasamFollowingRef.removeObserver(withHandle: self.kasamFollowingRefHandle)
                    }
                }
            }
        })
    }
    
    @objc func retrieveKasams() {
        self.kasamBlocks.removeAll()
        var todayKasamCount = 0
        for kasam in SavedData.kasamTodayArray {
            var dayOrder = 0
            //Seeing which blocks are needed for the day
            if kasam.status == "inactive" || kasam.status == "completed" {
                todayKasamCount += 1
            } else if kasam.status == "active" {
                todayKasamCount += 1
                dayOrder = ((Calendar.current.dateComponents([.day], from: kasam.joinedDate, to: Date()).day!) + 1)
                //Finds out which block should be called based on the day of the kasam the user is on
                Database.database().reference().child("Coach-Kasams").child(kasam.kasamID).child("Blocks").observeSingleEvent(of: .value, with: { blockCountSnapshot in
                    let blockCount = Int(blockCountSnapshot.childrenCount)
                    var blockOrder = "1"
                    if dayOrder <= blockCount {
                        blockOrder = String(dayOrder)
                    } else {
                        blockOrder = String((blockCount / dayOrder) + 1)
                    }
                    
                    //Gets the blockdata after the block is decided on
                    Database.database().reference().child("Coach-Kasams").child(kasam.kasamID).child("Blocks").queryOrdered(byChild: "Order").queryEqual(toValue : blockOrder).observeSingleEvent(of: .childAdded, with: { snapshot in
                        let value = snapshot.value as! Dictionary<String,Any>
                        let block = TodayBlockFormat(kasamOrder: kasam.kasamOrder, kasamID: kasam.kasamID, blockID: value["BlockID"] as? String ?? "", kasamName: kasam.kasamName, title: value["Title"] as! String, dayOrder: String(dayOrder), duration: value["Duration"] as! String, image: URL(string: value["Image"] as! String) ?? self.placeholder() as! URL, statusType: "", displayStatus: "Checkmark", dayTrackerArray: nil)
                        self.kasamBlocks.append(block)
                        self.kasamBlocks = self.kasamBlocks.sorted(by: {$0.kasamOrder < $1.kasamOrder})
                        SavedData.kasamTodayArray = SavedData.kasamTodayArray.sorted(by: { $0.kasamOrder < $1.kasamOrder })
                        if todayKasamCount == SavedData.kasamTodayArray.count {
                            //now know how many rows are there, so update table height and hide skeleton
                            self.tableView.reloadData()
                            self.updateContentTableHeight()
                            self.tableView.hideSkeleton(transition: .crossDissolve(0.25))
                        }
                    })
                })
            }
        }
    }
    
    func getDayTracker() {
        //for the active Challos on the Today page
        for kasam in SavedData.kasamTodayArray {
            self.dayTrackerDateArray.removeAll()
            let kasamOrder = kasam.kasamOrder
            let dayTrackerKasamRef = self.dayTrackerRef.child(kasam.kasamID)
            let currentDate = self.getCurrentDate()
            var dayCount = 0

            //Checks if there's kasam history
            self.dayTrackerRef.child(kasam.kasamID).observeSingleEvent(of: .value, with: {(snap) in
                dayCount = Int(snap.childrenCount)
                var dayTrackerArrayInternal = [Int]()
                    //Gets the DayTracker info - only goes into this loop if the user has kasam history
                    self.dayTrackerRefHandle = dayTrackerKasamRef.observe(.childAdded, with: {(snap) in
                        let kasamDate = self.stringToDate(date: snap.key)
                        if kasamDate >= kasam.joinedDate {
                            let order = (Calendar.current.dateComponents([.day], from: kasam.joinedDate, to: kasamDate)).day! + 1
                            self.dayTrackerDateArray[order] = snap.key          //to save the Challo date and order
                            dayTrackerArrayInternal.append(order)               //places the gold dots on the right day in the today block tracker
                        } else {
                            dayCount -= 1
                        }
                        //Checks if user has completed Kasam for the current day
                        var displayStatus = "Checkmark"
                        if snap.key == currentDate {
                            let dictionary = snap.value as! Dictionary<String,Any>
                            let value = dictionary["Metric Percent"] as! Double
                            if value >= 1 {
                                displayStatus = "Check"            //Challo has been completed today
                            } else {
                                displayStatus = "Progress"         //Challo has been started, but not completed
                        }
                    }
                    if dayTrackerArrayInternal.count == dayCount && dayCount > 0 && kasamOrder < self.kasamBlocks.count {
                        self.kasamBlocks[kasamOrder].displayStatus = displayStatus
                        self.kasamBlocks[kasamOrder].dayTrackerArray = dayTrackerArrayInternal
                        SavedData.addDayTracker(kasam: kasam.kasamID, dayTrackerArray: self.dayTrackerDateArray)
                        dayTrackerKasamRef.removeAllObservers()
                        self.tableView.reloadData()
                    }
                })
            })
        }
        //for the inactive kasams that are completed
        for kasam in SavedData.kasamArray {
            if kasam.status == "inactive" {
                let dayTrackerKasamRef = self.dayTrackerRef.child(kasam.kasamID)
                var dayCount = 0
                //Checks if there's kasam history
                self.dayTrackerRef.child(kasam.kasamID).observeSingleEvent(of: .value, with: {(snap) in
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
                            SavedData.addDayTracker(kasam: kasam.kasamID, dayTrackerArray: self.dayTrackerDateArray)
                            dayTrackerKasamRef.removeAllObservers()
                        }
                    })
                })
            }
        }
    }
    
    @objc func updateKasamStatus(_ notification: NSNotification) {
        //only updates the kasam where progress was made from KasamView
        if let kasamID = notification.userInfo?["kasamID"] as? String {
            let kasam = SavedData.kasamDict[kasamID]
            let kasamOrder = (SavedData.kasamDict[kasamID]!.kasamOrder)
            //Updates the DayTracker
            self.dayTrackerRefHandle = self.dayTrackerRef.child(kasamID).child(getCurrentDate() ?? "").observe(.value, with: {(snapshot) in
                let kasamDate = self.stringToDate(date: snapshot.key)
                let dayOrder = (Calendar.current.dateComponents([.day], from: kasam!.joinedDate, to: kasamDate)).day! + 1
               
                //Updates the KasamStatus
                self.dayTrackerRef.child(kasamID).child(self.getCurrentDate() ?? "").child("Metric Percent").observeSingleEvent(of: .value, with: {(snap) in
                    var displayStatus = "Checkmark"
                    if let value = snap.value as? Double {
                        if value >= 1 {
                            displayStatus = "Check"        //Kasam has been completed today
                            Analytics.logEvent("completed_Challo", parameters: nil)
                        } else if value < 1 {
                            displayStatus = "Progress"     //kasam has been started, but not completed
                            Analytics.logEvent("working_Challo", parameters: ["metric_percent": value.rounded(toPlaces: 2)])
                        }
                    }
                    if snapshot.exists() {
                        //if there's progress for today, it adds it to the dayTracker
                        self.kasamBlocks[kasamOrder].dayTrackerArray?.append(dayOrder)
                    } else {
                        //removes the dayTracker for today if kasam is set to zero
                        while let index = self.kasamBlocks[kasamOrder].dayTrackerArray?.index(of: dayOrder) {
                            self.kasamBlocks[kasamOrder].dayTrackerArray!.remove(at: index)
                        }
                    }
                    self.kasamBlocks[kasamOrder].displayStatus = displayStatus
                    SavedData.dayTrackerDict[kasamID]?[dayOrder] = snapshot.key
                    self.tableView.reloadData()
                    self.tableView.beginUpdates()
                    self.tableView.endUpdates()
                })
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
                motivationRefHandle = motivationRef.observe(.childAdded) { (snapshot) in
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
        self.motivationRefHandle = self.motivationRef.observe(.childAdded) {(snap) in
            let motivationURL = snap.value as! String
            self.motivationBackground.append(motivationURL)
            self.todayMotivationCollectionView.reloadData()
        }
    }
    
    @objc func editMotivation(_ notification: NSNotification){
        if let motivationID = notification.userInfo?["motivationID"] as? String {
            let attributes = FormFieldPresetFactory.attributes()
            changeMotivationPopup(attributes: attributes, style: .light, motivationID: motivationID)
        }
    }
    
    private func changeMotivationPopup(attributes: EKAttributes, style: FormStyle, motivationID: String) {
        let titleStyle = EKProperty.LabelStyle(font: UIFont.systemFont(ofSize: 15), color: .standardContent, alignment: .center, displayMode: .light)
        let title = EKProperty.LabelContent(text: "Add your motivation!", style: titleStyle)
        let textFields = FormFieldPresetFactory.fields(by: [.motivation], style: style)
        let button = EKProperty.ButtonContent(label: .init(text: "Continue", style: style.buttonTitle), backgroundColor: style.buttonBackground, highlightedBackgroundColor: style.buttonBackground.with(alpha: 0.8), displayMode: .light, accessibilityIdentifier: "continueButton") {
            let newMotivation = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Motivation")
            if motivationID == "" {
                newMotivation.childByAutoId().setValue(textFields[0].textContent) { (error, ref) -> Void in
                    self.getMotivations()
                }
            } else if motivationID != "" {
                newMotivation.child(motivationID).setValue(textFields[0].textContent) { (error, ref) -> Void in
                    self.getMotivations()
                }
            }
            SwiftEntryKit.dismiss()
        }
        let contentView = EKFormMessageView(with: title, textFieldsContent: textFields, buttonContent: button)
        SwiftEntryKit.display(entry: contentView, using: attributes)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToChalloActivityViewer" {
            let kasamActivityHolder = segue.destination as! ChalloActivityViewer
            kasamActivityHolder.kasamID = kasamIDGlobal
            kasamActivityHolder.blockID = blockIDGlobal
            kasamActivityHolder.dayOrder = dayOrderGlobal
        }
    }
}

//TableView---------------------------------------------------------------------------------------------------------------------

extension TodayBlocksViewController: SkeletonTableViewDataSource, UITableViewDataSource, UITableViewDelegate {
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
            cell.delegate = self
            cell.setBlock(block: block)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if noKasamTracker == 1{
            //go to Discover Page when clicked
            animateTabBarChange(tabBarController: self.tabBarController!, to: self.tabBarController!.viewControllers![0])
            self.tabBarController?.selectedIndex = 0
        } else {
            loadingAnimation(animationView: animationView, animation: "loading", height: 100, overlayView: nil, loop: true, completion: nil)
            UIApplication.shared.beginIgnoringInteractionEvents()
            kasamIDGlobal = kasamBlocks[indexPath.row].kasamID
            blockIDGlobal = kasamBlocks[indexPath.row].blockID
            dayOrderGlobal = kasamBlocks[indexPath.row].dayOrder
            performSegue(withIdentifier: "goToChalloActivityViewer", sender: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let height = UITableView.automaticDimension
        tableView.estimatedRowHeight = 125
        return height
    }
    
    //Skeleton View----------------------------------------------------------------------------------------------------------
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

//CollectionView------------------------------------------------------------------------------------------

extension TodayBlocksViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, SkeletonCollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        todayCollectionHeight.constant = (view.bounds.size.width * (2/5))
        return CGSize(width: (view.frame.size.width - 30), height: view.frame.size.width * (2/5))
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return motivationArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TodayMotivationCell", for: indexPath) as! TodayMotivationCell
        if indexPath.row < motivationBackground.count  {
            cell.backgroundImage.sd_setImage(with: URL(string: motivationBackground[indexPath.row]))
        } else {
             cell.backgroundImage.image = UIImage(named: "placeholder.png")
        }
        cell.motivationText.text = motivationArray[indexPath.row].motivationText
        cell.motivationID["motivationID"] = motivationArray[indexPath.row].motivationID
        return cell
    }
    
    //Skeleton View
    func collectionSkeletonView(_ skeletonView: UICollectionView, cellIdentifierForItemAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return "TodayMotivationCell"
    }
    
    func collectionSkeletonView(_ skeletonView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
}
