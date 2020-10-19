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

class TrophiesAchieved: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    init() {super.init(nibName: type(of: self).className, bundle: nil)}
    required init?(coder aDecoder: NSCoder) {fatalError("init(coder:) has not been implemented")}
    
    var kasamID: String?
    var badgeNameArray = Array(SavedData.trophiesAchieved.keys)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //OPTION 1 - Show trophies for kasamID
        if kasamID != nil {
            if SavedData.trophiesAchieved[kasamID!] != nil {
                badgeNameArray = [kasamID!]
            } else {
                badgeNameArray = [""]               //to show "no trophies achieved" message in badge popup (for specifc kasams)
            }
        //OPTION 2 - show all trophies
        } else {
            if badgeNameArray.count == 0 {
                badgeNameArray = [""]               //to show "no trophies achieved" message in badge popup (for user profile page)
            }
        }
        let nib = UINib(nibName: "TrophiesAchievedCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "TrophiesAchievedCell")
        DispatchQueue.main.async {
            self.loadBadges()
        }
    }
    
    func loadBadges(){
        var kasamCount = 0
        for kasamName in badgeNameArray {
            var badgeCount = 0
            if SavedData.trophiesAchieved[kasamName] != nil {
                for _ in SavedData.trophiesAchieved[kasamName]!.kasamTrophies {
                    if let cell = self.tableView.cellForRow(at: IndexPath(item: badgeCount, section: kasamCount)) as? TrophiesAchievedCell {
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

extension TrophiesAchieved: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return badgeNameArray.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var label: String?
        if kasamID != nil {
            if SavedData.trophiesAchieved[kasamID!] != nil {
                label = SavedData.trophiesAchieved[kasamID!]?.kasamName
            } else {label = "No trophies achieved"}
        } else {
            if badgeNameArray != [""] {
                label = SavedData.trophiesAchieved[badgeNameArray[section]]?.kasamName
            } else {label = "No trophies achieved"}
        }
        return sectionHeader(text: label ?? "", color: .colorFive, leading: 20)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if SavedData.trophiesAchieved.count != 0 {
            return SavedData.trophiesAchieved[badgeNameArray[section]]?.kasamTrophies.count ?? 0
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrophiesAchievedCell") as! TrophiesAchievedCell
        let kasamName = badgeNameArray[indexPath.section]
        let trophy = SavedData.trophiesAchieved[kasamName]?.kasamTrophies[indexPath.row]
        cell.selectionStyle = .none
        if trophy != nil {
            cell.badgeCompletionDate.text = convertLongDateToShortYear(date: trophy!.completedDate)
            cell.badgeThreshold.text = trophy!.trophyThreshold.pluralUnit(unit: "day")
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
