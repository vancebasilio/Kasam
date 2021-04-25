//
//  NotificationsCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2020-06-06.
//  Copyright © 2020 Vance Basilio. All rights reserved.
//

import UIKit

class NotificationsCell: UITableViewCell {
    
    @IBOutlet weak var kasamImage: UIImageView!
    @IBOutlet weak var kasamName: UILabel!
    @IBOutlet weak var preferenceTime: UILabel!
    @IBOutlet weak var preferenceSwitch: UISwitch!
    
    var kasamID = ""
    var order = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        kasamImage.layer.cornerRadius = 8.0
        kasamImage.clipsToBounds = true
        preferenceSwitch.onTintColor = .colorFour
        preferenceSwitch.tintColor = .gray
        preferenceSwitch.layer.cornerRadius = preferenceSwitch.frame.height / 2
        preferenceSwitch.backgroundColor = .gray
    }
    
    func updateSwitch(notificationInfo: UNNotificationRequest?){
        if notificationInfo != nil {
            preferenceSwitch.setOn(true, animated: false)
        } else {
            preferenceSwitch.setOn(false, animated: false)
        }
    }
    
    @IBAction func switchClicked(_ sender: Any) {
        if preferenceSwitch.isOn {
//            kasamID.restartExistingNotification()         //create a local notification
        } else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [kasamID])
        }
    }
    
    @IBAction func editButtonPressed(_ sender: Any) {
        var saveTimeObserver: NSObjectProtocol?
        showBottomAddKasamPopup(kasamID: kasamID, state: "edit", duration: SavedData.kasamDict[kasamID]!.repeatDuration)
        
        saveTimeObserver = NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "SaveTime\(kasamID)"), object: nil, queue: OperationQueue.main) {(notification) in
            
            let timeVC = notification.object as! AddKasamController
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers:[self.kasamID])
//            var endDate: Date?
//            let kasam = SavedData.kasamDict[self.kasamID]
//            if kasam!.repeatDuration != 0 {
//                endDate = Calendar.current.date(byAdding: .day, value: kasam!.repeatDuration, to: kasam!.joinedDate)!
//            }
//            self.kasamID.setupNotifications(kasamName: kasam!.kasamName, startDate: Date(), endDate: endDate, chosenTime: timeVC.formattedTime)
            
            if SavedData.todayKasamBlocks["personal"]!.contains(where: {$0.kasamID == self.kasamID}) || SavedData.upcomingKasamBlocks["personal"]!.contains(where: {$0.kasamID == self.kasamID})  {
                DBRef.userPersonalFollowing.child(self.kasamID).updateChildValues(["Time": timeVC.formattedTime]) {(error, reference) in
                    SavedData.kasamDict[self.kasamID]?.startTime = timeVC.formattedTime
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "ReloadNotifications"), object: self, userInfo: ["order": self.order])
                    NotificationCenter.default.removeObserver(saveTimeObserver as Any)
                }
            } else if SavedData.todayKasamBlocks["group"]!.contains(where: {$0.kasamID == self.kasamID}) || SavedData.upcomingKasamBlocks["group"]!.contains(where: {$0.kasamID == self.kasamID}) {
                DBRef.userGroupFollowing.child((SavedData.kasamDict[self.kasamID]?.groupID)!).updateChildValues(["Time": timeVC.formattedTime]) {(error, reference) in
                    SavedData.kasamDict[self.kasamID]?.startTime = timeVC.formattedTime
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "ReloadNotifications"), object: self, userInfo: ["order": self.order])
                    NotificationCenter.default.removeObserver(saveTimeObserver as Any)
                }
            }
        }
    }
}
