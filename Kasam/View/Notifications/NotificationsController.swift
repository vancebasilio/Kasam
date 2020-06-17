//
//  NotificationsController.swift
//  Kasam
//
//  Created by Vance Basilio on 2020-06-06.
//  Copyright © 2020 Vance Basilio. All rights reserved.
//

import UIKit

class NotificationsController: UIViewController {
    
    @IBOutlet weak var slidingHandle: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var kasamLogo: UIImageView!
    @IBOutlet weak var notificationsTable: UITableView!
    
    var didLayout = false
    var notificationArray = [Int:UNNotificationRequest]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        kasamLogo.image = UIImage(named: "KasamLogo")
        slidingHandle.layer.cornerRadius = 3
        saveButton.layer.cornerRadius = 20.0
        closeButton?.setIcon(icon: .fontAwesomeSolid(.times), iconSize: 20, color: UIColor.init(hex: 0x79787e), forState: .normal)
        localNotifications(nil)
        
        let reloadNotification = NSNotification.Name("ReloadNotifications")
        NotificationCenter.default.addObserver(self, selector: #selector(NotificationsController.localNotifications), name: reloadNotification, object: nil)
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        tableViewHeight.constant = CGFloat(100 * SavedData.todayKasamList.count)
        contentViewHeight.constant = 400 + (tableViewHeight.constant)
    }
     
    @objc func localNotifications(_ notification: NSNotification?){
//        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().getPendingNotificationRequests {(notifications) in
            for item in notifications {
                if let index = SavedData.todayKasamList.index(of:item.identifier) {
                    self.notificationArray[index] = item
                    let localTrigger = item.trigger as! UNCalendarNotificationTrigger
                    let format = DateFormatter()
                    format.timeZone = .current
                    format.dateFormat = "yyyy-MM-dd' 'HH:mm"
                    print("hell7 \((SavedData.kasamDict[item.identifier]!.kasamName,format.string(from: localTrigger.nextTriggerDate()!)))")
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
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension NotificationsController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SavedData.todayKasamList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationsCell") as! NotificationsCell
        let block = SavedData.kasamDict[SavedData.todayKasamList[indexPath.row]]!
        cell.kasamImage.sd_setImage(with: URL(string: block.image))
        cell.kasamName.text = block.kasamName
        cell.kasamID = block.kasamID
        cell.order = indexPath.row
        cell.updateSwitch(notificationInfo: self.notificationArray[indexPath.row])      //Updates the state of the switch
        cell.preferenceTime.setIcon(prefixText: "", prefixTextColor: .clear, icon: .fontAwesomeSolid(.clock), iconColor: .colorFive, postfixText: " \(block.startTime)", postfixTextColor: .colorFive, size: 13, iconSize: 13)
        cell.preferenceTime.textAlignment = .left
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(100)
    }
}