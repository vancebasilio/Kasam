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
    var kasamID = ""                    //loaded in
    var blockID = ""                    //loaded in
    var blockName = ""                  //loaded in
    var dateToLoad: Date?               //loaded in
    var dayToLoad: Int?                 //loaded in (for PROGRAM kasams, to update the right dayTracker day)
    
    var activityRef: DatabaseReference!
    var activityRefHandle: DatabaseHandle!
    var metricRef: DatabaseReference?
    var metricRefHandle: DatabaseHandle?
    var metricCompleted = 0
    var totalActivties = 0
    var summedTotalMetric = 0
    var transferMetricMatrix = [String: String]()
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
        NotificationCenter.default.post(name: Notification.Name(rawValue: "MainStatsUpdate"), object: self)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "RemoveLoadingAnimation"), object: self)
    }
    
    func setupButtons() {
        UIApplication.shared.endIgnoringInteractionEvents()
        closeButton?.setIcon(icon: .fontAwesomeSolid(.timesCircle), iconSize: 23, color: .lightGray, forState: .normal)
    }
    
    func getBlockActivities(_ completion: @escaping () -> ()){
        activityBlocks.removeAll()
        var count = 0
        if reviewOnly == false {
            //Check if user has past progress and download metric
            self.statusDate = dateToLoad?.dateToString() ?? Date().dateToString()
            self.activityRef = DBRef.coachKasams.child(kasamID).child("Blocks").child(blockID).child("Activity")
            self.activityRefHandle = activityRef.observe(.childAdded) {(snapshot) in
                if let value = snapshot.value as? [String: Any] {
                    count += 1
                    var currentMetric = "0"
                    DBRef.userHistory.child(self.kasamID).child(SavedData.kasamDict[self.kasamID]!.joinedDate.dateToString()).child(self.statusDate).child("Metric Breakdown").child(String(count)).observeSingleEvent(of: .value, with: {(snap) in
                        if snap.exists() && self.viewingOnlyCheck == false {
                            currentMetric = snap.value as! String               //Gets the metric for the activity for the day selected
                        }
                        let activity = KasamActivityCellFormat(kasamID: self.kasamID, blockID: self.blockID, title: value["Title"] as! String, description: value["Description"] as! String, totalMetric: value["Metric"] as! String, increment: value["Interval"] as? String, currentMetric: currentMetric, imageURL: value["Image"] as? String, videoURL: value["Video"] as? String, image: nil, type: value["Type"] as! String, currentOrder: 0, totalOrder: 0)
                        self.activityBlocks.append(activity)
                        self.collectionView.reloadData()
                        if self.activityBlocks.count == count {
                            if self.activityBlocks.count == 1 {self.activityNumber.isHidden = true}
                            else {self.activityNumber.isHidden = false}
                            self.activityNumber.text = "1/\(self.activityBlocks.count)"
                            completion()
                        }
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
            let activity = KasamActivityCellFormat(kasamID: "", blockID: "", title: blockActivity?[0]?.title ?? "Activity Title", description: blockActivity?[0]?.description ?? "Activity Description", totalMetric: String(describing: blockActivity?[0]?.reps), increment: String(describing: blockActivity?[0]?.interval), currentMetric: "", imageURL: "", videoURL: "", image: blockActivity?[0]?.imageToSave, type: NewKasam.chosenMetric, currentOrder: 0, totalOrder: 0)
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
        cell.viewOnlyCheck = viewingOnlyCheck
        cell.kasamIDTransfer["kasamID"] = kasamID
        cell.setKasamViewer(activity: activity)
        cell.pastProgress = Double(activityBlocks[indexPath.row].currentMetric) ?? 0.0
        if activity.type == "Reps" {
            cell.setupPicker()
        } else if activity.type == "Countdown" {
            cell.setupCountdown(maxtime: activity.totalMetric)
        } else if activity.type == "Timer" {
            cell.setupTimer(maxtime: activity.totalMetric)
        } else if activity.type == "Checkmark" {
            cell.setupCheckmark()
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
    
    func sendCompletedMatrix(activityNo: Int, value: Double) {
        transferMetricMatrix[String(activityNo)] = String(value)
        activityBlocks[activityNo - 1].currentMetric = String(value)
        let statusDateTime = getCurrentDateTime()
        var transferAvg = 1.0
        var sum = 0.0
        
        for (_, avg) in transferMetricMatrix {
            sum += Double(avg) ?? 0.0
        }
        
        if self.summedTotalMetric > 0 {
            transferAvg = sum / Double(self.summedTotalMetric)
        }
        if transferAvg > 0.0 {
            DBRef.userHistory.child(kasamID).child(SavedData.kasamDict[self.kasamID]!.joinedDate.dateToString()).child(statusDate).setValue(["BlockID": blockID, "Block Name": blockName, "Time": statusDateTime , "Metric Percent": transferAvg.rounded(toPlaces: 2), "Total Metric": sum, "Metric Breakdown": transferMetricMatrix])
        } else {
            //removes the dayTracker for today if kasam is set to zero
            DBRef.userHistory.child(kasamID).child(SavedData.kasamDict[self.kasamID]!.joinedDate.dateToString()).child(statusDate).setValue(nil)
        }
    }
}
