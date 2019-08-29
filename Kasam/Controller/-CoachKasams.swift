//
//  CoachKasams.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-06-20.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Firebase

class CoachKasams: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var kasamSquareCollection: UICollectionView!
    
    var kasamArray: [SquareKasamFormat] = []
    var kasamIDGlobal: String = ""
    var coachID: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        getKasamsData()
    }
    
    //Number of cells
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return kasamArray.count
    }
    
    //Populate cells
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let block = kasamArray[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "KasamSquareCell", for: indexPath) as! KasamSquareCell
        cell.setBlock(cell: block)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let kasamID = kasamArray[indexPath.row].kasamID
        kasamIDGlobal = kasamID
        self.performSegue(withIdentifier: "goToKasam2", sender: indexPath)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToKasam2" {
            let kasamTransferHolder = segue.destination as! KasamHolder
            kasamTransferHolder.kasamID = kasamIDGlobal
        }
    }
    
    //Retrieves Kasams based on coach selected
    func getKasamsData() {
        Database.database().reference().child("Users").child(coachID).child("Kasams").observe(.childAdded, with: { (snapshot) in
            
            Database.database().reference().child("Coach-Kasams").child(snapshot.key).observe(.value, with: { (snapshot) in
                
                if let value = snapshot.value as? [String: Any] {
                    
                    let kasamURL = URL(string: value["Image"] as? String ?? "")
                    let kasam = SquareKasamFormat(title: value["Title"] as? String ?? "", type: value["Genre"] as? String ?? "", duration: value["Duration"] as? String ?? "", image: kasamURL!, kasamID: value["KasamID"] as! String)
                    self.kasamArray.append(kasam)
                    self.kasamSquareCollection.reloadData()
                }
            })
        })
    }

}
