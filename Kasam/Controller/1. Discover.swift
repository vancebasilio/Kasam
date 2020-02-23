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

class DiscoverViewController: UIViewController {
    
    @IBOutlet weak var categoryCollection: UICollectionView!
    @IBOutlet weak var discoverTableView: UITableView!
    @IBOutlet weak var discoverTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var expertPageControl: UIPageControl!
    @IBOutlet weak var expertHeight: NSLayoutConstraint!
    @IBOutlet weak var contentView: NSLayoutConstraint!
    
    let discoverCriteriaArray = ["Basic", "User"]
    let discoverTitlesArray = ["Popular Kasams, My Kasams"]
    var discoverKasamArray = [Int:[discoverKasamFormat]]()
    var discoverKasamDBHandle: DatabaseHandle!
    
    var featuredKasamArray: [discoverKasamFormat] = []
    var kasamIDGlobal: String = ""
    var kasamTitleGlobal: String = ""
    var timer = Timer()
    var counter = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getDiscoverKasams(criteria: "Challenge")
        for discoverCriteria in discoverCriteriaArray {getDiscoverKasams(criteria: discoverCriteria)}
        setupNavBar()
        self.view.showAnimatedSkeleton()
        let getUserKasams = NSNotification.Name("GetUserKasams")
        NotificationCenter.default.addObserver(self, selector: #selector(DiscoverViewController.getUserKasams), name: getUserKasams, object: nil)
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: 4.0, target: self, selector: #selector(self.changeImage), userInfo: nil, repeats: true)
        }
    }
    
    @objc func getUserKasams(){
        getDiscoverKasams(criteria: "User")
    }
    
    //Puts the nav bars back
    override func viewDidAppear(_ animated: Bool) {
        if let navBar = self.navigationController?.navigationBar {
            navBar.backgroundColor = UIColor.white.withAlphaComponent(100)
            navBar.isTranslucent = false
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        DBRef.coachKasams.removeObserver(withHandle: self.discoverKasamDBHandle)
    }
    
//   override func viewDidLayoutSubviews(){
//        let frame = self.view.safeAreaLayoutGuide.layoutFrame
//        let expertHeightValue = expertHeight.constant + 61
//        let popularHeightValue = popularHeight.constant + 49                //the 49 and 61 are the title heights
//        contentView.constant =  discoverTableView.fr + 15    //15 is the additional space from the bottom
//        let contentViewHeight = contentView.constant + 1
//        if contentViewHeight > frame.height {
//            contentView.constant = contentViewHeight
//        } else if contentViewHeight <= frame.height {
//            let diff = frame.height - contentViewHeight
//            contentView.constant = contentViewHeight + diff + 1
//        }
//    }

    //Table Resizing----------------------------------------------------------------------
    
    func updateContentTableHeight(){
        //set the table row height, based on the screen size
        discoverTableView.rowHeight = UITableView.automaticDimension
        discoverTableView.estimatedRowHeight = (view.bounds.size.width / 2.3) + 60
        
        //sets the height of the whole tableview, based on the numnber of rows
        var tableFrame = discoverTableView.frame
        tableFrame.size.height = discoverTableView.contentSize.height
        discoverTableView.frame = tableFrame
        self.discoverTableViewHeight.constant = self.discoverTableView.contentSize.height
        
        //elongates the entire scrollview, based on the tableview height
        let frame = self.view.safeAreaLayoutGuide.layoutFrame
        let featureViewHeight = view.bounds.size.width * (8/13)
        let contentViewHeight = discoverTableViewHeight.constant + featureViewHeight + 61 + 25         //25 is the additional space from the bottom and 61 is the height of the Discover Title
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
        }
    }
    
    func getDiscoverKasams(criteria: String) {
        discoverKasamArray.removeAll()      //THIS WILL CAUSE ISSUES WHEN USER ADDS A NEW KASAM AND IT WIPES OUT EVERYTHING!!!!
        var tempArray = [discoverKasamFormat]()
        discoverKasamDBHandle = DBRef.coachKasams.queryOrdered(byChild: "Type").queryEqual(toValue: criteria).observe(.childAdded) {(snapshot) in
            if let value = snapshot.value as? [String: Any] {
                let creatorID = value["CreatorID"] as? String ?? ""
                DBRef.userCreator.child(creatorID).child("Name").observeSingleEvent(of: .value, with: {(snap) in
                    let creatorName = snap.value as! String
                    let imageURL = URL(string: value["Image"] as? String ?? "")
                    let kasam = discoverKasamFormat(title: value["Title"] as? String ?? "", image: imageURL ?? URL(string:PlaceHolders.kasamLoadingImageURL)!, rating: value["Rating"] as? String ?? "5", creator: creatorName, kasamID: value["KasamID"] as? String ?? "")
                    if criteria == "Challenge" {
                        self.featuredKasamArray.append(kasam)
                        self.categoryCollection.reloadData()
                        self.categoryCollection.hideSkeleton(transition: .crossDissolve(0.25))
                    } else {
                        if let index = self.discoverCriteriaArray.index(of: criteria) {
                            if (criteria == "User" && creatorID == Auth.auth().currentUser?.uid) || criteria != "User" {
                                tempArray.append(kasam)
                                self.discoverKasamArray[index] = tempArray
                                self.updateContentTableHeight()
                                self.discoverTableView.reloadData()
                            }
                        }
                    }
                })
            }
        }
    }
}

//TableView-----------------------------------------------------------

extension DiscoverViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoverCriteriaArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DiscoverKasamCell") as! DiscoverKasamCell
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let height = (view.bounds.size.width / 2.3) + 60
        return height
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
            if discoverCriteriaArray[collectionView.tag] == "User" {
                return discoverKasamArray[collectionView.tag]?.count ?? 1
            } else {
                return discoverKasamArray[collectionView.tag]?.count ?? 0
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
            if discoverKasamArray[collectionView.tag] == nil {
                cell.kasamTitle.text = "Create a Kasam"
                cell.topImage.image = UIImage(named: "placeholder-add-kasam")!
                cell.kasamRating.rating = 5.0
                cell.topImage.layer.cornerRadius = 8.0
                cell.topImage.clipsToBounds = true
            } else {
                let block = discoverKasamArray[collectionView.tag]![indexPath.row]
                cell.setBlock(cell: block)
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
            if discoverCriteriaArray[collectionView.tag] == "User" && discoverKasamArray[collectionView.tag] == nil {
                self.performSegue(withIdentifier: "goToNewKasam", sender: indexPath)
            } else {
                let kasamID = discoverKasamArray[collectionView.tag]?[indexPath.row].kasamID
                let kasamName = discoverKasamArray[collectionView.tag]?[indexPath.row].title
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
            return CGSize(width: view.bounds.size.width / 2, height: view.bounds.size.width / 2.3)
        }
    }
    
    //Skeleton View
    func collectionSkeletonView(_ skeletonView: UICollectionView, cellIdentifierForItemAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return "ExpertKasamCell"
    }
    
    func collectionSkeletonView(_ skeletonView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
}
