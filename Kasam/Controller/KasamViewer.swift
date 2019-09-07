//
//  KasamViewer.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-09-05.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Firebase
import SwiftIcons

class KasamViewer: UIViewController {
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var kasamViewerTable: UITableView!
    
    var activityBlocks: [KasamActivityCellFormat] = []
    var kasamID = ""
    var blockID = ""
    var activityRef: DatabaseReference!
    var activityRefHandle: DatabaseHandle!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(kasamID, blockID)
        getBlockActivities()
        UIApplication.shared.endIgnoringInteractionEvents()
        closeButton?.setIcon(icon: .fontAwesomeSolid(.times), iconSize: 20, color: UIColor.init(hex: 0x79787e), forState: .normal)
    }
    
    @IBAction func closeButton(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    func getBlockActivities(){
        activityBlocks.removeAll()
        self.activityRef = Database.database().reference().child("Coach-Kasams").child(kasamID).child("Blocks").child(blockID).child("Activity")
        self.activityRefHandle = activityRef.observe(.value) { (snapshot) in
            if let value = snapshot.value as? [String: String] {
                print("i'm in")
                let activity = KasamActivityCellFormat(kasamID: self.kasamID, blockID: self.blockID, title: value["Title"] ?? "", description: value["Description"] ?? "", totalNo: value["Metric"] ?? "", image: value["Image"] ?? "")
                self.activityBlocks.append(activity)
                self.kasamViewerTable.reloadData()
            }
        }
        self.kasamViewerTable.reloadData()
    }
}

extension KasamViewer: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activityBlocks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let activity = activityBlocks[indexPath.row]
        let cell = kasamViewerTable.dequeueReusableCell(withIdentifier: "KasamViewerCell") as! KasamViewerCell
        cell.setKasamViewer(activity: activity)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.frame.size.height
    }
}
