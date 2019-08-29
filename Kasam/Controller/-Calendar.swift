//
//  Following.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-05-11.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Firebase

class CalendarViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var kasamArray: [KasamFormat] = [KasamFormat]()
    var kasamIDGlobal: String = ""

    @IBOutlet weak var kasamTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        retrieveKasams()
        kasamTableView.register(UINib(nibName: "KasamCell", bundle: nil), forCellReuseIdentifier: "TableViewCell")
        
        let kasamUpdate = NSNotification.Name("KasamUpdate")
        NotificationCenter.default.addObserver(self, selector: #selector(FollowingViewController.reloadTableview), name: kasamUpdate, object: nil)
    }
    
    //Stops the observer
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.kasamUserRef.removeObserver(withHandle: self.kasamUserRefHandle!)
    }
    
    @objc func reloadTableview() {
        retrieveKasams()
        kasamTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as! TableViewCell
        
        cell.kasamTitle.text = kasamArray[indexPath.row].kasamTitle
        cell.kasamTiming.text = kasamArray[indexPath.row].kasamTiming
        
        let kasamURL = URL(string: kasamArray[indexPath.row].kasamImage)
        
        ImageService.getImage(withURL: kasamURL!) { image in
            cell.kasamImage.image = image
            cell.kasamImage.roundCorners([.topLeft, .topRight], radius: 10)
            cell.kasamImage.clipsToBounds = true
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return kasamArray.count
    }
    
    //When kasam clicked, goes to Kasam Details
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let kasamID = kasamArray[indexPath.row].kasamID
        kasamIDGlobal = kasamID
        self.performSegue(withIdentifier: "goToKasam", sender: indexPath)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToKasam" {
            let kasamTransferHolder = segue.destination as! KasamHolder
            kasamTransferHolder.kasamID = kasamIDGlobal
        }
    }
    
    func configureTableView(){
        kasamTableView.estimatedRowHeight = kasamTableView.rowHeight
        kasamTableView.rowHeight = UITableViewAutomaticDimension
    }
    
    var kasamUserRef: DatabaseReference! = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Kasam-Following")
    var kasamUserRefHandle: DatabaseHandle!
    
    func retrieveKasams() {
        kasamArray.removeAll()
        self.kasamUserRefHandle = self.kasamUserRef.observe(.childAdded) { (snapshot) in
            
            var timePreference = ""
            var repeatPreference = ""
            
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                if snap.key == "Repeat" {
                    repeatPreference = snap.value as! String
                } else if snap.key == "Time" {
                    timePreference = snap.value as! String
                }
            }
            
            Database.database().reference().child("Coach-Kasams").queryOrderedByKey().queryEqual(toValue: snapshot.key).observeSingleEvent(of: .childAdded, with: { (snapshot) in
                let snapshotValue = snapshot.value as! Dictionary<String,Any>
                let title = snapshotValue["Title"]!
                let image = snapshotValue["Image"]!
                let kasamID = snapshotValue["KasamID"]!
                
                let kasam = KasamFormat()
                kasam.kasamTitle = title as! String
                kasam.kasamTiming = ("\(repeatPreference) at \(timePreference)")
                kasam.kasamImage = image as! String
                kasam.kasamID = kasamID as! String
                
                self.kasamArray.append(kasam)
                self.configureTableView()
                self.kasamTableView.reloadData()
            })
        }
    }
}
