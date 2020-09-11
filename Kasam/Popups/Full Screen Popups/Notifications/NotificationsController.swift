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
    var notificationArray = [(kasamID: String, notification: UNNotificationRequest?)]()
    
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
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        tableViewHeight.constant = CGFloat(100 * notificationArray.count)
        contentViewHeight.constant = 380 + (tableViewHeight.constant)
    }
     
    @objc func localNotifications(_ notification: NSNotification?){
        notificationArray.removeAll()
        UNUserNotificationCenter.current().getPendingNotificationRequests {(notifications) in
            for kasam in SavedData.personalKasamBlocks + SavedData.groupKasamBlocks {
                //Notification exists for kasamID
                if let index = notifications.index(where: {$0.identifier == kasam.kasamID}) {
                    self.notificationArray.append((kasam.kasamID, notifications[(index)]))
                    let format = DateFormatter(); format.timeZone = .current; format.dateFormat = "yyyy-MM-dd' 'HH:mm"
                    print("hell7 \((SavedData.kasamDict[notifications[index].identifier]!.kasamName, format.string(from: (notifications[index].trigger as! UNCalendarNotificationTrigger).nextTriggerDate()!)))")
                } else {
                //No Notification for kasamID
                    self.notificationArray.append((kasam.kasamID, nil))
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [kasam.kasamID]) //Remove notification if it exists
                }
            }
            DispatchQueue.main.async {
                if let order = notification?.userInfo?["order"] as? Int {
                    self.notificationsTable.reloadRows(at: [IndexPath(row: order, section: 0)], with: .none)
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notificationArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationsCell") as! NotificationsCell
        if let block = SavedData.kasamDict[notificationArray[indexPath.row].kasamID] {
            cell.kasamImage.sd_setImage(with: URL(string: block.image))
            cell.kasamName.text = block.kasamName
            cell.kasamID = block.kasamID
            cell.order = indexPath.row
            cell.updateSwitch(notificationInfo: self.notificationArray[indexPath.row].notification)      //Updates the state of the switch
            cell.preferenceTime.setIcon(prefixText: "", prefixTextColor: .clear, icon: .fontAwesomeSolid(.clock), iconColor: .colorFive, postfixText: " \(block.startTime)", postfixTextColor: .colorFive, size: 13, iconSize: 13)
        }
        cell.preferenceTime.textAlignment = .left
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(100)
    }
}
