//
//  ViewController.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-04-30.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Firebase

class CoachHolder: UIViewController, UIScrollViewDelegate  {
    // MARK: Outlet properties
    
    @IBOutlet weak var tableView: UITableView! {didSet {tableView.estimatedRowHeight = 20}}
    @IBOutlet var headerView : UIView!
    @IBOutlet weak var profileView: UIView!
    @IBOutlet weak var profileViewRadius: UIView!
    @IBOutlet weak var coachName: UILabel!
    @IBOutlet weak var coachType: UIButton!
    @IBOutlet weak var coachBio: UILabel!
    @IBOutlet weak var followersNo: UILabel!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var contrainHeaderHeight: NSLayoutConstraint!
    @IBOutlet weak var kasamSquareCollection: UICollectionView!
    
    //scroll view variables
    var headerBlurImageView:UIImageView!
    var headerImageView:UIImageView!
    var observer: NSObjectProtocol?

    //local variables
    var discoverArray: [freeKasamFormat] = []
    var followerCountGlobal = 0
    var coachID: String = ""                //transfered in value
    var coachGName: String = ""             //transfered in value
    var previousWindow: String = "Name"
    var kasamIDGlobal: String = ""
    var kasamTitleGlobal: String = ""
    
    // MARK: The view
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLoad()
        countFollowers()
        countRoutines()
        getCoachData()
        countFollowers()
        getKasamsData()
    }
    
    func countFollowers(){
        var count = 0
        Database.database().reference().child("Users").child(coachID).child("Followers").observe(.childAdded) { (snapshot) in
            count += 1
            self.followersNo.text = String(count)
        }
    }
    
    func countRoutines(){
//        var count = 0
//            Database.database().reference().child("Users").child(coachID).child("Kasams").observe(.childAdded) { (snapshot) in
//            count += 1
//            self.routineNo.text = String(count)
//        }
    }
    
    //Retrieves Coach Data using coachID selected
    func getCoachData() {
        Database.database().reference().child("Users").child(coachID).observe(.value, with: { (snapshot) in
            if let value = snapshot.value as? [String: Any] {
                self.coachName.text! = value["Name"] as? String ?? ""
                self.headerLabel.text! = value["Name"] as? String ?? ""
                self.coachBio.text! = value["Bio"] as? String ?? ""
                self.coachType.setTitle(value["Type"] as? String ?? "", for: .normal)
                
                //Header - Image
                let headerURL = URL(string: value["ProfileImage"] as? String ?? "")
                self.headerImageView = UIImageView(frame: self.headerView.bounds)
                self.headerImageView?.contentMode = UIView.ContentMode.scaleAspectFill
                self.headerImageView?.sd_setImage(with: headerURL, placeholderImage: UIImage(named: "placeholder.png"))
                self.headerView.insertSubview(self.headerImageView, belowSubview: self.headerLabel)
                    
                //align header image to top
                self.headerImageView.translatesAutoresizingMaskIntoConstraints = false
                let topConstraint = NSLayoutConstraint(item: self.headerImageView, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.headerView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0)
                let bottomConstraint = NSLayoutConstraint(item: self.headerImageView, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.headerView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 30)
                let trailingConstraint = NSLayoutConstraint(item: self.headerImageView, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.headerView, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1, constant: 0)
                let leadingConstraint = NSLayoutConstraint(item: self.headerImageView, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.headerView, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1, constant: 0)
                self.headerView.addConstraints([topConstraint, bottomConstraint, trailingConstraint, leadingConstraint])
                
                self.setupBlurImage()
            }
        })
    }
    
    func setupLoad(){
        profileViewRadius.layer.cornerRadius = 16.0
        profileViewRadius.clipsToBounds = true
        tableView.contentInset = UIEdgeInsets(top: headerView.frame.height, left: 0, bottom: 0, right: 0)     //setup floating header
        contrainHeaderHeight.constant = UIScreen.main.bounds.width * 0.568              //setup floating header
        
        //change floating navigation bar font
        self.title = ""
        headerLabel.textColor = UIColor.colorFive
        headerLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 17)
        
        if let navBar = self.navigationController?.navigationBar {
            extendedLayoutIncludesOpaqueBars = true
            navBar.isTranslucent = true
            navBar.backgroundColor = UIColor.clear
            navBar.setBackgroundImage(UIImage(), for: .default)
            navBar.shadowImage = UIImage()         //remove bottom border on navigation bar
            navBar.tintColor = UIColor.white       //change back arrow to white
        }
        tableView.contentSize.height = 20
        self.kasamSquareCollection.delegate = nil
        self.kasamSquareCollection.dataSource = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(gesture(_:)))
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        tap.delegate = self
        kasamSquareCollection?.addGestureRecognizer(tap)
    }
    
    //Retrieves Kasams based on coach selected
    func getKasamsData() {
        Database.database().reference().child("Users").child(coachID).child("Kasams").observe(.childAdded, with: { (snapshot) in
            Database.database().reference().child("Coach-Kasams").child(snapshot.key).observe(.value, with: { (snapshot) in
                if let value = snapshot.value as? [String: Any] {
                    let kasamURL = URL(string: value["Image"] as? String ?? "")
                    let kasam = freeKasamFormat(title: value["Title"] as? String ?? "", image: kasamURL!, rating: value["Rating"] as! String, creator: value["CreatorName"] as? String ?? "", kasamID: value["KasamID"] as? String ?? "")
                    self.discoverArray.append(kasam)
                    self.kasamSquareCollection.reloadData()
                }
            })
        })
    }
    
    func setupBlurImage(){
        headerBlurImageView = UIImageView(frame: headerView.bounds)
        headerBlurImageView?.backgroundColor = UIColor.white
        headerBlurImageView?.contentMode = UIView.ContentMode.scaleAspectFill
        headerBlurImageView?.alpha = 0.0
        headerView.clipsToBounds = true
        headerView.insertSubview(headerBlurImageView, belowSubview: headerLabel)
    }
    
    // MARK: Scroll view delegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y + headerView.bounds.height
        var headerTransform = CATransform3DIdentity
        
        // PULL DOWN -----------------
        if offset < 0 {
            let headerScaleFactor:CGFloat = -(offset) / headerView.bounds.height
            let headerSizevariation = ((headerView.bounds.height * (1.0 + headerScaleFactor)) - headerView.bounds.height)/2
            headerTransform = CATransform3DTranslate(headerTransform, 0, headerSizevariation, 0)
            headerTransform = CATransform3DScale(headerTransform, 1.0 + headerScaleFactor, 1.0 + headerScaleFactor, 0)
            
            // Hide views if scrolled super fast
            headerView.layer.zPosition = 0
            headerLabel.isHidden = true
            
            if let navBar = self.navigationController?.navigationBar {
                navBar.tintColor = UIColor.white
            }
        }
            
        // SCROLL UP/DOWN ------------
        else {
            // Header -----------
            headerTransform = CATransform3DTranslate(headerTransform, 0, max(-offset_HeaderStop, -offset), 0)
            
            //  ------------ Label
            headerLabel.isHidden = false
            let alignToNameLabel = -offset + coachName.frame.origin.y + headerView.frame.height + offset_HeaderStop
            headerLabel.frame.origin = CGPoint(x: headerLabel.frame.origin.x, y: max(alignToNameLabel, distance_W_LabelHeader + offset_HeaderStop))
            
            //  ------------ Blur
            headerBlurImageView?.alpha = min (1.0, (offset + 150 - alignToNameLabel)/(distance_W_LabelHeader + 50))
            if let navBar = self.navigationController?.navigationBar {
                let scrollPercentage = Double(min (1.0, (offset + 150 - alignToNameLabel)/(distance_W_LabelHeader + 50)))
                navBar.tintColor = scrollColor(percent: scrollPercentage)
            }
        }
        headerView.layer.transform = headerTransform
    }
    
    @IBAction func gesture(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: kasamSquareCollection)
        if let indexPath = kasamSquareCollection?.indexPathForItem(at: point) {
            let kasamID = discoverArray[indexPath.row].kasamID
            let kasamName = discoverArray[indexPath.row].title
            kasamTitleGlobal = kasamName
            kasamIDGlobal = kasamID
            self.performSegue(withIdentifier: "goToKasam", sender: indexPath)
        }
    }
}

extension CoachHolder: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "KasamBlock") as! BlocksCell
        return cell
    }
}

extension CoachHolder: UICollectionViewDataSource, UICollectionViewDelegate {
    //Number of cells
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return discoverArray.count
    }
    
    //Populate cells
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let block = discoverArray[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DiscoverHorizontalCell", for: indexPath) as! DiscoverHorizontalCell
        cell.setBlock(cell: block)
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToKasam" {
            let kasamTransferHolder = segue.destination as! KasamHolder
            kasamTransferHolder.kasamID = kasamIDGlobal
        }
    }
}

extension CoachHolder: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let point = touch.location(in: kasamSquareCollection)
        if let indexPath = kasamSquareCollection?.indexPathForItem(at: point),
            let cell = kasamSquareCollection?.cellForItem(at: indexPath) {
            return touch.location(in: cell).y > 0
        }
        return false
    }
}
