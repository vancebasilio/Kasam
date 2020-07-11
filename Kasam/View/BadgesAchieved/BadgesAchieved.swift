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
    
    var kasamID: String?
    var badgeNameArray = Array(SavedData.badgesAchieved.keys).sorted()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if kasamID != nil {
            if SavedData.kasamDict[kasamID!] != nil {
                badgeNameArray = [SavedData.kasamDict[kasamID!]!.kasamName]
            } else {
                badgeNameArray = [""]               //to show "no trophies achieved" message in badge popup (for specifc kasams)
            }
        } else {
            if badgeNameArray.count == 0 {
                badgeNameArray = [""]               //to show "no trophies achieved" message in badge popup (for user profile page)
            }
        }
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
            if SavedData.badgesAchieved[kasamName] != nil {
                for _ in SavedData.badgesAchieved[kasamName]! {
                    if let cell = self.tableView.cellForRow(at: IndexPath(item: badgeCount, section: kasamCount)) as? BadgesAchievedCell {
                        cell.badgeImage.animation = Animations.kasamBadges[1]
                        cell.badgeImage.play()
                    }
                    badgeCount += 1
                }
            }
            kasamCount += 1
        }
    }
}

extension BadgesAchieved: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return badgeNameArray.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        let newlabel = UILabel()
        newlabel.textColor = .colorFive
        newlabel.textAlignment = .left
        newlabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        newlabel.adjustsFontSizeToFitWidth = true
        if kasamID != nil {
            if SavedData.kasamDict[kasamID!] != nil {
                if SavedData.badgesAchieved[SavedData.kasamDict[kasamID!]!.kasamName]?.count != nil {
                    newlabel.text = badgeNameArray[section]
                } else {
                    newlabel.text = "No trophies achieved"
                }
            } else {
                newlabel.text = "No trophies achieved"
            }
        } else {
            if badgeNameArray != [""] {
                newlabel.text = badgeNameArray[section]
            } else {
                newlabel.text = "No trophies achieved"
            }
        }
        
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
            cell.kasamName.text = convertLongDateToShortYear(date: badge!.completedDate)
            cell.badgeDate.text = badge!.badgeThreshold.pluralUnit(unit: "day")
        }
        cell.textLabel?.textAlignment = .left
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(40)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(40)
    }
}
