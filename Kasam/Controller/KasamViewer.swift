//
//  KasamViewer.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-09-05.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Firebase
import SwiftIcons

class KasamActivityViewer: UIViewController {
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var activityNumber: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var activityBlocks: [KasamActivityCellFormat] = []
    var kasamID = ""
    
    //determines which block and past history loads
    var blockID = ""
    var dayOrder = 0                    //
    var dayToLoad: Int?                 //for picking the correct block to show (for past and today days)
    
    var activityRef: DatabaseReference!
    var activityRefHandle: DatabaseHandle!
    var historyRef = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("History")
    var metricRef: DatabaseReference?
    var metricRefHandle: DatabaseHandle?
    var metricCompleted = 0
    var totalActivties = 0
    var summedTotalMetric = 0
    var transferMetricMatrix = [String: String]()
    var transferTextFieldMatrix = [String: String]()
    var viewingOnlyCheck = false
    var activityCurrentValue = 0
    var reviewOnly = false
    var statusDate = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getBlockActivities{self.setupMetricMatrix()}
        if reviewOnly == true {viewingOnlyCheck = true}
        setupButtons()
        self.hideKeyboardWhenTappedAround()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @IBAction func closeButton(_ sender: UIButton) {
        if viewingOnlyCheck == false {
            updateControllers()
        }
        dismiss(animated: true)
    }
    
    func updateControllers(){
        NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateTodayBlockStatus"), object: self, userInfo: ["kasamID":kasamID, "date":statusDate, "day": self.dayToLoad])
        NotificationCenter.default.post(name: Notification.Name(rawValue: "KasamStatsUpdate"), object: self)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "MainStatsUpdate"), object: self)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "RemoveLoadingAnimation"), object: self)
    }
    
    func setupButtons() {
        UIApplication.shared.endIgnoringInteractionEvents()
        closeButton?.setIcon(icon: .fontAwesomeSolid(.times), iconSize: 20, color: UIColor.init(hex: 0x79787e), forState: .normal)
    }
    
    func getBlockActivities(_ completion: @escaping () -> ()){
        activityBlocks.removeAll()
        var count = 0
        if reviewOnly == false {
            self.activityRef = DBRef.coachKasams.child(kasamID).child("Blocks").child(blockID).child("Activity")
            self.activityRefHandle = activityRef.observe(.childAdded) {(snapshot) in
                if let value = snapshot.value as? [String: Any] {
                    //check if user has past progress from today and download metric
                    if self.dayToLoad == nil {self.dayToLoad = self.dayOrder}      //in case DayToLoad isn't loaded
                    var diff = self.dayOrder - self.dayToLoad!
                    if SavedData.kasamDict[self.kasamID]?.repeatDuration == 0 {diff = 0}
                    if SavedData.kasamDict[self.kasamID]?.sequence == nil {
                        self.statusDate = self.dateFormat(date: Calendar.current.date(byAdding: .day, value: -diff, to: Date())!)
                    } else {
                        self.statusDate = self.dateFormat(date: SavedData.kasamDict[self.kasamID]?.dayTrackerArray?[self.dayToLoad!]?.0 ?? Date())
                    }
                    
                    count += 1
                    //Load in past history
                    var currentMetric = "0"
                    var currentText = ""
                    self.historyRef.child(self.kasamID).child(self.statusDate).child("Metric Breakdown").child(String(count)).observeSingleEvent(of: .value, with: {(snap) in
                        if snap.exists() && self.viewingOnlyCheck == false {
                            currentMetric = snap.value as! String               //gets the metric for the activity
                        }
                        self.historyRef.child(self.kasamID).child(self.statusDate).child("Text Breakdown").child(String(count)).observeSingleEvent(of: .value, with: {(snap) in
                            if snap.exists() {
                                currentText = snap.value as! String         //gets the text for the activity
                            }
                            let activity = KasamActivityCellFormat(kasamID: self.kasamID, blockID: self.blockID, title: value["Title"] as! String, description: value["Description"] as! String, totalMetric: value["Metric"] as! String, increment: value["Interval"] as? String, currentMetric: currentMetric, imageURL: value["Image"] as! String, image: nil, type: value["Type"] as! String, currentOrder: 0, totalOrder: 0, currentText: currentText)
                            self.activityBlocks.append(activity)
                            self.collectionView.reloadData()
                            if self.activityBlocks.count == count {
                                self.activityNumber.text = "1/\(self.activityBlocks.count)"
                                completion()
                            }
                        })
                    })
                    self.transferMetricMatrix[String(count)] = "0"
                }
                self.collectionView.reloadData()
                self.activityRef.removeObserver(withHandle: self.activityRefHandle!)
            }
        } else {
            count += 1
            let blockNo = Int(blockID) ?? 1
            let blockActivity = NewKasam.fullActivityMatrix[blockNo]
            let activity = KasamActivityCellFormat(kasamID: "", blockID: "", title: blockActivity?[0]?.title ?? "Activity Title", description: blockActivity?[0]?.description ?? "Activity Description", totalMetric: String(describing: blockActivity?[0]?.reps), increment: String(describing: blockActivity?[0]?.interval), currentMetric: "", imageURL: "", image: blockActivity?[0]?.imageToSave, type: NewKasam.chosenMetric, currentOrder: 0, totalOrder: 0, currentText: "")
            self.activityBlocks.append(activity)
            self.collectionView.reloadData()
            if self.activityBlocks.count == count {
                self.activityNumber.text = "1/\(self.activityBlocks.count)"
                completion()
            }
        }
    }
    
    func setupMetricMatrix(){
        for index in 1...activityBlocks.count {
            self.transferMetricMatrix[String(index)] = String(activityBlocks[index - 1].currentMetric)
            summedTotalMetric += Int(activityBlocks[index - 1].totalMetric) ?? 0
        }
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= (keyboardSize.height)
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
}

extension KasamActivityViewer: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, KasamViewerCellDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return activityBlocks.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        activityBlocks[indexPath.row].currentOrder = indexPath.row + 1
        activityBlocks[indexPath.row].totalOrder = activityBlocks.count
        let activity = activityBlocks[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "KasamViewerCell", for: indexPath) as! KasamViewerCell
        cell.viewOnlyCheck = viewingOnlyCheck
        cell.kasamIDTransfer["kasamID"] = kasamID
        cell.setKasamViewer(activity: activity)
        if activity.type == "Reps" {
            let pastProgress = Double(activityBlocks[indexPath.row].currentMetric) ?? 0.0
            cell.setupPicker(pastProgress: pastProgress)
        } else if activity.type == "Countdown" {
            let pastProgress = Double(activityBlocks[indexPath.row].currentMetric) ?? 0.0
            cell.setupCountdown(maxtime: activity.totalMetric, pastProgress: pastProgress)
        } else if activity.type == "CountdownText" {
            let pastProgress = Double(activityBlocks[indexPath.row].currentMetric) ?? 0.0
            cell.setupCountdown(maxtime: activity.totalMetric, pastProgress: pastProgress)
            cell.textField.isHidden = false
        } else if activity.type == "Timer" {
            let pastProgress = Double(activityBlocks[indexPath.row].currentMetric) ?? 0.0
            cell.setupTimer(maxtime: activity.totalMetric, pastProgress: pastProgress)
        } else if activity.type == "Checkmark" {
            cell.textField.isHidden = false
            let pastProgress = Double(activityBlocks[indexPath.row].currentMetric) ?? 0.0
            let pastText = activityBlocks[indexPath.row].currentText
            cell.setupCheckmark(pastProgress: pastProgress, pastText: pastText)
        } else if activity.type == "CheckmarkText" {
            let pastProgress = Double(activityBlocks[indexPath.row].currentMetric) ?? 0.0
            let pastText = activityBlocks[indexPath.row].currentText
            cell.textField.isHidden = false
            cell.setupCheckmark(pastProgress: pastProgress, pastText: pastText)
        }
        else if activity.type == "Rest" {
            cell.setupRest(activity: activity)
        }
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.size.width, height: view.frame.size.height)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        activityCurrentValue = Int(scrollView.contentOffset.x / scrollView.frame.size.width) + 1
        activityNumber.text = "\(activityCurrentValue)/\(activityBlocks.count)"
    }
    
    func nextItem() {
        let visibleItems: NSArray = self.collectionView.indexPathsForVisibleItems as NSArray
        let currentItem: IndexPath = visibleItems.object(at: 0) as! IndexPath
        let nextItem: IndexPath = IndexPath(item: currentItem.item + 1, section: 0)
        if nextItem.row < activityBlocks.count {
            self.collectionView.scrollToItem(at: nextItem, at: .left, animated: true)
            activityCurrentValue += 1
            activityNumber.text = "\(activityCurrentValue)/\(activityBlocks.count)"
        }
    }
    
    func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }
    
    func sendCompletedMatrix(key: Int, value: Double, text: String) {
        transferMetricMatrix[String(key)] = String(value)
        transferTextFieldMatrix[String(key)] = text
        activityBlocks[key - 1].currentMetric = String(value)
        let statusDateTime = getCurrentDateTime()
        var transferAvg = 1.0
        var sum = 0.0
        
        for (_, avg) in transferMetricMatrix {
            sum += Double(avg) ?? 0.0
        }
        
        if self.summedTotalMetric > 0 {
            transferAvg = sum / Double(self.summedTotalMetric)
        }
        if SavedData.kasamDict[kasamID]?.badgeThresholds == nil {
            DBRef.coachKasams.child(kasamID).child("Badges").observeSingleEvent(of: .value) {(snap) in
                if snap.exists() {SavedData.kasamDict[self.kasamID]?.badgeThresholds = (snap.value as! String).components(separatedBy: ";")} else {
                    SavedData.kasamDict[self.kasamID]?.badgeThresholds = ["10","30","90"]
                }
            }
        }
        if transferAvg > 0.0 || SavedData.kasamDict[self.kasamID]?.timelineDuration != nil {
            DBRef.userHistory.child(kasamID).child(statusDate).setValue(["Block Completed": blockID, "Time": statusDateTime , "Metric Percent": transferAvg.rounded(toPlaces: 2), "Total Metric": sum, "Metric Breakdown": transferMetricMatrix, "Text Breakdown": transferTextFieldMatrix])
        } else {
            //removes the dayTracker for today if kasam is set to zero
            DBRef.userHistory.child(kasamID).child(statusDate).setValue(nil)
        }
    }
}
