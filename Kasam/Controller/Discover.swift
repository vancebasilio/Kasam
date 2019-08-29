//
//  DiscoverViewController.swift
//  Kasam 1.0
//
//  Created by Vance Basilio on 2019-04-21.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Firebase
import SkeletonView

class DiscoverViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var discoverCollection: UICollectionView!
    @IBOutlet weak var categoryCollection: UICollectionView!
    
    var freeKasamArray: [freeKasamFormat] = []
    var expertKasamArray: [expertKasamFormat] = []
    var kasamIDGlobal: String = ""
    var kasamTitleGlobal: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getFreeKasams()
        getExpertKasams()
        let sendValue = ProfileViewController()
        sendValue.profilePicture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    //Number of cells
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == discoverCollection {
            return freeKasamArray.count
        } else {
            return expertKasamArray.count
        }
    }
    
    //Populate cells
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == discoverCollection {
            let block = freeKasamArray[indexPath.row]
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FreeKasamCell", for: indexPath) as! DiscoverHorizontalCell
            cell.setBlock(cell: block)
            return cell
        } else {
            let block = expertKasamArray[indexPath.row]
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExpertKasamCell", for: indexPath) as! DiscoverCategoryCell
            cell.setBlock(cell: block)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == discoverCollection {
            let kasamID = freeKasamArray[indexPath.row].kasamID
            let kasamName = freeKasamArray[indexPath.row].title
            kasamTitleGlobal = kasamName
            kasamIDGlobal = kasamID
            self.performSegue(withIdentifier: "goToKasam", sender: indexPath)
        } else {
            let kasamID = expertKasamArray[indexPath.row].kasamID
            let kasamName = expertKasamArray[indexPath.row].title
            kasamTitleGlobal = kasamName
            kasamIDGlobal = kasamID
            self.performSegue(withIdentifier: "goToKasam", sender: indexPath)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToKasam" {
            let kasamTransferHolder = segue.destination as! KasamHolder
            kasamTransferHolder.kasamID = kasamIDGlobal
        }
    }
    
    func getFreeKasams() {
        freeKasamArray.removeAll()
        let categoryDB = Database.database().reference().child("Coach-Kasams")
        categoryDB.queryOrdered(byChild: "Type").queryEqual(toValue: "Free").observe(.childAdded) { (snapshot) in
            if let value = snapshot.value as? [String: Any] {
                let imageURL = URL(string: value["Image"] as? String ?? "")
                let categoryBlock = freeKasamFormat(title: value["Title"] as? String ?? "", image: imageURL!, rating: value["Rating"] as! String, creator: value["CreatorName"] as? String ?? "", kasamID: value["KasamID"] as? String ?? "")
                self.freeKasamArray.append(categoryBlock)
                self.discoverCollection.reloadData()
            }
        }
    }
    
    func getExpertKasams() {
        expertKasamArray.removeAll()
        let kasamDB = Database.database().reference().child("Coach-Kasams")
        kasamDB.queryOrdered(byChild: "Type").queryEqual(toValue: "Expert").observe(.childAdded) { (snapshot) in
            if let value = snapshot.value as? [String: Any] {
                let imageURL = URL(string: value["Image"] as? String ?? "")
                let kasam = expertKasamFormat(title: value["Title"] as? String ?? "", image: imageURL!, rating: value["Rating"] as! String, creator: value["CreatorName"] as? String ?? "", kasamID: value["KasamID"] as? String ?? "")
                self.expertKasamArray.append(kasam)
                self.categoryCollection.reloadData()
            }
        }
    }
    
    func getCategoryData() {
        freeKasamArray.removeAll()
        let categoryDB = Database.database().reference().child("Discover").child("Categories")
        categoryDB.observe(.childAdded) { (snapshot) in
            if let value = snapshot.value as? [String: Any] {
                let imageURL = URL(string: value["Image"] as? String ?? "")
                let categoryBlock = freeKasamFormat(title: value["Title"] as? String ?? "", image: imageURL!, rating: value["Rating"] as! String, creator: value["CreatorName"] as? String ?? "", kasamID: value["KasamID"] as? String ?? "")
                self.freeKasamArray.append(categoryBlock)
                self.discoverCollection.reloadData()
            }
        }
    }
}
