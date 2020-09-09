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
    
    var dropdownUserArray: [(userID: String, name: String, image: URL?, status: Double)] = []
    var selectedUserArray: [(userID: String, name: String, image: URL?, status: Double)] = []
    var kasamID = ""
    let popTipView = PopTip()
    var popTipViewStatus = false
    
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
        popTipView.shouldDismissOnTapOutside = true
        popTipView.shouldDismissOnSwipeOutside = true
        popTipView.bubbleColor = .darkGray
        popTipView.shouldDismissOnTap = false
        popTipView.cornerRadius = 8
    }
    
    func loadExistingUsersArray(){
        selectedUserArray.removeAll()
        if SavedData.kasamDict[kasamID]?.groupTeam != nil {
            for member in SavedData.kasamDict[kasamID]!.groupTeam! {
                DBRef.users.child(member.key).child("Info").observeSingleEvent(of: .value) {(userInfo) in
                    DispatchQueue.main.async {
                        if let value = userInfo.value as? [String:Any] {
                            self.selectedUserArray.append((userID: member.key,name: value["Name"] as! String, image: URL(string: value["ProfilePic"] as! String), status: member.value))
                        }
                        if self.selectedUserArray.count == SavedData.kasamDict[self.kasamID]!.groupTeam!.count {
                            self.selectedUserArray = self.selectedUserArray.sorted(by: {$0.status > $1.status})
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
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.dropdownTableHeight.constant = self.selectedTableView.frame.height
        self.dropdownTableView.reloadData()
        selectedTableView.isUserInteractionEnabled = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        let touch: UITouch? = touches.first
        if touch?.view != dropdownTableView {
            self.dropdownTableHeight.constant = 20
            self.dropdownTableView.reloadData()
            selectedTableView.isUserInteractionEnabled = true
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            self.dropdownTableHeight.constant = 20
            self.dropdownUserArray.removeAll()
            self.dropdownTableView.reloadData()
            selectedTableView.isUserInteractionEnabled = true
        } else if searchText.contains(".com") {
            Database.database().reference().child("User-Emails").child((searchBar.text ?? "").MD5()).observeSingleEvent(of: .value) {(snap) in
                if snap.exists() {
                    DBRef.users.child(snap.value as! String).child("Info").observeSingleEvent(of: .value) {(userInfo) in
                        DispatchQueue.main.async {
                            if let value = userInfo.value as? [String:Any] {
                                var status = -2.0
                                if SavedData.kasamDict[self.kasamID]?.groupTeam?[snap.value as! String] != nil {
                                    status = SavedData.kasamDict[self.kasamID]!.groupTeam![snap.value as! String]!
                                }
                                self.dropdownUserArray.append((userID: snap.value as! String,name: value["Name"] as! String, image: URL(string: value["ProfilePic"] as! String), status: status))
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
            self.dropdownUserArray.removeAll()
            self.dropdownTableView.reloadData()
        }
    }
}

extension GroupSearchController: UITableViewDelegate, UITableViewDataSource, GroupCellDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == selectedTableView {
            return selectedUserArray.count
        } else {
            if dropdownUserArray.count == 0 {
                return 2
            } else {
                return dropdownUserArray.count + 1
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == selectedTableView {
            return 50
        } else {
            if indexPath.row == 0 {
                return 40
            } else {
                return 50
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupSearchCell") as! GroupSearchCell
        cell.row = indexPath.row
        cell.cellDelegate = self
        if tableView == selectedTableView {
            cell.setCell(cell: selectedUserArray[indexPath.row])
            cell.cellTable = "selected"
        } else {
            cell.cellTable = "dropdown"
            if indexPath.row == 0 {
                cell.firstCell()
            } else {
                if dropdownUserArray.count == 0 {
                    cell.setPlaceholder()
                } else {
                    cell.setCell(cell: dropdownUserArray[indexPath.row - 1])
                }
            }
        }
        return cell
    }
    
    func statusButtonPressed(row: Int, status: Double, userID: String) {
        //User being invited
        if status == -2 {
            dropdownTableView.beginUpdates()
            dropdownUserArray[row - 1].status = -1.0
            dropdownTableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .fade)
            dropdownTableView.endUpdates()
            
            //Add kasam to user group following
            DBRef.users.child(userID).child("Group-Following").child(SavedData.kasamDict[kasamID]!.groupID!).child("Time").setValue(SavedData.kasamDict[kasamID]?.startTime)
            
            //Add user to group kasam
            DBRef.groupKasams.child(SavedData.kasamDict[kasamID]!.groupID!).child("Info").child("Team").child(userID).setValue(-1.0)
            
            //Send notification invite
            DBRef.users.child(userID).child("Info").child("fcmToken").observeSingleEvent(of: .value) {(fcmTokenSnap) in
                if let fcmToken = fcmTokenSnap.value as? String {
                    let sender = PushNotificationSender()
                    sender.sendPushNotification(to: fcmToken, title: "Group Kasam Invitation", body: "\(Auth.auth().currentUser?.displayName ?? "") is inviting you to join the \(SavedData.kasamDict[self.kasamID]?.kasamName ?? "") kasam")
                }
            }
            
            //Add user to internal app tracking dictionary
            SavedData.kasamDict[kasamID]?.groupTeam?[userID] = -1
            loadExistingUsersArray()
        }
    }
    
    func showPopTipRemove(row: Int, frame: CGRect) {
        if SavedData.userID == SavedData.kasamDict[kasamID]!.groupAdmin {
            popTipView.appearHandler = {popTip in self.popTipViewStatus = true}
            popTipView.dismissHandler = {popTip in self.popTipViewStatus = false}
            let customView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 20))
            let button:UIButton = UIButton(frame: customView.frame)
            button.backgroundColor = .clear
            button.setTitle("Remove", for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
            button.addTarget(self, action:#selector(buttonClicked), for: .touchUpInside)
            button.tag = row
            customView.addSubview(button)
            if popTipViewStatus == false {
                let frameY = self.selectedTableView.rectForRow(at: IndexPath(row: row, section: 0)).minY + selectedTableView.frame.minY + 5
                let modifiedFrame = CGRect(x: frame.midX - 10, y: frameY, width: frame.width, height: frame.height)
                popTipView.show(customView: customView, direction: .down, in: view, from: modifiedFrame, duration: 3)}
            else {popTipView.hide()}
        }
    }
    
    @objc func buttonClicked(sender:UIButton) {
        removeUser(row: sender.tag, userID: selectedUserArray[sender.tag].userID)
        popTipView.hide()
    }
    
    func removeUser(row:Int, userID: String) {
        DBRef.groupKasams.child(SavedData.kasamDict[kasamID]!.groupID!).child("Info").child("Team").child(userID).setValue(nil)
        DBRef.users.child(userID).child("Group-Following").child(SavedData.kasamDict[kasamID]!.groupID!).setValue(nil)
        SavedData.kasamDict[kasamID]?.groupTeam?[userID] = nil
        if let index = selectedUserArray.index(where: {$0.userID == userID}) {
            selectedUserArray.remove(at: index)
            selectedTableView.deleteRows(at: [IndexPath(row: row, section: 0)], with: .fade)
        }
        if let index = dropdownUserArray.index(where: {$0.userID == userID}) {
            dropdownUserArray[index].status = -2
        }
    }
}
