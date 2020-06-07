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
        localNotifications()
        
        let setupNotification = NSNotification.Name("SetupNotification")
        NotificationCenter.default.addObserver(self, selector: #selector(NotificationsController.setupNotification), name: setupNotification, object: nil)
    }
     
    func localNotifications(){
        let center = UNUserNotificationCenter.current()
//        center.removeAllPendingNotificationRequests()
        center.getPendingNotificationRequests {(notifications) in
            print("hell7 Count: \(notifications.count)")
            for item in notifications {
                if let index = SavedData.todayKasamList.index(of:item.identifier) {
                    self.notificationArray[index] = item
                }
            }
        }
    }
    
    @objc func setupNotification (_ notification: NSNotification?){
        if let kasamID = notification?.userInfo?["kasamID"] as? String {
            let kasam = SavedData.kasamDict[kasamID]
            setupNotifications(kasamID: kasamID, kasamName: kasam!.kasamName, startDate: dateFormat(date:kasam!.joinedDate), chosenTime: kasam!.startTime)
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
        cell.updateSwitch(notificationInfo: self.notificationArray[indexPath.row])
        cell.preferenceTime.setIcon(prefixText: "", prefixTextColor: .clear, icon: .fontAwesomeSolid(.clock), iconColor: .colorFive, postfixText: " \(block.startTime)", postfixTextColor: .colorFive, size: 13, iconSize: 13)
        cell.preferenceTime.textAlignment = .left
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(100)
    }
}
