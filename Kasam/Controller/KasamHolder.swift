//
//  ViewController.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-04-30.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Firebase
import SwiftEntryKit

class KasamHolder: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var tableView: UITableView! {didSet {tableView.estimatedRowHeight = 100}}
    @IBOutlet var headerView : UIView!
    @IBOutlet var profileView : UIView!
    @IBOutlet weak var profileViewRadius: UIView!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var addButtonText: UIButton!
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
        setupTwitterParallax()
        getKasamData()
        getBlocksData()
        countFollowers()
        registeredCheck()
    }
    
    func setupLoad(){
        //setup radius for kasam info block
        addButton.setImage(UIImage(named:"kasam-add"), for: .normal)
        profileViewRadius.layer.cornerRadius = 16.0
        profileViewRadius.clipsToBounds = true
        headerLabel.text = kasamGTitle
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
    
    //Twitter Parallax-------------------------------------------------------------------------------------------------------------------
    
    let headerHeight = UIScreen.main.bounds.width * 0.65            //Twitter Parallax -- CHANGE THIS VALUE TO MODIFY THE HEADER
    
    func setupTwitterParallax(){
        tableView.contentInset = UIEdgeInsets(top: headerView.frame.height, left: 0, bottom: 0, right: 0)     //setup floating header
        constraintHeightHeaerImages.constant = headerHeight                                                   //setup floating header
        
        if let navBar = self.navigationController?.navigationBar {
            extendedLayoutIncludesOpaqueBars = true
            navBar.isTranslucent = true
            navBar.backgroundColor = UIColor.white.withAlphaComponent(0)
            navBar.setBackgroundImage(UIImage(), for: .default)
            navBar.shadowImage = UIImage()         //remove bottom border on navigation bar
            navBar.tintColor = UIColor.white       //change back arrow to white
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetHeaderStop:CGFloat = headerHeight - 100         // At this offset the Header stops its transformations
        let offsetLabelHeader:CGFloat = 60.0                  // The distance between the top of the screen and the top of the White Label
        twitterParallaxScrollDelegate(scrollView: scrollView, headerHeight: headerHeight, headerView: headerView, headerBlurImageView: headerBlurImageView, headerLabel: headerLabel, offsetHeaderStop: offsetHeaderStop, offsetLabelHeader: offsetLabelHeader, shrinkingButton: nil, mainTitle: kasamTitle)
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
    
    func setupBlurImage(){
        //setup blur image, which creates the white navbar that appears as you scroll up
        headerBlurImageView = UIImageView(frame: view.bounds)
        headerBlurImageView?.backgroundColor = UIColor.white
        headerBlurImageView?.contentMode = UIView.ContentMode.scaleAspectFill
        headerBlurImageView?.alpha = 0.0
        headerView.clipsToBounds = true
        headerView.insertSubview(headerBlurImageView, belowSubview: headerLabel)
    }
    
    //-----------------------------------------------------------------------------------------------------------------------------------
    
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
    
    //REGISTER TO KASAM-------------------------------------------------------------------------------------------------
    
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
            showUnfollowConfirmation(title: "You sure?", description: "You'll lose all the progress you've made so far") { (success) in
                self.unregisterUseFromKasam()
            }
        }
    }
    
    func registerUserToKasam() {
        //STEP 1: Adds the user to the Coach Kasam-following list
        Database.database().reference().child("Coach-Kasams").child(kasamID).child("Followers").updateChildValues([(Auth.auth().currentUser?.uid)!: (Auth.auth().currentUser?.displayName)!])
        //STEP 2: Adds the user to the Coach-following list
        Database.database().reference().child("Users").child(coachIDGlobal).child("Followers").updateChildValues([(Auth.auth().currentUser?.uid)!: (Auth.auth().currentUser?.displayName)!])
        self.addButtonText.setIcon(icon: .fontAwesomeSolid(.check), iconSize: 20, color: .white, backgroundColor: .clear, forState: .normal)
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
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "RetrieveTodayKasams"), object: self)
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
        self.addButtonText.setIcon(icon: .fontAwesomeSolid(.plus), iconSize: 20, color: .white, backgroundColor: .clear, forState: .normal)
        countFollowers()
        registeredCheck()
        
        //Removes the kasam from the user's following list
        Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Kasam-Following").child(kasamID).setValue(nil) {(error, reference) in
            if error != nil {
                print(error!)
            } else {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "RetrieveTodayKasams"), object: self)
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
            if SavedData.kasamDict[self.kasamID]?.status == "completed" {
                //completed
                self.addButton.tintColor = UIColor.black
                self.addButtonText.setIcon(icon: .fontAwesomeSolid(.trophy), iconSize: 20, color: .white, backgroundColor: .clear, forState: .normal)
            }
            else {
                if snapshot.hasChild((Auth.auth().currentUser?.uid)!){
                    //registered
                    self.registerCheck = 1
                    self.addButtonText.setIcon(icon: .fontAwesomeSolid(.check), iconSize: 20, color: .white, backgroundColor: .clear, forState: .normal)
                } else{
                    //not registered
                    self.registerCheck = 0
                    self.addButtonText.setIcon(icon: .fontAwesomeSolid(.plus), iconSize: 20, color: .white, backgroundColor: .clear, forState: .normal)
                }
            }
        })
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
