//
//  EmbeddedViewController.swift
//  SwiftEntryKitDemo
//
//  Created by Daniel Huri on 3/15/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import SwiftEntryKit
import FBSDKLoginKit

class UserOptionsController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet weak var slidingHandle: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    
    init() {super.init(nibName: type(of: self).className, bundle: nil)}
    required init?(coder aDecoder: NSCoder) {fatalError("init(coder:) has not been implemented")}
    
    var popupType = "userOptions"
    var categoryChosen = ""
    var array: [(blockID: String, blockName: String)]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        slidingHandle.layer.cornerRadius = 3
        slidingHandle.clipsToBounds = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "GenericCell")
    }
}

extension UserOptionsController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if popupType == "changeKasamBlock" {
            headerLabel.text = "Change Kasam Activity"
            headerLabel.textColor = .colorFive
            return array?.count ?? 1
        } else if popupType == "userOptions" {
            return 4
        } else {
            return Icons.categoryIcons.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GenericCell")!
        cell.selectionStyle = .none
        if popupType == "userOptions" {
            switch indexPath.row {
                case 0: cell.textLabel?.setIcon(prefixText: "  ", icon: .fontAwesomeSolid(.gift), postfixText: "  Create a Basic Kasam", size: 20)
                case 1: cell.textLabel?.setIcon(prefixText: "  ", icon: .fontAwesomeSolid(.cubes), postfixText: "  Create a Complex Kasam", size: 20)
                case 2: cell.textLabel?.setIcon(prefixText: "  ", icon: .fontAwesomeSolid(.bell), postfixText: "  Notifications", size: 20)
                case 3: cell.textLabel?.setIcon(prefixText: "  ", icon: .fontAwesomeSolid(.signOutAlt), postfixText: "  Log Out", size: 20)
                default: cell.textLabel?.text = ""
            }
        } else if popupType == "categoryOptions" {
            let category = Icons.categoryIcons[indexPath.row]
            switch category {
                case "Fitness": cell.textLabel?.setIcon(prefixText: "  ", icon: .fontAwesomeSolid(.dumbbell), postfixText: "  Fitness", size: 20)
                case "Personal": cell.textLabel?.setIcon(prefixText: "  ", icon: .fontAwesomeSolid(.seedling), postfixText: "  Personal", size: 20)
                case "Health": cell.textLabel?.setIcon(prefixText: "  ", icon: .fontAwesomeSolid(.heart), postfixText: "  Health", size: 20)
                case "Spiritual": cell.textLabel?.setIcon(prefixText: "  ", icon: .fontAwesomeSolid(.spa), postfixText: "  Spiritual", size: 20)
                case "Writing": cell.textLabel?.setIcon(prefixText: "  ", icon: .fontAwesomeSolid(.book), postfixText: "  Writing", size: 20)
                default: cell.textLabel?.setIcon(prefixText: "  ", icon: .fontAwesomeSolid(.dumbbell), postfixText: "  Default", size: 20)
            }
        } else if popupType == "changeKasamBlock" {
            cell.textLabel?.text = array?[indexPath.row].blockName
        }
        cell.textLabel?.textAlignment = .left
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if popupType == "userOptions" {
            switch indexPath.row {
                case 0:
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "GoToCreateKasam"), object: self, userInfo: ["type": "basic"])
                    SwiftEntryKit.dismiss()
                case 1:
                    if SavedData.userType == "Pro" {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "GoToCreateKasam"), object: self, userInfo: ["type": "complex"])
                        SwiftEntryKit.dismiss()
                    } else {
                        showOptionsPopup(kasamID: nil, title: nil, subtitle: nil, text: "You'll need to go Pro to create a complex kasam", type:"goPro", button: "Go Pro!") {
                            print("Go Pro Page")
                        }
                    }
                case 2:
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "GoToNotifications"), object: self)
                    SwiftEntryKit.dismiss()
                case 3:
                    showOptionsPopup(kasamID: nil, title: "Are you sure?", subtitle: nil, text: nil, type:"logout", button: "Logout") {
                        SavedData.wipeAllData()
                        AppManager.shared.logoout()
                        LoginManager().logOut()
                    }
                default: SwiftEntryKit.dismiss()
            }
        } else if popupType == "changeKasamBlock" {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "ReloadKasamBlock"), object: self, userInfo: ["blockID": array?[indexPath.row].blockID ?? "", "blockName": array?[indexPath.row].blockName ?? ""])
            SwiftEntryKit.dismiss()
        } else if popupType == "categoryOptions" {
            categoryChosen = Icons.categoryIcons[indexPath.row]
            NotificationCenter.default.post(name: Notification.Name(rawValue: "SaveCategory"), object: self)
            SwiftEntryKit.dismiss()
        }
    }
}

extension NSObject {
    var className: String {
        return String(describing: type(of: self))
    }
    
    class var className: String {
        return String(describing: self)
    }
}
