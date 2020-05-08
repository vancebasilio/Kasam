//
//  EmbeddedViewController.swift
//  SwiftEntryKitDemo
//
//  Created by Daniel Huri on 3/15/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import SwiftEntryKit
import Lottie

class BadgesAchieved: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    init() {super.init(nibName: type(of: self).className, bundle: nil)}
    required init?(coder aDecoder: NSCoder) {fatalError("init(coder:) has not been implemented")}
    
    var badgeNameArray = Array(SavedData.badgesAchieved.keys)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let nib = UINib(nibName: "BadgesAchievedCellTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "BadgesAchievedCell")
        DispatchQueue.main.async {
            self.loadBadges()
        }
    }
    
    func loadBadges(){
        var kasamCount = 0
        for kasamName in badgeNameArray {
            var badgeCount = 0
            for badge in SavedData.badgesAchieved[kasamName]! {
                if let cell = self.tableView.cellForRow(at: IndexPath(item: badgeCount, section: kasamCount)) as? BadgesAchievedCell {
                    cell.badgeImage.animation = Animations.kasamBadges[badge.badgeLevel]
                    cell.badgeImage.play()
                }
                badgeCount += 1
            }
            kasamCount += 1
        }
    }
}

extension BadgesAchieved: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return SavedData.badgesAchieved.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        let newlabel = UILabel()
        newlabel.textColor = .colorFive
        newlabel.textAlignment = .left
        newlabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        newlabel.adjustsFontSizeToFitWidth = true
        newlabel.text = badgeNameArray[section]

        headerView.addSubview(newlabel)
        newlabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addConstraint(NSLayoutConstraint(item: newlabel, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: headerView, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1.0, constant: 20.0))
        
        headerView.addConstraint(NSLayoutConstraint(item: newlabel, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.greaterThanOrEqual, toItem: headerView, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1.0, constant: 20.0))
        
        headerView.addConstraint(NSLayoutConstraint(item: newlabel, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: headerView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: 0))
        
        headerView.addConstraint(NSLayoutConstraint(item: newlabel, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: headerView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: 0))
      
        return headerView
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if SavedData.badgesAchieved.count != 0 {
            return SavedData.badgesAchieved[badgeNameArray[section]]?.count ?? 0
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BadgesAchievedCell") as! BadgesAchievedCell
        let kasamName = badgeNameArray[indexPath.section]
        let badge = SavedData.badgesAchieved[kasamName]?[indexPath.row]
        cell.selectionStyle = .none
        if badge != nil {
            if badge!.badgeThreshold == 1 {
                cell.kasamName.text = "\(badge!.badgeThreshold) day"
            } else {
                cell.kasamName.text = "\(badge!.badgeThreshold) days"
            }
            cell.badgeDate.text = convertLongDateToShortYear(date: badge!.completedDate)
        } else {
            cell.textLabel?.setIcon(prefixText: "  ", icon: .fontAwesomeSolid(.signOutAlt), postfixText: "  Log Out", size: 20)
        }
        cell.textLabel?.textAlignment = .left
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "GoToCreateKasam"), object: self)
            SwiftEntryKit.dismiss()
        } else if indexPath.row == 1 {
            let popupImage = UIImage.init(icon: .fontAwesomeSolid(.doorOpen), size: CGSize(width: 30, height: 30), textColor: .white)
            showPopupConfirmation(title: "Are you sure?", description: "", image: popupImage, buttonText: "Logout") {(success) in
                AppManager.shared.logoout()
                LoginManager().logOut()
                SwiftEntryKit.dismiss()
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(40)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(30)
    }
}
