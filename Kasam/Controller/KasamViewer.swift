//
//  KasamViewer.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-09-05.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import SwiftIcons

class KasamActivityViewer: UIViewController {
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var activityNumber: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var activityBlocks: [KasamActivityCellFormat] = []
    var kasamID = ""                    //loaded in
    var blockID = ""                    //loaded in
    var type = ""                       //loading in
    var blockName = ""                  //loaded in
    var dateToLoad: Date?               //loaded in
    
    var activityRef: DatabaseReference!
    var activityRefHandle: DatabaseHandle!
    var metricRef: DatabaseReference?
    var metricRefHandle: DatabaseHandle?
    var metricCompleted = 0
    var totalActivties = 0
    var achievedMaxMatrix = [String: (achieved: Double, max: Double)]()
    var achievedMatrix = [String: Double]()
    var activityCurrentValue = 0
    var reviewOnly = false
    var viewOnlyCheck = false
    var statusDate = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if reviewOnly == true {reviewOnlyKasamViewer()}
        else {getBlockActivities(nil)}
        setupButtons()
        self.hideKeyboardWhenTappedAround()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let reloadKasamBlock = NSNotification.Name("ReloadKasamBlock")
        NotificationCenter.default.addObserver(self, selector: #selector(KasamActivityViewer.getBlockActivities), name: reloadKasamBlock, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func closeButton(_ sender: UIButton) {
        if reviewOnly == false {
            updateControllers()
        }
        dismiss(animated: true)
    }
    
    func updateControllers(){
        NotificationCenter.default.post(name: Notification.Name(rawValue: "RemovePersonalLoadingAnimation"), object: self)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "RemoveGroupLoadingAnimation"), object: self)
    }
    
    func setupButtons() {
        UIApplication.shared.endIgnoringInteractionEvents()
        closeButton.setIcon(icon: .fontAwesomeSolid(.timesCircle), iconSize: 23, color: .darkGray, forState: .normal)
    }
    
    @objc func getBlockActivities(_ manualBlock: NSNotification?){
        //User manually changing kasam block from the Kasam Viewer Cell
        if let manualBlockID = manualBlock?.userInfo?["blockID"] as? String {
            blockID = manualBlockID
            blockName = manualBlock?.userInfo?["blockName"] as? String ?? ""
            if let kasamOrder = SavedData.personalKasamBlocks.index(where: {($0.kasamID == kasamID)}) {
                SavedData.personalKasamBlocks[kasamOrder].data.blockTitle = blockName
                SavedData.personalKasamBlocks[kasamOrder].data.blockID = blockID
                NotificationCenter.default.post(name: Notification.Name(rawValue: "RefreshPersonalKasam"), object: self, userInfo: ["kasamOrder": kasamOrder])
            }
        }
        activityBlocks.removeAll()
        var count = 0
        self.statusDate = dateToLoad?.dateToString() ?? Date().dateToString()
    //STEP 1 - GET ALL THE BLOCK ACTIVITIES
        self.activityRef = DBRef.coachKasams.child(kasamID).child("Blocks").child(blockID).child("Activity")
        self.activityRefHandle = activityRef.observe(.childAdded) {(snapshot) in
            if let value = snapshot.value as? [String: Any] {
                count += 1
            //STEP 2A - DOWNLOAD PAST PROGRESS FOR THE ACTIVITIES
                if SavedData.kasamDict[self.kasamID] != nil {
                    var currentMetric = 0.0
                    var db = DBRef.userPersonalHistory.child(self.kasamID).child(SavedData.kasamDict[self.kasamID]!.joinedDate.dateToString()).child(self.statusDate).child("Metric Breakdown").child(String(count))
                    if self.type == "group" {
                        db = DBRef.groupKasams.child((SavedData.kasamDict[self.kasamID]?.groupID)!).child("Team").child(Auth.auth().currentUser!.uid).child(self.statusDate).child("Metric Breakdown").child(String(count))
                    }
                    db.observeSingleEvent(of: .value, with: {(snap) in
                        if snap.exists() && self.reviewOnly == false {
                            currentMetric = (snap.value as? Double) ?? 0.0               //Gets the metric for the activity for the day selected
                        }
                        self.loadActivity(currentMetric: currentMetric, value: value, count: count)
                    })
                //STEP 2B - ONLY VIEWING THE KASAM BLOCKS FROM DISCOVER
                } else {
                    self.loadActivity(currentMetric: Double(value["Metric"] as? Int ?? 0), value: value, count: count)
                }
            }
            self.activityRef.removeObserver(withHandle: self.activityRefHandle!)
        }
    }
    
    func loadActivity(currentMetric: Double, value: [String:Any], count: Int) {
        let activity = KasamActivityCellFormat(kasamID: self.kasamID, blockID: self.blockID, title: value["Title"] as! String, description: value["Description"] as! String, increment: value["Interval"] as? String, currentMetric: currentMetric, totalMetric: value["Metric"] as? Int ?? 0, imageURL: value["Image"] as? String, videoURL: value["Video"] as? String, image: nil, type: value["Type"] as! String, currentOrder: 0, totalOrder: 0)
        self.activityBlocks.append(activity)
        if self.activityBlocks.count == count {
            if self.activityBlocks.count == 1 {self.activityNumber.isHidden = true}
            else {self.activityNumber.isHidden = false}
            self.activityNumber.text = "1/\(self.activityBlocks.count)"
            self.collectionView.reloadData()
            if reviewOnly == false {
                for index in 1...self.activityBlocks.count {
                    self.achievedMatrix[String(index)] = self.activityBlocks[index - 1].currentMetric
                    self.achievedMaxMatrix[String(index)] = (self.activityBlocks[index - 1].currentMetric!, Double(self.activityBlocks[index - 1].totalMetric))
                }
            }
        }
    }
    
    func reviewOnlyKasamViewer(){
        let blockNo = Int(blockID) ?? 1
        let blockActivity = NewKasam.fullActivityMatrix[blockNo]
        let activity = KasamActivityCellFormat(kasamID: "", blockID: "", title: blockActivity?[0]?.title ?? "Activity Title", description: blockActivity?[0]?.description ?? "Activity Description", increment: String(describing: blockActivity?[0]?.interval), currentMetric: 0.0, totalMetric: blockActivity?[0]?.reps ?? 0, imageURL: "", videoURL: "", image: blockActivity?[0]?.imageToSave, type: NewKasam.chosenMetric, currentOrder: 0, totalOrder: 0)
        self.activityBlocks.append(activity)
        self.collectionView.reloadData()
        self.activityNumber.text = "1/\(self.activityBlocks.count)"
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
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let collectionViewCell = cell as? KasamViewerCell {
            collectionViewCell.pickerViewIsScrolling = false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        activityBlocks[indexPath.row].currentOrder = indexPath.row + 1
        activityBlocks[indexPath.row].totalOrder = activityBlocks.count
        let activity = activityBlocks[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "KasamViewerCell", for: indexPath) as! KasamViewerCell
        cell.viewOnlyCheck = viewOnlyCheck
        cell.today = dateToLoad?.dateToString() == Date().dateToString()
        cell.kasamIDTransfer["kasamID"] = kasamID
        cell.setKasamViewer(activity: activity)
        cell.pastProgress = activityBlocks[indexPath.row].currentMetric ?? 0
        if activity.type == "Reps" {
            cell.setupPicker()
        } else if activity.type == "Countdown" {
            cell.setupCountdown(maxtime: activity.totalMetric)
        } else if activity.type == "Timer" {
            cell.setupTimer(maxtime: activity.totalMetric)
        } else if activity.type == "Checkmark" {
            cell.setupCheckmark()
        } else if activity.type == "Video" {
            cell.setVideoPlayer()
        } else if activity.type == "Rest" {
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
    
    func sendCompletedMatrix(activityNo: Int, value: Double, max: Double) {
        print("hell5 \(statusDate)")
        achievedMaxMatrix[String(activityNo)] = (value, max)
        achievedMatrix[String(activityNo)] = value
        activityBlocks[activityNo - 1].currentMetric = value
        var transferAvg = 0.0
        var sum = 0.0
        
        for progress in achievedMaxMatrix {
            if progress.value.max > 0 {transferAvg += ((progress.value.achieved / progress.value.max) / Double(activityBlocks.count))}
            sum += progress.value.achieved
        }
        
        let db = DBRef.userPersonalHistory.child(kasamID).child(SavedData.kasamDict[self.kasamID]!.joinedDate.dateToString()).child(statusDate)
        if transferAvg > 0.0 {
        //OPTION 1 - Progress made
            if type == "personal" {
                db.observeSingleEvent(of: .value) {(snap) in
                    if !snap.exists() {self.setHistoryTotal(kasamID: self.kasamID, statusDate: self.statusDate, value: 1)}  //Add history once
                    db.setValue(["BlockID": self.blockID, "Block Name": self.blockName, "Time": self.getCurrentDateTime(), "Metric Percent": transferAvg.rounded(toPlaces: 2), "Total Metric": sum, "Metric Breakdown": self.achievedMatrix])
                }
            } else {
                DBRef.groupKasams.child((SavedData.kasamDict[kasamID]?.groupID)!).child("History").child(Auth.auth().currentUser!.uid).child(statusDate).setValue(["BlockID": blockID, "Block Name": blockName, "Time": self.getCurrentDateTime(), "Metric Percent": transferAvg.rounded(toPlaces: 2), "Total Metric": sum, "Metric Breakdown": self.achievedMatrix])
            }
        //OPTION 2 - REMOVE PROGRESS
        } else {
            if type == "personal" {
                db.setValue(nil)
                setHistoryTotal(kasamID: kasamID, statusDate: statusDate, value: 0)
            } else {
                DBRef.groupKasams.child((SavedData.kasamDict[kasamID]?.groupID)!).child("History").child(Auth.auth().currentUser!.uid).child(statusDate).setValue(nil)
            }
        }
    }
}
