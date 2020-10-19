//
//  NotificationsController.swift
//  Kasam
//
//  Created by Vance Basilio on 2020-06-06.
//  Copyright © 2020 Vance Basilio. All rights reserved.
//

import UIKit
import SwiftEntryKit


class NotificationsController: UIViewController {
    
    @IBOutlet weak var slidingHandle: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var kasamLogo: UIImageView!
    @IBOutlet weak var notificationsTable: UITableView!
    
    init() {super.init(nibName: type(of: self).className, bundle: nil)}
    required init?(coder aDecoder: NSCoder) {fatalError("init(coder:) has not been implemented")}
    
    var didLayout = false
    var sectionHeight = CGFloat(0)
    var notificationArray = ["current": [(kasamID: String, notification: UNNotificationRequest?)](), "upcoming": [(kasamID: String, notification: UNNotificationRequest?)]()]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        kasamLogo.image = UIImage(named: "KasamLogo")
        slidingHandle.layer.cornerRadius = 3
        saveButton.layer.cornerRadius = 20.0
        closeButton?.setIcon(icon: .fontAwesomeSolid(.times), iconSize: 20, color: UIColor.init(hex: 0x79787e), forState: .normal)
        localNotifications(nil)
        
        let nib = UINib(nibName: "NotificationsCell", bundle: nil)
        notificationsTable.register(nib, forCellReuseIdentifier: "NotificationsCell")
        
        let reloadNotification = NSNotification.Name("ReloadNotifications")
        NotificationCenter.default.addObserver(self, selector: #selector(NotificationsController.localNotifications), name: reloadNotification, object: nil)
    }
    
    func updateScrollViewSize() {
        super.updateViewConstraints()
        let count = notificationArray["current"]!.count + notificationArray["upcoming"]!.count
        tableViewHeight.constant = CGFloat(100 * count) + sectionHeight
        contentViewHeight.constant = 380 + (tableViewHeight.constant)
    }
     
    @objc func localNotifications(_ notification: NSNotification?){
        UNUserNotificationCenter.current().getPendingNotificationRequests {(notifications) in
            for kasam in SavedData.todayKasamBlocks["personal"]! + SavedData.upcomingKasamBlocks["personal"]! + SavedData.todayKasamBlocks["group"]! + SavedData.upcomingKasamBlocks["group"]! {
                //Notification exists for kasamID
                var type = "current"; if SavedData.kasamDict[kasam.kasamID]!.joinedDate > Date() {type = "upcoming"}
                if let index = notifications.index(where: {$0.identifier == kasam.kasamID}) {
                    self.notificationArray[type]!.append((kasam.kasamID, notifications[(index)]))
                    let format = DateFormatter(); format.timeZone = .current; format.dateFormat = "yyyy-MM-dd' 'HH:mm"
                    print("hell7 \((SavedData.kasamDict[notifications[index].identifier]!.kasamName, format.string(from: (notifications[index].trigger as! UNCalendarNotificationTrigger).nextTriggerDate()!)))")
                } else {
                //No Notification for kasamID
                    self.notificationArray[type]!.append((kasam.kasamID, nil))
                    //Remove notification if it exists
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [kasam.kasamID])
                }
            }
            DispatchQueue.main.async {
                self.updateScrollViewSize()
                if let order = notification?.userInfo?["order"] as? Int {
                    self.notificationsTable.reloadRows(at: [IndexPath(row: order, section: 0)], with: .none)
                    self.notificationsTable.reloadRows(at: [IndexPath(row: order, section: 1)], with: .none)
                }
            }
        }
    }
    
    @IBAction func closeButtonPressed(_ sender: Any) {
        SwiftEntryKit.dismiss()
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        SwiftEntryKit.dismiss()
    }
}

extension NotificationsController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {return notificationArray["current"]?.count ?? 0}
        else {return notificationArray["upcoming"]?.count ?? 0}
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 {return sectionHeader(text: "Upcoming", color: .colorFive, leading: 0)}
        else {return nil}
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 || (section == 1 && notificationArray["upcoming"]?.count == 0) {return 0}
        else {sectionHeight = 30; return sectionHeight}
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var type = "current"; if indexPath.section == 1 {type = "upcoming"}
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationsCell") as! NotificationsCell
        if let block = SavedData.kasamDict[notificationArray[type]![indexPath.row].kasamID] {
            cell.kasamImage.sd_setImage(with: URL(string: block.image))
            cell.kasamName.text = block.kasamName
            cell.kasamID = block.kasamID
            cell.order = indexPath.row
            cell.updateSwitch(notificationInfo: self.notificationArray[type]![indexPath.row].notification)
            cell.preferenceTime.setIcon(prefixText: "", prefixTextColor: .clear, icon: .fontAwesomeSolid(.clock), iconColor: .colorFive, postfixText: " \(block.startTime)", postfixTextColor: .colorFive, size: 13, iconSize: 13)
        }
        cell.preferenceTime.textAlignment = .left
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(100)
    }
}
