//
//  KasamDetailsViewController.swift
//  Kasam 1.0
//
//  Created by Vance Basilio on 2019-04-27.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Firebase

class KasamDetailsViewController: UIViewController {

    @IBOutlet weak var kasamProfileImage: UIImageView!
    @IBOutlet weak var kasamTitle: UILabel!
    @IBOutlet weak var trackerTable: UITableView!
    
    var kasamTracker: [Tracker] = [Tracker]()
    var kasamID: String = ""
    var participantCountGlobal = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Setup Tracker BG
        trackerTable.delegate = self
        trackerTable.dataSource = self
        trackerTable.backgroundColor = .clear
        trackerTable.layer.cornerRadius = 5
        trackerTable.layer.borderWidth = 1
        trackerTable.layer.borderColor = UIColor.kasamYellow.cgColor

        getKasamData()
        getParticipants()
    }
    
    //Back Button
    @IBAction func backButton(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func getParticipants(){
        var count = 1
        let creatorDeets = Tracker(userName: (Auth.auth().currentUser?.displayName)!, progress: 23)
        self.kasamTracker.append(creatorDeets)
        
        Database.database().reference().child("KasamDB").child(kasamID).child("Participants").observe(.childAdded) { (snapshot) in
            count += 1
            let participantDeets = Tracker(userName: snapshot.key, progress: 45)
            self.kasamTracker.append(participantDeets)
            self.participantCountGlobal = count
            self.trackerTable.reloadData()
            }
    }
    
    //Retrieves Kasam Data using Kasam ID
    func getKasamData(){
        Database.database().reference().child("KasamDB").child(kasamID).observe(.value, with: { (snapshot) in
            if let value = snapshot.value as? [String: Any] {
                let title = value["Title"] as? String ?? ""
                let image = value["Image"] as? String ?? ""
                
                self.kasamTitle.text! = title
                let kasamURL = URL(string: image)
                let data = try? Data(contentsOf: kasamURL!)
                if let imageData = data {
                    let image = UIImage(data: imageData)
                    self.kasamProfileImage.image = image
                    self.kasamProfileImage.layer.cornerRadius = self.kasamProfileImage.bounds.height / 2
                    self.kasamProfileImage.clipsToBounds = true
                }
            }
        })
    }
}

//Setup Kasam Tracker
extension KasamDetailsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return kasamTracker.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let kasam = kasamTracker[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "trackingBar") as! KasamTrackerCell
    
        cell.setKasam(kasam: kasam)
        return cell
    }
}
