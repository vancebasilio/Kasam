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
    
    @IBOutlet weak var discoverCollection: UICollectionView!
    @IBOutlet weak var categoryCollection: UICollectionView!
    @IBOutlet weak var myKasamCollection: UICollectionView!
    @IBOutlet weak var expertPageControl: UIPageControl!
    @IBOutlet weak var expertHeight: NSLayoutConstraint!
    @IBOutlet weak var popularHeight: NSLayoutConstraint!
    @IBOutlet weak var myKasamHeight: NSLayoutConstraint!
    @IBOutlet weak var contentView: NSLayoutConstraint!
    
    var freeKasamArray: [freeKasamFormat] = []
    var expertKasamArray: [expertKasamFormat] = []
    var myKasamArray: [freeKasamFormat] = []
    var kasamIDGlobal: String = ""
    var kasamTitleGlobal: String = ""
    var timer = Timer()
    var counter = 0
    let userKasamDB = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Kasams")
    let userCreator = Database.database().reference().child("Users")
    var userKasamDBHandle: DatabaseHandle!
    let kasamDB = Database.database().reference().child("Coach-Kasams")
    var freeKasamDBHandle: DatabaseHandle!
    var expertKasamDBHandle: DatabaseHandle!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getFreeKasams()
        getUserKasams()
        getExpertKasams()
        setupNavBar()
        self.view.showAnimatedSkeleton()
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: 4.0, target: self, selector: #selector(self.changeImage), userInfo: nil, repeats: true)
        }
    }
    
    //Puts the nav bars back
    override func viewWillAppear(_ animated: Bool) {
        if let navBar = self.navigationController?.navigationBar {
            navBar.backgroundColor = UIColor.white.withAlphaComponent(100)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let navBar = self.navigationController?.navigationBar {
            navBar.isTranslucent = false
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.kasamDB.removeObserver(withHandle: self.freeKasamDBHandle)
        self.kasamDB.removeObserver(withHandle: self.expertKasamDBHandle)
        self.userKasamDB.removeObserver(withHandle: self.userKasamDBHandle)
    }
    
   override func viewDidLayoutSubviews(){
        let frame = self.view.safeAreaLayoutGuide.layoutFrame
        let expertHeightValue = expertHeight.constant + 61
        let popularHeightValue = popularHeight.constant + 49                //the 49 and 61 are the title heights
        let myKasamHeightValue = myKasamHeight.constant + 49
        contentView.constant =  popularHeightValue + expertHeightValue + myKasamHeightValue + 15    //15 is the additional space from the bottom
        let contentViewHeight = contentView.constant + 1
        if contentViewHeight > frame.height {
            contentView.constant = contentViewHeight
        } else if contentViewHeight <= frame.height {
            let diff = frame.height - contentViewHeight
            contentView.constant = contentViewHeight + diff + 1
        }
    }
    

    //make the expert slider automatically scroll
    @objc func changeImage() {
        if counter < expertKasamArray.count {
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
    
    //Part 1
    func getExpertKasams() {
        expertKasamArray.removeAll()
        expertKasamDBHandle = kasamDB.queryOrdered(byChild: "Type").queryEqual(toValue: "Expert").observe(.childAdded) { (snapshot) in
            if let value = snapshot.value as? [String: Any] {
                let creatorID = value["CreatorID"] as? String ?? ""
                self.userCreator.child(creatorID).child("Name").observeSingleEvent(of: .value, with: {(snap) in
                    let creatorName = snap.value as! String
                    let imageURL = URL(string: value["Image"] as? String ?? "")
                    let kasam = expertKasamFormat(title: value["Title"] as? String ?? "", image: imageURL ?? self.placeholder() as! URL, rating: value["Rating"] as? String ?? "5", creator: creatorName, kasamID: value["KasamID"] as? String ?? "")
                    self.expertKasamArray.append(kasam)
                    self.categoryCollection.reloadData()
                    self.categoryCollection.hideSkeleton(transition: .crossDissolve(0.25))
                })
            }
        }
    }
    
    //Part 2
    func getFreeKasams() {
        freeKasamArray.removeAll()
        freeKasamDBHandle = kasamDB.queryOrdered(byChild: "Type").queryEqual(toValue: "Free").observe(.childAdded) { (snapshot) in
            if let value = snapshot.value as? [String: Any] {
                let imageURL = URL(string: value["Image"] as? String ?? "")
                let categoryBlock = freeKasamFormat(title: value["Title"] as? String ?? "", image: imageURL ?? self.placeholder() as! URL, rating: value["Rating"] as! String, creator: value["CreatorName"] as? String ?? "", kasamID: value["KasamID"] as? String ?? "")
                self.freeKasamArray.append(categoryBlock)
                self.discoverCollection.reloadData()
            }
        }
    }
    
    //Part 3
    func getUserKasams(){
        myKasamArray.removeAll()
        userKasamDBHandle = userKasamDB.observe(.childAdded, with: { (snapshot) in
            Database.database().reference().child("Coach-Kasams").child(snapshot.key).observe(.value, with: { (snapshot) in
            if let value = snapshot.value as? [String: Any] {
                let imageURL = URL(string: value["Image"] as? String ?? "")
                let categoryBlock = freeKasamFormat(title: value["Title"] as? String ?? "", image: imageURL ?? self.placeholder() as! URL, rating: value["Rating"] as! String, creator: value["CreatorName"] as? String ?? "", kasamID: value["KasamID"] as? String ?? "")
                self.myKasamArray.append(categoryBlock)
                self.myKasamCollection.reloadData()
                }
                //remove observer
                Database.database().reference().child("Coach-Kasams").child(snapshot.key).removeAllObservers()
            })
        })
    }
}

extension DiscoverViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, SkeletonCollectionViewDataSource {
    //Number of cells
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == discoverCollection {
            return freeKasamArray.count
        } else if collectionView == categoryCollection {
            let count = expertKasamArray.count
            expertPageControl.numberOfPages = count
            expertPageControl.isHidden = !(count > 1)
            return expertKasamArray.count
        } else {
            if myKasamArray.count == 0 {
                return 1
            } else {
                return myKasamArray.count
            }
        }
    }
    
    //Populate cells
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == discoverCollection {
            let block = freeKasamArray[indexPath.row]
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FreeKasamCell", for: indexPath) as! DiscoverHorizontalCell
            cell.setBlock(cell: block)
            cell.topImage.layer.cornerRadius = 8.0
            cell.topImage.clipsToBounds = true
            return cell
        } else if collectionView == categoryCollection {
            let block = expertKasamArray[indexPath.row]
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExpertKasamCell", for: indexPath) as! DiscoverCategoryCell
            cell.setBlock(cell: block)
            return cell
        } else {
            if myKasamArray.count != 0 {
                let block = myKasamArray[indexPath.row]
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyKasamCell", for: indexPath) as! DiscoverHorizontalCell
                cell.setBlock(cell: block)
                cell.topImage.layer.cornerRadius = 8.0
                cell.topImage.clipsToBounds = true
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyKasamCell", for: indexPath) as! DiscoverHorizontalCell
                cell.kasamTitle.text = "Create a Challo"
                cell.topImage.image = UIImage(named: "placeholder-add-kasam")!
                cell.kasamRating.rating = 5.0
                cell.topImage.layer.cornerRadius = 8.0
                cell.topImage.clipsToBounds = true
                return cell
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == discoverCollection {
            let kasamID = freeKasamArray[indexPath.row].kasamID
            let kasamName = freeKasamArray[indexPath.row].title
            kasamTitleGlobal = kasamName
            kasamIDGlobal = kasamID
            self.performSegue(withIdentifier: "goToKasam", sender: indexPath)
        } else if collectionView == categoryCollection {
            let kasamID = expertKasamArray[indexPath.row].kasamID
            let kasamName = expertKasamArray[indexPath.row].title
            kasamTitleGlobal = kasamName
            kasamIDGlobal = kasamID
            self.performSegue(withIdentifier: "goToKasam", sender: indexPath)
        } else {
            if myKasamArray.count != 0 {
                let kasamID = myKasamArray[indexPath.row].kasamID
                let kasamName = myKasamArray[indexPath.row].title
                kasamTitleGlobal = kasamName
                kasamIDGlobal = kasamID
                self.performSegue(withIdentifier: "goToKasam", sender: indexPath)
            } else {
                self.performSegue(withIdentifier: "goToNewKasam", sender: indexPath)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == categoryCollection {
            expertHeight.constant = (view.bounds.size.width * (8/13))
            return CGSize(width: view.bounds.size.width, height: view.bounds.size.width * (8/13))
        } else {
            popularHeight.constant = (view.bounds.size.width / 2.3)
            myKasamHeight.constant = popularHeight.constant
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
