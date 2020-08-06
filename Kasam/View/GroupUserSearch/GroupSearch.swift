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
    
    var dropdownTableArray:[(name: String, image: URL?)] = []
    
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
                DBRef.userCreator.child(snap.value as! String).child("Info").child("Name").observeSingleEvent(of: .value) {(userName) in
                    DispatchQueue.main.async {
                        self.dropdownTableArray.removeAll()
                        self.dropdownTableArray.append((name: userName.value as! String, image: URL(string: "")))
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
            return 0
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
            
        } else {
            cell.userName.text = dropdownTableArray[indexPath.row].name
        }
        return cell
    }
}
