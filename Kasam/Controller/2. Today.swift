//
//  KasamCalendar.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-05-15.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Foundation
import FSCalendar
import Firebase
import SDWebImage
import Lottie
import SwiftEntryKit

class TodayBlocksViewController: UIViewController, FSCalendarDataSource, FSCalendarDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var todayMotivationCollectionView: UICollectionView!
    @IBOutlet weak var calendar: FSCalendar!
    @IBOutlet weak var calendarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var todayCollectionHeight: NSLayoutConstraint!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var contentView: NSLayoutConstraint!
    
    var kasamBlocks: [TodayBlockFormat] = []
    var kasamFollowingArray: [KasamSavedFormat] = []
    var motivationArray: [motivationFormat] = []
    var motivationBackground: [String] = []
    var blockURLGlobal = ""
    var dateSelected = ""
    var kasamIDGlobal = ""
    var blockIDGlobal = ""
    var dayOrderGlobal = ""
    let semaphore = DispatchSemaphore(value: 1)
    let animationView = AnimationView()
    var kasamFollowingRef: DatabaseReference! = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Kasam-Following")
    var kasamFollowingRefHandle: DatabaseHandle!
    let motivationRef = Database.database().reference().child("Assets").child("Motivation Images")
    var motivationRefHandle: DatabaseHandle!
    let dayTrackerRef = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("History")
    var dayTrackerRefHandle: DatabaseHandle!
    var dayTrackerArray = [Int]()

    fileprivate lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableAndHeader()
        navBarShadow()
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
        let retrieveKasams = NSNotification.Name("RetrieveKasams")
        NotificationCenter.default.addObserver(self, selector: #selector(TodayBlocksViewController.getPreferences), name: retrieveKasams, object: nil)
        let updateKasamStatus = NSNotification.Name("UpdateKasamStatus")
        NotificationCenter.default.addObserver(self, selector: #selector(TodayBlocksViewController.updateKasamStatus), name: updateKasamStatus, object: nil)
        let editMotivation = NSNotification.Name("EditMotivation")
        NotificationCenter.default.addObserver(self, selector: #selector(TodayBlocksViewController.editMotivation), name: editMotivation, object: nil)
    }
    
    func updateContentTableHeight(){
        tableViewHeight.constant = tableView.contentSize.height
        let frame = self.view.safeAreaLayoutGuide.layoutFrame
        let contentViewHeight = tableViewHeight.constant + 210 + 20
        if contentViewHeight > frame.height {
            contentView.constant = contentViewHeight
        } else if contentViewHeight <= frame.height {
            let diff = UIScreen.main.bounds.height - contentViewHeight
            contentView.constant = tableViewHeight.constant + diff + 140
        }
    }

    func setupTableAndHeader(){
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150
        tableView.reloadData()
    }

    deinit {
        print("\(#function)")
    }
    
    @objc func stopLoadingAnimation(){
        animationView.removeFromSuperview()
    }
    
    @objc func getPreferences() {
        kasamFollowingArray.removeAll()
        SavedData.clearKasamArray()
        kasamFollowingRef.observeSingleEvent(of: .value, with:{ (snap) in
        let count = Int(snap.childrenCount)
            self.kasamFollowingRefHandle = self.kasamFollowingRef.observe(.childAdded) { (snapshot) in
                //Get Kasams from user following + their preference for each kasam
                if let value = snapshot.value as? [String: Any] {
                    let kasamID = snapshot.key
                    let kasamTitle = value["Kasam Name"] as? String ?? ""
                    let dateJoined = self.dateConverter(datein: value["Date Joined"] as? String ?? "")
                    let startTime = value["Time"] as? String ?? ""
                    let preference = KasamSavedFormat(kasamID: kasamID, kasamName: kasamTitle, joinedDate: dateJoined, startTime: startTime)
                    self.kasamFollowingArray.append(preference)
                    SavedData.addKasam(kasam: preference)
                    if self.kasamFollowingArray.count == count {
                        self.retrieveKasams()
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "ChalloStatsUpdate"), object: self)
                        self.kasamFollowingRef.removeObserver(withHandle: self.kasamFollowingRefHandle)
                    }
                }
            }
        })
    }
    
    @objc func retrieveKasams() {
        self.kasamBlocks.removeAll()
        for kasam in self.kasamFollowingArray {
            var dayOrder = ""
            let currentDate = self.getCurrentDate()
            //Seeing which blocks are needed for the day
            if Date() >= kasam.joinedDate {
                dayOrder = String((Calendar.current.dateComponents([.day], from: kasam.joinedDate, to: Date()).day!) + 1)
                
                //Gets all the info for one block
                Database.database().reference().child("Coach-Kasams").child(kasam.kasamID).child("Blocks").queryOrdered(byChild: "Order").queryEqual(toValue : dayOrder).observeSingleEvent(of: .childAdded, with: { snapshot in
                    let value = snapshot.value as! Dictionary<String,Any>
                    var count = 0
                    
                    //Gets the DayTracker info
                    self.dayTrackerRef.child(kasam.kasamID).observeSingleEvent(of: .value, with: {(snap) in
                        count = Int(snap.childrenCount)
                    self.dayTrackerRefHandle = self.dayTrackerRef.child(kasam.kasamID).observe(.childAdded, with: {(snap) in
                        let kasamDate = self.dateConverter2(datein: snap.key)
                        let order = (Calendar.current.dateComponents([.day], from: kasam.joinedDate, to: kasamDate)).day! + 1
                        self.dayTrackerArray.append(order)
                    
                        //Checks if user has completed Kasam for the current day
                        var displayStatus = "Checkmark"
                        if snap.key == currentDate {
                            let dictionary = snap.value as! Dictionary<String,Any>
                            let value = dictionary["Metric Percent"] as! Double
                                if value >= 1 {
                                    displayStatus = "Check"            //Kasam has been completed today
                                } else {
                                    displayStatus = "Progress"         //kasam has been started, but not completed
                                }
                            }
                        
                        //once you have all the dayTracking info, transfer it to the today block
                        if self.dayTrackerArray.count == count {
                            let block = TodayBlockFormat(kasamID: kasam.kasamID, blockID: value["BlockID"] as? String ?? "", kasamName: kasam.kasamName, title: value["Title"] as! String, dayOrder: dayOrder, duration: value["Duration"] as! String, image: URL(string: value["Image"] as! String) ?? self.placeholder() as! URL, statusType: "", displayStatus: displayStatus, dayTrackerArray: self.dayTrackerArray)
                            self.kasamBlocks.append(block)
                            self.tableView.reloadData()
                            self.tableView.beginUpdates()
                            self.tableView.endUpdates()
                            self.updateContentTableHeight()
                            self.dayTrackerRef.removeObserver(withHandle: self.dayTrackerRefHandle)
                            self.dayTrackerArray.removeAll()
                            }
                        })
                    })
                })
            }
        }
    }
    
    @objc func updateKasamStatus() {
        for i in 0...(kasamBlocks.count - 1) {
            Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("History").child(self.kasamBlocks[i].kasamID).child(getCurrentDate() ?? "").child("Metric Percent").observeSingleEvent(of: .value, with: {(snap) in
                var displayStatus = "Checkmark"
                if let value = snap.value as? Double {
                    if value >= 1 {
                        displayStatus = "Check"        //Kasam has been completed today
                    } else if value < 1 {
                        displayStatus = "Progress"     //kasam has been started, but not completed
                    }
                } else {
                    displayStatus = "Checkmark"
                }
                self.kasamBlocks[i].displayStatus = displayStatus
                self.tableView.reloadData()
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            })
        }
    }
    
    func stopObserving(ref: AnyObject?, handle: DatabaseHandle?) {
        guard ref != nil else {
            print("Not observing")
            return
        }
        ref?.removeObserver(withHandle: handle!)
        print("Observer removed")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func dateConverter(datein: String) -> Date{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy"
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale.current
        let joinedDate = dateFormatter.date(from: datein)
        return joinedDate!
    }
    
    func dateConverter2(datein: String) -> Date{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale.current
        let joinedDate = dateFormatter.date(from: datein)
        return joinedDate!
    }
    
    func loadingAnimation(){
        animationView.animation = Animation.named("690-loading")
        animationView.contentMode = .scaleAspectFit
        view.addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.centerXAnchor.constraint(lessThanOrEqualTo: self.view.centerXAnchor).isActive = true
        animationView.centerYAnchor.constraint(lessThanOrEqualTo: self.view.centerYAnchor).isActive = true
        NSLayoutConstraint(item: animationView, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 100).isActive = true
        NSLayoutConstraint(item: animationView, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 100).isActive = true
        animationView.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        animationView.play()
        animationView.loopMode = .loop
    }
    
    func getMotivations(){
        motivationArray.removeAll()
        let motivationRef = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Motivation")
        var motivationRefHandle: DatabaseHandle!
        motivationRef.observeSingleEvent(of: .value, with:{ (snap) in
            let count = Int(snap.childrenCount)
            motivationRefHandle = motivationRef.observe(.childAdded) { (snapshot) in
                let motivation = motivationFormat(motivationID: snapshot.key, motivationText: snapshot.value as! String)
                self.motivationArray.append(motivation)
                if self.motivationArray.count == count {
                    self.motivationArray.append(motivationFormat(motivationID: "", motivationText: "Enter your personal motivation here!"))
                    motivationRef.removeObserver(withHandle: motivationRefHandle)
                    self.todayMotivationCollectionView.reloadData()
                }
            }
        })
    }
    
    func getMotivationBackgrounds(){
        self.motivationRefHandle = self.motivationRef.observe(.childAdded) {(snap) in
            let motivationURL = snap.value as! String
            self.motivationBackground.append(motivationURL)
        }
    }
    
    // Sign in form
    private func showSigninForm(attributes: EKAttributes, style: FormStyle, motivationID: String) {
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
    
    @objc func editMotivation(_ notification: NSNotification){
        if let motivationID = notification.userInfo?["motivationID"] as? String {
            let attributes = FormFieldPresetFactory.attributes()
            showSigninForm(attributes: attributes, style: .light, motivationID: motivationID)
        }
    }
}

extension TodayBlocksViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return kasamBlocks.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let height = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150
        return height
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let block = kasamBlocks[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "CalendarKasamBlock") as! TodayBlockCell
        cell.delegate = self
        if indexPath.row != kasamBlocks.count - 1 {
            cell.setBlock(block: block, end: false)
        } else {
            cell.setBlock(block: block, end: true)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        loadingAnimation()
        UIApplication.shared.beginIgnoringInteractionEvents()
        kasamIDGlobal = kasamBlocks[indexPath.row].kasamID
        blockIDGlobal = kasamBlocks[indexPath.row].blockID
        dayOrderGlobal = kasamBlocks[indexPath.row].dayOrder
        performSegue(withIdentifier: "goToKasamViewerTicker", sender: indexPath)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToKasamViewerTicker" {
            let kasamActivityHolder = segue.destination as! KasamViewerTicker
            kasamActivityHolder.kasamID = kasamIDGlobal
            kasamActivityHolder.blockID = blockIDGlobal
            kasamActivityHolder.dayOrder = dayOrderGlobal
        }
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

extension TodayBlocksViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return motivationArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TodayMotivationCell", for: indexPath) as! TodayMotivationCell
        cell.backgroundImage.sd_setImage(with: URL(string: motivationBackground[indexPath.row]), placeholderImage: UIImage(named: "placeholder.png"))
        cell.motivationText.text = motivationArray[indexPath.row].motivationText
        cell.motivationID["motivationID"] = motivationArray[indexPath.row].motivationID
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        todayCollectionHeight.constant = (view.bounds.size.width * (2/5))
        return CGSize(width: (view.frame.size.width - 30), height: view.frame.size.width * (2/5))
    }
}
