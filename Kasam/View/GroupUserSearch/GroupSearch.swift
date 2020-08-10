//
//  GroupSearchController.swift
//  Kasam
//
//  Created by Vance Basilio on 2020-08-04.
//  Copyright © 2020 Vance Basilio. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import SwiftEntryKit
import AMPopTip

class GroupSearchController: UIViewController {
    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var selectedTableView: UITableView!
    @IBOutlet weak var dropdownTableView: UITableView!
    @IBOutlet weak var dropdownTableHeight: NSLayoutConstraint!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var dropdownTableArray: [(userID: String, name: String, image: URL?, status: Double)] = []
    var existingUsersArray: [(userID: String, name: String, image: URL?, status: Double)] = []
    var kasamID = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        doneButton.layer.cornerRadius = 20
        closeButton?.setIcon(icon: .fontAwesomeSolid(.times), iconSize: 18, color: UIColor.init(hex: 0x79787e), forState: .normal)
        let nib = UINib(nibName: "GroupSearchCell", bundle: nil)
        dropdownTableView.register(nib, forCellReuseIdentifier: "GroupSearchCell")
        selectedTableView.register(nib, forCellReuseIdentifier: "GroupSearchCell")
        dropdownTableView.layer.shadowColor = UIColor.colorFour.cgColor
        dropdownTableView.layer.shadowOffset = CGSize.zero
        dropdownTableView.layer.shadowOpacity = 0.8
        dropdownTableView.layer.cornerRadius = 10
        searchBar.autocapitalizationType = .none
        loadExistingUsersArray()
    }
    
    func loadExistingUsersArray(){
        existingUsersArray.removeAll()
        if SavedData.kasamDict[kasamID]?.groupTeam != nil {
            for member in SavedData.kasamDict[kasamID]!.groupTeam! {
                DBRef.userBase.child(member.key).child("Info").observeSingleEvent(of: .value) {(userInfo) in
                    DispatchQueue.main.async {
                        if let value = userInfo.value as? [String:Any] {
                            self.existingUsersArray.append((userID: member.key,name: value["Name"] as! String, image: URL(string: value["ProfilePic"] as! String), status: member.value))
                        }
                        if self.existingUsersArray.count == SavedData.kasamDict[self.kasamID]!.groupTeam!.count {
                            self.existingUsersArray = self.existingUsersArray.sorted(by: {$0.status > $1.status})
                            self.selectedTableView.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func closeButtonPressed(_ sender: Any) {
        SwiftEntryKit.dismiss()
    }
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        SwiftEntryKit.dismiss()
    }
}

extension GroupSearchController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            self.dropdownTableHeight.constant = 0
            self.dropdownTableArray.removeAll()
            self.dropdownTableView.reloadData()
        } else if searchText.contains(".com") {
            Database.database().reference().child("User-Emails").child((searchBar.text ?? "").MD5()).observeSingleEvent(of: .value) {(snap) in
                if snap.exists() {
                    DBRef.userBase.child(snap.value as! String).child("Info").observeSingleEvent(of: .value) {(userInfo) in
                        DispatchQueue.main.async {
                            if let value = userInfo.value as? [String:Any] {
                                var status = -2.0
                                if SavedData.kasamDict[self.kasamID]?.groupTeam?[snap.value as! String] != nil {
                                    status = SavedData.kasamDict[self.kasamID]!.groupTeam![snap.value as! String]!
                                }
                                self.dropdownTableArray.append((userID: snap.value as! String,name: value["Name"] as! String, image: URL(string: value["ProfilePic"] as! String), status: status))
                            }
                            self.dropdownTableView.reloadData()
                        }
                    }
                } else {
                    self.dropdownTableView.reloadData()
                    print("hell0 no userfound")
                }
            }
        } else {
            self.dropdownTableHeight.constant = self.selectedTableView.frame.height
            self.dropdownTableArray.removeAll()
            self.dropdownTableView.reloadData()
        }
    }
}

extension GroupSearchController: UITableViewDelegate, UITableViewDataSource, GroupCellDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == selectedTableView {
            return existingUsersArray.count
        } else {
            if dropdownTableArray.count == 0 {
                return 1
            } else {
                return dropdownTableArray.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupSearchCell") as! GroupSearchCell
        cell.row = indexPath.row
        cell.cellDelegate = self
        if tableView == selectedTableView {
            cell.setCell(cell: existingUsersArray[indexPath.row])
        } else {
            if dropdownTableArray.count == 0 {
                cell.setPlaceholder()
            } else {
                cell.setCell(cell: dropdownTableArray[indexPath.row])
            }
        }
        return cell
    }
    
    func statusButtonPressed(row: Int, status: Double, userID: String) {
        if let cell = dropdownTableView.cellForRow(at: IndexPath(item: row, section: 0)) as? GroupSearchCell {
            dropdownTableView.beginUpdates()
            //User being invited
            if status == -2 {
                cell.checkBox.setIcon(icon: .fontAwesomeRegular(.checkCircle), iconSize: 30, color: .dayYesColor, forState: .normal)
                DBRef.userBase.child(userID).child("Group-Following").child(SavedData.kasamDict[kasamID]!.groupID!).child("Time").setValue(SavedData.kasamDict[kasamID]?.startTime)
                DBRef.groupKasams.child(SavedData.kasamDict[kasamID]!.groupID!).child("Info").child("Team").child(userID).setValue(-1.0)
                SavedData.kasamDict[kasamID]?.groupTeam?[userID] = -1
                loadExistingUsersArray()
            }
            dropdownTableView.endUpdates()
        }
    }
    
    func removeUser(row:Int, userID: String) {
        DBRef.groupKasams.child(SavedData.kasamDict[kasamID]!.groupID!).child("Info").child("Team").child(userID).setValue(nil)
        DBRef.userBase.child(userID).child("Group-Following").child(SavedData.kasamDict[kasamID]!.groupID!).setValue(nil)
        SavedData.kasamDict[kasamID]?.groupTeam?[userID] = nil
        loadExistingUsersArray()
    }
}
