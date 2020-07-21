//
//  DiscoverViewController.swift
//  Kasam 1.0
//
//  Created by Vance Basilio on 2019-04-21.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Firebase

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
    
    var discoverFilledHeight = CGFloat(120)
    var discoverEmptyHeight = CGFloat(120)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        discoverFilledHeight = (view.bounds.size.width / 2.3) + 60
        getDiscoverFeatured()
        getDiscoverKasams()
        getMyKasams()
        setupNavBar(clean: false)
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: 4.0, target: self, selector: #selector(self.changeImage), userInfo: nil, repeats: true)
        }
    }
    
    func notificationsSetup(){
        let getUserKasams = NSNotification.Name("GetUserKasams")
        NotificationCenter.default.addObserver(self, selector: #selector(DiscoverViewController.getMyKasams), name: getUserKasams, object: nil)
        
        let popDiscoverToRoot = Notification.Name("PopDiscoverToRoot")
        NotificationCenter.default.addObserver(self, selector: #selector(DiscoverViewController.resetToTopView), name: popDiscoverToRoot, object: nil)
    }
    
    @objc func resetToTopView(){
        _ = navigationController?.popToViewController(self, animated: true)
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
        //sets the height of the whole tableview, based on the numnber of rows
        var height = CGFloat(0)
        for row in Assets.discoverCriteria {
            if discoverKasamDict[row] == nil {height += discoverEmptyHeight}
            else {height += discoverFilledHeight}
        }
        self.discoverTableViewHeight.constant = height
        
        //elongates the entire scrollview, based on the tableview height
        let frame = self.view.safeAreaLayoutGuide.layoutFrame
        let featureViewHeight = view.bounds.size.width * (8/13)
        let contentViewHeight = discoverTableViewHeight.constant + featureViewHeight + 61 + 10  //10 is the additional space from the bottom and 61 is the height of the Discover Title
        if contentViewHeight > frame.height {
            contentView.constant = contentViewHeight
        } else if contentViewHeight <= frame.height {
            let diff = frame.height - contentViewHeight
            contentView.constant = contentViewHeight + diff + 1
        }
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
        } else if segue.identifier == "goToCreateKasam" {
            let segueTransferHolder = segue.destination as! NewKasamPageController
            segueTransferHolder.kasamType = "basic"
        }
    }
    
    func getDiscoverFeatured(){
        if Assets.featuredKasams != nil {
            for kasam in Assets.featuredKasams! {
                DBRef.coachKasams.child(kasam).observe(.value) {(snapshot) in
                    let value = snapshot.value as? Dictionary<String,Any>
                    let kasam = discoverKasamFormat(title: value?["Title"] as? String ?? "", image: URL(string: value?["Image"] as? String ?? "") ?? URL(string:PlaceHolders.kasamLoadingImageURL)!, rating: value?["Rating"] as? String ?? "5", creator: value?["CreatorName"] as? String ?? "", kasamID: value?["KasamID"] as? String ?? "", genre: value?["Genre"] as? String ?? "Fitness")
                    self.featuredKasamArray.append(kasam)
                    self.categoryCollection.reloadData()
                }
            }
        }
    }
    
    func getDiscoverKasams() {
        var count = 0
        discoverKasamDict.removeAll()
        DBRef.coachKasams.observeSingleEvent(of: .value, with:{(snap) in
            DBRef.coachKasams.observe(.childAdded) {(snapshot) in
                if let value = snapshot.value as? [String: Any] {
                    let imageURL = URL(string: value["Image"] as? String ?? "")
                    let kasam = discoverKasamFormat(title: value["Title"] as? String ?? "", image: (imageURL ?? URL(string: PlaceHolders.kasamHeaderPlaceholderURL))!, rating: value["Rating"] as? String ?? "5", creator: nil, kasamID: value["KasamID"] as? String ?? "", genre: value["Genre"] as? String ?? "Fitness")
                    count += 1
                    if self.discoverKasamDict[kasam.genre] == nil {self.discoverKasamDict[kasam.genre] = [kasam]}
                    else {self.discoverKasamDict[kasam.genre]!.append(kasam)}
                    if count == snap.childrenCount {
                        self.updateContentTableHeight()
                        self.discoverTableView.reloadData()
                    }
                }
            }
        })
    }
    
    @objc func getMyKasams() {
        var count = 0
        discoverKasamDict["My Kasams"] = nil
        DBRef.userKasams.observeSingleEvent(of: .value, with:{(snapshot) in
            if snapshot.exists() {
                DBRef.userKasams.observe(.childAdded) {(snap) in
                    if let value = snap.value as? [String: Any] {
                        let imageURL = URL(string: value["Image"] as? String ?? "")
                        let kasam = discoverKasamFormat(title: value["Title"] as? String ?? "", image: (imageURL ?? URL(string: PlaceHolders.kasamHeaderPlaceholderURL))!, rating: value["Rating"] as? String ?? "5", creator: nil, kasamID: value["KasamID"] as? String ?? "", genre: value["Genre"] as? String ?? "Fitness")
                        if self.discoverKasamDict["My Kasams"] == nil {self.discoverKasamDict["My Kasams"] = [kasam]}
                        else {self.discoverKasamDict["My Kasams"]!.append(kasam)}
                        count += 1
                        if count == snapshot.childrenCount {
                            self.discoverTableView.reloadRows(at: [IndexPath(item: Assets.discoverCriteria.count - 1, section: 0)], with: .fade)
                            self.updateContentTableHeight()
                        }
                    }
                }
            } else {
                //Incase there was a user kasam, that's now being deleted, so this view needs to be reloaded
                self.updateContentTableHeight()
                self.discoverTableView.reloadRows(at: [IndexPath(item: Assets.discoverCriteria.count - 1, section: 0)], with: .fade)
            }
        })
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
        if Assets.discoverCriteria[indexPath.row] == "My Kasams" && discoverKasamDict["My Kasams"] == nil {
            cell.DiscoverCategoryTitle.text = ""
            cell.disableSwiping()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if Assets.discoverCriteria[indexPath.row] == "My Kasams" && discoverKasamDict["My Kasams"] == nil {
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
                return count
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
            if Assets.discoverCriteria[collectionView.tag] == "My Kasams" && discoverKasamDict["My Kasams"] == nil {
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
            if Assets.discoverCriteria[collectionView.tag] == "My Kasams" && discoverKasamDict["My Kasams"] == nil {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "GoToCreateKasam"), object: self, userInfo: ["type": "basic"])
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
            viewSafeAreaInsetsDidChange()
            if discoverKasamDict[Assets.discoverCriteria[collectionView.tag]]?[indexPath.row] == nil {
                return CGSize(width: view.bounds.size.width - 30, height: 95)
            } else {
                return CGSize(width: view.bounds.size.width / 2, height: view.bounds.size.width / 2.3)
            }
        }
    }
}
