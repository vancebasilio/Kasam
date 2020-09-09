//
//  DiscoverViewController.swift
//  Kasam 1.0
//
//  Created by Vance Basilio on 2019-04-21.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class DiscoverViewController: UIViewController {
    
    @IBOutlet weak var categoryCollection: UICollectionView!
    @IBOutlet weak var discoverTableView: UITableView!
    @IBOutlet weak var discoverTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var expertPageControl: UIPageControl!
    @IBOutlet weak var expertHeight: NSLayoutConstraint!
    @IBOutlet weak var contentView: NSLayoutConstraint!
    
    var discoverKasamDict = [String:[discoverKasamFormat]]()
    var featuredKasamArray: [discoverKasamFormat] = []
    var kasamIDGlobal: String = ""
    var kasamTitleGlobal: String = ""
    var timer = Timer()
    var counter = 0
    var userKasam = false
    
    var discoverFilledHeight = CGFloat(240)
    var discoverEmptyHeight = CGFloat(0)
    var featureViewHeight = CGFloat(0)
    var rowCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setHeights()
        getDiscoverFeatured()
        getDiscoverKasams()
        setupNavBar(clean: false)
        notificationsSetup()
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: 4.0, target: self, selector: #selector(self.changeImage), userInfo: nil, repeats: true)
        }
    }
    
    func notificationsSetup(){
        let popDiscoverToRoot = Notification.Name("PopDiscoverToRoot")
        NotificationCenter.default.addObserver(self, selector: #selector(DiscoverViewController.resetToTopView), name: popDiscoverToRoot, object: nil)
    }
    
    @objc func resetToTopView(){
        _ = navigationController?.popToViewController(self, animated: true)
    }
    
    func setHeights(){
        discoverFilledHeight = (view.bounds.size.width / 2.3) + 60
        featureViewHeight = view.bounds.size.width * (8/13) + 61 + 10
        rowCount = Assets.discoverCriteria.count
    }
    
    //Puts the nav bars back
    override func viewWillAppear(_ animated: Bool) {
        if let navBar = self.navigationController?.navigationBar {
            navBar.backgroundColor = UIColor.white.withAlphaComponent(100)
            navBar.isTranslucent = false
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        DBRef.coachKasams.removeAllObservers()
    }

    //Table Resizing----------------------------------------------------------------------
    
    func updateContentTableHeight(){
        self.updateContentViewHeight(contentViewHeight: contentView, tableViewHeight: discoverTableViewHeight, tableRowHeight: discoverFilledHeight, additionalTableHeight: discoverEmptyHeight, rowCount: rowCount, additionalHeight: featureViewHeight)
    }

    //make the expert slider automatically scroll
    @objc func changeImage() {
        if counter < featuredKasamArray.count {
            let index = IndexPath.init(item: counter, section: 0)
            self.categoryCollection.scrollToItem(at: index, at: .centeredHorizontally, animated: true)
            expertPageControl.currentPage = counter
            counter += 1
        } else {
            counter = 0
            let index = IndexPath.init(item: counter, section: 0)
            self.categoryCollection.scrollToItem(at: index, at: .centeredHorizontally, animated: false)
            expertPageControl.currentPage = counter
            counter = 1
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        expertPageControl?.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        expertPageControl?.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToKasam" {
            let kasamTransferHolder = segue.destination as! KasamHolder
            kasamTransferHolder.kasamID = kasamIDGlobal
            kasamTransferHolder.userKasam = userKasam
        }
    }
    
    func getDiscoverFeatured(){
        if Assets.featuredKasams != nil {
            for kasamID in Assets.featuredKasams! {
                DBRef.coachKasams.child(kasamID).child("Info").observe(.value) {(snapshot) in
                    let value = snapshot.value as? Dictionary<String,Any>
                    let kasam = discoverKasamFormat(title: value?["Title"] as? String ?? "", image: URL(string: value?["Image"] as? String ?? "") ?? URL(string:PlaceHolders.kasamLoadingImageURL)!, rating: value?["Rating"] as? String ?? "5", creator: value?["CreatorName"] as? String ?? "", kasamID: value?["KasamID"] as? String ?? "", genre: value?["Genre"] as? String ?? "Fitness")
                    self.featuredKasamArray.append(kasam)
                    self.categoryCollection.reloadData()
                }
            }
        }
    }
    
    func getDiscoverKasams() {
        discoverKasamDict.removeAll()
        for rowCount in 0...(Assets.discoverCriteria.count - 1) {
            let genre = Assets.discoverCriteria[rowCount]
            if genre != "My Kasams" {
                DBRef.coachKasamIndex.child(genre).observe(.childAdded) {(kasamID) in
                    DBRef.coachKasams.child(kasamID.key).child("Info").observeSingleEvent(of: .value) {(snapshot) in
                        if let value = snapshot.value as? [String: Any] {
                            let kasam = discoverKasamFormat(title: value["Title"] as? String ?? "", image: (URL(string: value["Image"] as? String ?? "") ?? URL(string: PlaceHolders.kasamHeaderPlaceholderURL))!, rating: value["Rating"] as? String ?? "5", creator: nil, kasamID: value["KasamID"] as? String ?? "", genre: value["Genre"] as? String ?? "Fitness")
                            if self.discoverKasamDict[kasam.genre] == nil {self.discoverKasamDict[kasam.genre] = [kasam]}
                            else {self.discoverKasamDict[kasam.genre]!.append(kasam)}
                            self.discoverTableView.reloadRows(at: [IndexPath(item: rowCount, section: 0)], with: .fade)
                        }
                    }
                }
            } else {
                getMyKasams()
            }
        }
    }
    
    func getMyKasams() {
        discoverKasamDict["My Kasams"] = []
        DBRef.userKasams.observeSingleEvent(of: .value) {(snap) in
            if snap.exists() {
                self.addUserKasam(snap: snap)
                if self.discoverKasamDict.count == snap.childrenCount {
                    self.updateContentTableHeight()
                }
            } else {
                //Incase there was a user kasam, that's now being deleted, so this view needs to be reloaded
                if self.discoverKasamDict["My Kasams"]?.count == 0 {self.rowCount -= 1; self.discoverEmptyHeight = CGFloat(120)}
                self.updateContentTableHeight()
                self.discoverTableView.reloadRows(at: [IndexPath(item: Assets.discoverCriteria.count - 1, section: 0)], with: .fade)
            }
        }
        
        DBRef.userKasams.observe(.childAdded) {(snap) in
            self.addUserKasam(snap: snap)
        }
        
        DBRef.userKasams.observe(.childRemoved) {(snap) in
            if let index = self.discoverKasamDict["My Kasams"]?.index(where: {$0.kasamID == snap.key}) {
                self.discoverKasamDict["My Kasams"]?.remove(at: index)
                if self.discoverKasamDict["My Kasams"]?.count == 0 {self.rowCount -= 1; self.discoverEmptyHeight = CGFloat(120)}
                self.discoverTableView.reloadRows(at: [IndexPath(item: Assets.discoverCriteria.count - 1, section: 0)], with: .fade)
                self.updateContentTableHeight()
            }
        }
    }
    
    func addUserKasam(snap: DataSnapshot) {
        if let kasamValue = snap.value as? [String: Any] {
            if let value = kasamValue["Info"] as? [String: Any] {
                let imageURL = URL(string: value["Image"] as? String ?? "")
                let kasam = discoverKasamFormat(title: value["Title"] as? String ?? "", image: (imageURL ?? URL(string: PlaceHolders.kasamHeaderPlaceholderURL))!, rating: value["Rating"] as? String ?? "5", creator: nil, kasamID: snap.key, genre: value["Genre"] as? String ?? "Fitness")
                self.discoverKasamDict["My Kasams"]!.append(kasam)
                if self.discoverKasamDict["My Kasams"] != nil {self.rowCount = Assets.discoverCriteria.count; self.discoverEmptyHeight = CGFloat(0)}
                self.updateContentTableHeight()
                self.discoverTableView.reloadRows(at: [IndexPath(item: Assets.discoverCriteria.count - 1, section: 0)], with: .fade)
            }
        }
    }
}

//TableView-----------------------------------------------------------

extension DiscoverViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Assets.discoverCriteria.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DiscoverKasamCell") as! DiscoverKasamCell
        cell.DiscoverCategoryTitle.text = Assets.discoverCriteria[indexPath.row]
        if Assets.discoverCriteria[indexPath.row] == "My Kasams" && discoverKasamDict["My Kasams"]?.count == 0 {
            cell.DiscoverCategoryTitle.text = ""
            cell.disableSwiping()
        } else {
            cell.enableSwiping()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if Assets.discoverCriteria[indexPath.row] == "My Kasams" && discoverKasamDict["My Kasams"]?.count == 0 {
            return discoverEmptyHeight      //to show the create kasam button
        } else {
            return discoverFilledHeight
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tableViewCell = cell as? DiscoverKasamCell else { return }
        tableViewCell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.row)
    }
}

extension DiscoverViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    //Number of cells
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == categoryCollection {
            let count = featuredKasamArray.count
            expertPageControl.numberOfPages = count
            expertPageControl.isHidden = !(count > 1)
            return featuredKasamArray.count
        } else {
            if let count = discoverKasamDict[Assets.discoverCriteria[collectionView.tag]]?.count {
                if count == 0 {return 1}
                else {return count}
            } else {
                return 1
            }
        }
    }
    
    //Populate cells
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == categoryCollection {
            let block = featuredKasamArray[indexPath.row]
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FeaturedKasamCell", for: indexPath) as! DiscoverCategoryCell
            cell.setBlock(cell: block)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DiscoverKasamCell", for: indexPath) as! DiscoverHorizontalCell
            if Assets.discoverCriteria[collectionView.tag] == "My Kasams" && discoverKasamDict["My Kasams"]?.count == 0 {
                cell.setPlaceholder()
            } else if discoverKasamDict[Assets.discoverCriteria[collectionView.tag]]?[indexPath.row] != nil {
                let block = discoverKasamDict[Assets.discoverCriteria[collectionView.tag]]?[indexPath.row]
                cell.setBlock(cell: block!)
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == categoryCollection {
            let kasamID = featuredKasamArray[indexPath.row].kasamID
            let kasamName = featuredKasamArray[indexPath.row].title
            kasamTitleGlobal = kasamName
            kasamIDGlobal = kasamID
            self.performSegue(withIdentifier: "goToKasam", sender: indexPath)
        } else {
            //Creating a new kasam
            if Assets.discoverCriteria[collectionView.tag] == "My Kasams" && discoverKasamDict["My Kasams"]?.count == 0 {
                goToCreateNewKasam(type: "basic")
            } else {
                //User kasam
                if Assets.discoverCriteria[collectionView.tag] == "My Kasams" && discoverKasamDict["My Kasams"] != nil {userKasam = true}
                else {userKasam = false}
                //Coach kasam
                let kasamID = discoverKasamDict[Assets.discoverCriteria[collectionView.tag]]?[indexPath.row].kasamID
                let kasamName = discoverKasamDict[Assets.discoverCriteria[collectionView.tag]]?[indexPath.row].title
                kasamTitleGlobal = kasamName!
                kasamIDGlobal = kasamID!
                self.performSegue(withIdentifier: "goToKasam", sender: indexPath)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == categoryCollection {
            expertHeight.constant = (view.bounds.size.width * (8/13))
            return CGSize(width: view.bounds.size.width, height: view.bounds.size.width * (8/13))
        }
        else {
            //for TableView collection view:
            viewSafeAreaInsetsDidChange()
            if discoverKasamDict[Assets.discoverCriteria[collectionView.tag]]?.count == 0 {
                return CGSize(width: view.bounds.size.width - 30, height: 95)
            } else {
                return CGSize(width: view.bounds.size.width / 2, height: view.bounds.size.width / 2.3)
            }
        }
    }
}
