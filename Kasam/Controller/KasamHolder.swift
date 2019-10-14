//
//  ViewController.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-04-30.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Firebase
import AVKit

let offset_HeaderStop:CGFloat = 140.0  // At this offset the Header stops its transformations
let distance_W_LabelHeader:CGFloat = 30.0 // The distance between the top of the screen and the top of the White Label

class KasamHolder: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var tableView: UITableView! {didSet {tableView.estimatedRowHeight = 100}}
    @IBOutlet var headerView : UIView!
    @IBOutlet var profileView : UIView!
    @IBOutlet weak var profileViewRadius: UIView!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet var kasamTitle : UILabel!
    @IBOutlet weak var coachName: UIButton!
    @IBOutlet weak var kasamDescription: UILabel!
    @IBOutlet weak var kasamType: UILabel!
    @IBOutlet weak var kasamLevel: UILabel!
    @IBOutlet weak var followersNo: UILabel!
    @IBOutlet var headerLabel : UILabel!
    @IBOutlet weak var constraintHeightHeaerImages: NSLayoutConstraint!
    
    var headerBlurImageView:UIImageView!
    var headerImageView:UIImageView!
    var observer: NSObjectProtocol?
    var chosenTime = ""
    var chosenRepeat = ""
    var chosenDate : [String:Int] = [:]
    var startDate = ""
    var kasamBlocks: [BlockFormat] = []
    var followerCountGlobal = 0
    var kasamID: String = ""            //transfered in values from previous vc
    var kasamGTitle: String = ""        //transfered in values from previous vc
    var kasamTracker: [Tracker] = [Tracker]()
    var registerCheck = 0
    var coachIDGlobal = ""
    var coachNameGlobal = ""
    var blockURLGlobal = ""
    var startDay = ""
    
    // MARK: The view
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLoad()
        getKasamData()
        getBlocksData()
        countFollowers()
        registeredCheck()
    }
    
    func setupLoad(){
        //setup radius for kasam info block
        profileViewRadius.layer.cornerRadius = 16.0
        profileViewRadius.clipsToBounds = true
        tableView.contentInset = UIEdgeInsets(top: headerView.frame.height, left: 0, bottom: 0, right: 0)     //setup floating header
        constraintHeightHeaerImages.constant = UIScreen.main.bounds.width * 0.568                             //setup floating header

        if let navBar = self.navigationController?.navigationBar {
            extendedLayoutIncludesOpaqueBars = true
            navBar.isTranslucent = true
            navBar.backgroundColor = UIColor.white.withAlphaComponent(0)
            navBar.setBackgroundImage(UIImage(), for: .default)
            navBar.shadowImage = UIImage()         //remove bottom border on navigation bar
            navBar.tintColor = UIColor.white       //change back arrow to white
        }
    }
    
    @IBAction func coachNamePress(_ sender: Any) {
        self.performSegue(withIdentifier: "goToCoach", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToCoach" {
            let coachTransferHolder = segue.destination as! CoachHolder
            coachTransferHolder.coachID = self.coachIDGlobal
            coachTransferHolder.coachGName = self.coachNameGlobal
            coachTransferHolder.previousWindow = self.kasamTitle.text!
        }
    }
    
    //Retrieves Kasam Data using Kasam ID selected
    func getKasamData(){
        Database.database().reference().child("Coach-Kasams").child(kasamID).observe(.value, with: { (snapshot) in
            if let value = snapshot.value as? [String: Any] {
                self.kasamGTitle = value["Title"] as? String ?? ""
                self.headerLabel.text! = self.kasamGTitle
                self.kasamTitle.text! = self.kasamGTitle
                self.kasamDescription.text! = value["Description"] as? String ?? ""
                self.coachName.setTitle(value["CreatorName"] as? String ?? "", for: .normal)
                self.coachIDGlobal = value["CreatorID"] as! String
                self.kasamType.text! = value["Genre"] as? String ?? ""
                self.kasamLevel.text! = value["Level"] as? String ?? ""
                
                //Header - Image
                let headerURL = URL(string: value["Image"] as? String ?? "")
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
    
    //Retrieves Blocks based on Kasam selected
    func getBlocksData() {
        Database.database().reference().child("Coach-Kasams").child(kasamID).child("Blocks").observeSingleEvent(of: .value, with:{ (snap) in
            let ratio = 30 / (snap.childrenCount)
            var dayNumber = 1
            for _ in 1...ratio {
                Database.database().reference().child("Coach-Kasams").child(self.kasamID).child("Blocks").observe(.childAdded, with: { (snapshot) in
                    if let value = snapshot.value as? [String: Any] {
                        let blockURL = URL(string: value["Image"] as? String ?? "")
                        let block = BlockFormat(title: value["Title"] as? String ?? "", order: String(dayNumber), duration: value["Duration"] as? String ?? "", image: blockURL ?? self.placeholder() as! URL)
                        dayNumber += 1
                        self.kasamBlocks.append(block)
                        self.tableView.reloadData()
                        self.tableView.beginUpdates()
                        self.tableView.endUpdates()
                    }
                })
            }
        })
    }
    
    //Add Kasam to Following List of user
    @IBAction func addButtonPress(_ sender: Any) {
        if registerCheck == 0 {
            performSegue(withIdentifier: "goToAddKasamPopup", sender: self)
            observer = NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "saveTime"), object: nil, queue: OperationQueue.main) { (notification) in
                let timeVC = notification.object as! AddKasamPopup
                self.chosenTime = timeVC.formattedTime
                self.startDate = timeVC.formattedDate
                self.startDay = Date().dayOfWeek()!
                self.registerUserToKasam()
                NotificationCenter.default.removeObserver(self.observer as Any)
            }
        } else {
            unregisterUseFromKasam()
        }
    }
    
    func registerUserToKasam() {
        //STEP 1: Adds the user to the Coach Kasam-following list
        Database.database().reference().child("Coach-Kasams").child(kasamID).child("Followers").updateChildValues([(Auth.auth().currentUser?.uid)!: (Auth.auth().currentUser?.displayName)!])
        //STEP 2: Adds the user to the Coach-following list
        Database.database().reference().child("Users").child(coachIDGlobal).child("Followers").updateChildValues([(Auth.auth().currentUser?.uid)!: (Auth.auth().currentUser?.displayName)!])
        addButton.setBackgroundImage(UIImage(named: "check_mark.png"), for: UIControl.State.normal)
        countFollowers()
        registeredCheck()
        
        //STEP 3: Adds the kasam to the user's following list
        Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Kasam-Following").updateChildValues([kasamID:kasamTitle.text!]) {
            (error, reference) in
            if error != nil {
                print(error!)
            } else {
                //STEP 4: Adds the user preferences to the kasam they just followed
                Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Kasam-Following").child(self.kasamID).updateChildValues(["Kasam Name" : self.kasamTitle.text!, "Date Joined": self.startDate, "Day Joined": self.startDay, "Time": self.chosenTime, "Days": self.chosenDate]) {(error, reference) in
                    if error != nil {
                        print(error!)
                    } else {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "RetrieveKasams"), object: self)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "ProfileUpdate"), object: self)
                    }
                }
            }
        }
    }
    
    func unregisterUseFromKasam() {
        //Removes the user from the Kasam following
        Database.database().reference().child("Coach-Kasams").child(kasamID).child("Followers").child((Auth.auth().currentUser?.uid)!).setValue(nil)
        //Removes the user from the Coach following
        Database.database().reference().child("Users").child(coachIDGlobal).child("Followers").child((Auth.auth().currentUser?.uid)!).setValue(nil)
        addButton.setBackgroundImage(UIImage(named: "add-icon.png"), for: UIControl.State.normal)
        countFollowers()
        registeredCheck()
        
        //Removes the kasam from the user's following list
        Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Kasam-Following").child(kasamID).setValue(nil) {(error, reference) in
            if error != nil {
                print(error!)
            } else {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "RetrieveKasams"), object: self)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "ProfileUpdate"), object: self)
            }
        }
    }
    
    func countFollowers(){
        var count = 0
        Database.database().reference().child("Coach-Kasams").child(kasamID).child("Followers").observe(.childAdded) { (snapshot) in
            count += 1
            self.followersNo.text = "\(count) Followers"
        }
    }
    
    func registeredCheck(){
        Database.database().reference().child("Coach-Kasams").child(kasamID).child("Followers").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.hasChild((Auth.auth().currentUser?.uid)!){
                //registered
                self.registerCheck = 1
                self.addButton.setBackgroundImage(UIImage(named: "check_mark.png"), for: UIControl.State.normal)
            } else{
                //not registered
                self.registerCheck = 0
                self.addButton.setBackgroundImage(UIImage(named: "add-icon.png"), for: UIControl.State.normal)
            }
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
        var avatarTransform = CATransform3DIdentity
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
            let alignToNameLabel = -offset + kasamTitle.frame.origin.y + headerView.frame.height + offset_HeaderStop
            headerLabel.frame.origin = CGPoint(x: headerLabel.frame.origin.x, y: max(alignToNameLabel, distance_W_LabelHeader + offset_HeaderStop))
            
        //  ------------ Blur
            headerBlurImageView?.alpha = min (1.0, (offset + 150 - alignToNameLabel)/(distance_W_LabelHeader + 50))
            if let navBar = self.navigationController?.navigationBar {
                let scrollPercentage = Double(min (1.0, (offset + 150 - alignToNameLabel)/(distance_W_LabelHeader + 50)))
                navBar.tintColor = scrollColor(percent: scrollPercentage)
            }
            
        // Avatar -----------
            let avatarScaleFactor = (min(offset_HeaderStop, offset)) / addButton.bounds.height / 9.4 // Slow down the animation
            let avatarSizeVariation = ((addButton.bounds.height * (1.0 + avatarScaleFactor)) - addButton.bounds.height) / 2.0
            
            avatarTransform = CATransform3DTranslate(avatarTransform, 0, avatarSizeVariation, 0)
            avatarTransform = CATransform3DScale(avatarTransform, 1.0 - avatarScaleFactor, 1.0 - avatarScaleFactor, 0)
            
            if offset <= offset_HeaderStop {
                if addButton.layer.zPosition < headerView.layer.zPosition{
                    headerView.layer.zPosition = 0
                }
            } else {
                if addButton.layer.zPosition >= headerView.layer.zPosition{
                    headerView.layer.zPosition = 2
                }
            }
        }
        
        // Apply Transformations
        headerView.layer.transform = headerTransform
        addButton.layer.transform = avatarTransform
    }
}

extension KasamHolder: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return kasamBlocks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let block = kasamBlocks[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "KasamBlock") as! BlocksCell
        cell.setBlock(block: block)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
}
