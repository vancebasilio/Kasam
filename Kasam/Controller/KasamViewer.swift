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

class KasamViewerTicker: UIViewController {
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var activityBlocks: [KasamActivityCellFormat] = []
    var kasamID = ""
    var blockID = ""
    var activityRef: DatabaseReference!
    var activityRefHandle: DatabaseHandle!
    var metricRef: DatabaseReference?
    var metricRefHandle: DatabaseHandle?
    var metricCompleted = 0
    var totalActivties = 0
    var summedTotalMetric = 0
    var transferMetricMatrix = [String: String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getBlockActivities{self.setupMetricMatrix()}
        setupButtons()
        self.hideKeyboardWhenTappedAround()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @IBAction func closeButton(_ sender: UIButton) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateKasamStatus"), object: self)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "ChalloStatsUpdate"), object: self)
        dismiss(animated: true)
    }
    
    func setupButtons() {
        UIApplication.shared.endIgnoringInteractionEvents()
        closeButton?.setIcon(icon: .fontAwesomeSolid(.times), iconSize: 20, color: UIColor.init(hex: 0x79787e), forState: .normal)
    }
    
    func getBlockActivities(_ completion: @escaping () -> ()){
        activityBlocks.removeAll()
        var count = 0
        self.activityRef = Database.database().reference().child("Coach-Kasams").child(kasamID).child("Blocks").child(blockID).child("Activity")
        self.activityRefHandle = activityRef.observe(.childAdded) { (snapshot) in
            if let value = snapshot.value as? [String: Any] {
                //check if user has past progress from today and download metric
                let currentDate = self.getCurrentDate()
                var currentMetric = "0"
                count += 1
                Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("History").child(self.kasamID).child(currentDate ?? "").child("Metric Breakdown").child(String(count)).observeSingleEvent(of: .value, with: { (snap) in
                    if snap.exists() {
                        currentMetric = snap.value as! String
                    }
                    let activity = KasamActivityCellFormat(kasamID: self.kasamID, blockID: self.blockID, title: value["Title"] as! String, description: value["Description"] as! String, totalMetric: value["Metric"] as! String, currentMetric: currentMetric, image: value["Image"] as! String, type: value["Type"] as! String, currentOrder: 0, totalOrder: 0)
                    self.activityBlocks.append(activity)
                    self.collectionView.reloadData()
                    if self.activityBlocks.count == count {
                        completion()
                    }
                })
                self.transferMetricMatrix[String(count)] = "0"
            }
            self.collectionView.reloadData()
            self.activityRef.removeObserver(withHandle: self.activityRefHandle!)
        }
    }
    
    func setupMetricMatrix(){
        for index in 1...activityBlocks.count {
            self.transferMetricMatrix[String(index)] = activityBlocks[index - 1].currentMetric
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

extension KasamViewerTicker: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return activityBlocks.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        activityBlocks[indexPath.row].currentOrder = indexPath.row + 1
        activityBlocks[indexPath.row].totalOrder = activityBlocks.count
        let activity = activityBlocks[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "KasamViewerCell", for: indexPath) as! KasamViewerCell
        cell.setKasamViewer(activity: activity)
        if activity.type == "Picker" {
            cell.setupPicker()
            cell.circularSlider.isHidden = true
            cell.timerButtonStackView.isHidden = true
            cell.instruction.isHidden = true
            cell.textField.isHidden = true
        } else if activity.type == "Timer" {
            cell.setupTimer()
            cell.setInitialTime()
            cell.animatedImageView.isHidden = true
            cell.doneButton.isHidden = true
            cell.pickerView.isHidden = true
            cell.instruction.isHidden = true
        }
        cell.pickerView.selectRow((Int(activityBlocks[indexPath.row].currentMetric) ?? 0) / 10, inComponent: 0, animated: false)
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.size.width, height: view.frame.size.height)
    }
}

extension KasamViewerTicker: KasamViewerCellDelegate {
    
    func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }
    
   func nextItem() {
        let visibleItems: NSArray = self.collectionView.indexPathsForVisibleItems as NSArray
        let currentItem: IndexPath = visibleItems.object(at: 0) as! IndexPath
        let nextItem: IndexPath = IndexPath(item: currentItem.item + 1, section: 0)
        if nextItem.row < activityBlocks.count {
            self.collectionView.scrollToItem(at: nextItem, at: .left, animated: true)
        }
    }
    
    func sendCompletedMatrix(key: Int, value: Int) {
        transferMetricMatrix[String(key)] = String(value)
        activityBlocks[key - 1].currentMetric = String(value)
        let statusDateTime = getCurrentDateTime()
        let statusDate = getCurrentDate()
        var sum = 0.0
        
        for (_, avg) in transferMetricMatrix{
            sum += Double(avg) ?? 0.0
        }
        let  transferAvg : Double = sum / Double(self.summedTotalMetric)

        Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("History").child(kasamID).child(statusDate ?? "StatusDate").updateChildValues(["Block Completed": blockID, "Time": statusDateTime ?? "StatusTime", "Metric Completed": transferAvg, "Metric Breakdown": transferMetricMatrix]) {(error, reference) in}
    }
}
