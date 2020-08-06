//
//  GroupSearchController.swift
//  Kasam
//
//  Created by Vance Basilio on 2020-08-04.
//  Copyright © 2020 Vance Basilio. All rights reserved.
//

import UIKit
import FirebaseDatabase
import SwiftEntryKit

class GroupSearchController: UIViewController {
    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var selectedTableView: UITableView!
    @IBOutlet weak var dropdownTableView: UITableView!
    @IBOutlet weak var dropdownTableHeight: NSLayoutConstraint!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var dropdownTableArray: [(name: String, image: URL?, status: Double)] = []
    var existingUsersArray: [(name: String, image: URL?, status: Double)] = []
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
                DBRef.userCreator.child(member.key).child("Info").observeSingleEvent(of: .value) {(userInfo) in
                    DispatchQueue.main.async {
                        if let value = userInfo.value as? [String:Any] {
                            self.existingUsersArray.append((name: value["Name"] as! String, image: URL(string: value["ProfilePic"] as! String), status: member.value))
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
    
    @objc func touchOutside(){
        print("hell0")
    }
    
    @IBAction func closeButtonPressed(_ sender: Any) {
        SwiftEntryKit.dismiss()
    }
    
    @IBAction func doneButtonPressed(_ sender: Any) {
    }
}

extension GroupSearchController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        Database.database().reference().child("User-Emails").child((searchBar.text ?? "").MD5()).observeSingleEvent(of: .value) {(snap) in
            if snap.exists() {
                DBRef.userCreator.child(snap.value as! String).child("Info").observeSingleEvent(of: .value) {(userInfo) in
                    DispatchQueue.main.async {
                        self.dropdownTableArray.removeAll()
                        if let value = userInfo.value as? [String:Any] {
                            self.dropdownTableArray.append((name: value["Name"] as! String, image: URL(string: value["ProfilePic"] as! String), status: -2))
                        }
                        self.dropdownTableHeight.constant = CGFloat(50 * self.dropdownTableArray.count) + 20
                        self.dropdownTableView.reloadData()
                    }
                }
            }
            else {
                print("hell0 no userfound")
            }
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            self.dropdownTableHeight.constant = 0
            self.dropdownTableArray.removeAll()
        }
    }
}

extension GroupSearchController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == selectedTableView {
            return existingUsersArray.count
        } else {
            return dropdownTableArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupSearchCell") as! GroupSearchCell
        if tableView == selectedTableView {
            cell.setCell(cell: existingUsersArray[indexPath.row])
        } else {
            cell.setCell(cell: dropdownTableArray[indexPath.row])
        }
        return cell
    }
}
