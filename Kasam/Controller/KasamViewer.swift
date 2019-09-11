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

class KasamViewer: UIViewController {
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getBlockActivities()
        UIApplication.shared.endIgnoringInteractionEvents()
        closeButton?.setIcon(icon: .fontAwesomeSolid(.times), iconSize: 20, color: UIColor.init(hex: 0x79787e), forState: .normal)
    }
    
    @IBAction func closeButton(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    func getBlockActivities(){
        activityBlocks.removeAll()
        self.activityRef = Database.database().reference().child("Coach-Kasams").child(kasamID).child("Blocks").child(blockID).child("Activity")
        self.activityRefHandle = activityRef.observe(.childAdded) { (snapshot) in
            if let value = snapshot.value as? [String: Any] {
                //check if user has past progress from today and download metric
                let currentDate = self.getCurrentDate()
            Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("History").child(self.kasamID).child(currentDate ?? "").child("Metric Completed").observeSingleEvent(of: .value, with: {(snap) in
                    if let value = snap.value as? Int {
                        self.metricCompleted = value - 1
                        print(value)
                    } else {
                        print ("user has no progres from today to transfer")
                    }
                    let activity = KasamActivityCellFormat(kasamID: self.kasamID, blockID: self.blockID, title: value["Title"] as! String, description: value["Description"] as! String, totalMetric: value["Metric"] as! String, currentMetric: self.metricCompleted, image: value["Image"] as! String)
                    self.activityBlocks.append(activity)
                    self.collectionView.reloadData()
                })
            }
        }
        self.collectionView.reloadData()
        self.activityRef.removeObserver(withHandle: self.activityRefHandle!)
    }
}

extension KasamViewer: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return activityBlocks.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let activity = activityBlocks[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "KasamViewerCell", for: indexPath) as! KasamViewerCell
        cell.setKasamViewer(activity: activity)
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.size.width, height: view.frame.size.height)
    }
    
    //stops the Activity Video when the viewer is opened
//    func collectionView (_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//        NotificationCenter.default.post(name: Notification.Name(rawValue: "StopActivityVideo"), object: self)
//    }
}

extension KasamViewer: KasamViewerCellDelegate {
    
    func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }
    
    func setCompletedMetric(completedMetric: Int) {
        let statusDateTime = getCurrentDateTime()
        let statusDate = getCurrentDate()
        Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("History").child(kasamID).child(statusDate ?? "StatusDate").updateChildValues(["Block Completed": blockID, "Time": statusDateTime ?? "StatusTime", "Metric Completed": completedMetric]) {(error, reference) in}
        }
}
