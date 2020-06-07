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
        let center = UNUserNotificationCenter.current()
        if preferenceSwitch.isOn {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "SetupNotification"), object: self, userInfo: ["kasamID": kasamID])
        } else {
            center.removePendingNotificationRequests(withIdentifiers: [kasamID])
        }
    }
}
