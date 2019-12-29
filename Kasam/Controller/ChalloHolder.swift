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
import Lottie

class ChalloHolder: UIViewController, UIScrollViewDelegate {
    
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
    @IBOutlet weak var createChalloButton: UIButton!
    @IBOutlet weak var deleteChalloButton: UIButton!
    @IBOutlet weak var createDeleteButtonStackView: UIStackView!
    @IBOutlet weak var challoDeetsStackView: UIStackView!
    
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
    var blockIDGlobal = ""
    
    //Review Only Variables
    var reviewOnly = false
    let animationView = AnimationView()
    let animationOverlay = UIView()
    var storageRef = Storage.storage().reference()
    var kasamIDGlobal = ""
    var kasamImageGlobal = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLoad()
        setupTwitterParallax()
        if reviewOnly == false {
            getKasamData()
            getBlocksData()
            countFollowers()
            registeredCheck()
        }
    }
    
    func setupLoad(){
        //setup radius for kasam info block
        addButton.setImage(UIImage(named:"kasam-add"), for: .normal)
        profileViewRadius.layer.cornerRadius = 16.0
        profileViewRadius.clipsToBounds = true
        headerLabel.text = kasamGTitle
        var createChalloTitle = "  Create Challo"
        if NewChallo.loadedInChalloImage != UIImage() {
            createChalloTitle = "  Update Challo"
        }
        if reviewOnly == true {
            challoDeetsStackView.isHidden = true
            createDeleteButtonStackView.isHidden = false
            addButton.isHidden = true
            addButtonText.isHidden = true
            
            createChalloButton.layer.cornerRadius = 20.0
            createChalloButton.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight:.regular), prefixTextColor: UIColor.white, icon: .fontAwesomeSolid(.magic), iconColor: UIColor.white, postfixText: createChalloTitle, postfixTextFont: UIFont.systemFont(ofSize: 15, weight:.medium), postfixTextColor: UIColor.white, backgroundColor: UIColor.black, forState: .normal, iconSize: 15)
            
            deleteChalloButton.layer.cornerRadius = 20.0
            deleteChalloButton.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight:.regular), prefixTextColor: UIColor.white, icon: .fontAwesomeSolid(.trashAlt), iconColor: UIColor.white, postfixText: "  Delete Challo", postfixTextFont: UIFont.systemFont(ofSize: 15, weight:.medium), postfixTextColor: UIColor.white, backgroundColor: UIColor.init(hex: 0xDB482D), forState: .normal, iconSize: 15)
            
        }
    }
    
    @IBAction func coachNamePress(_ sender: Any) {
        if reviewOnly == false {
            self.performSegue(withIdentifier: "goToCoach", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToCoach" {
            let coachTransferHolder = segue.destination as! CoachHolder
            coachTransferHolder.coachID = self.coachIDGlobal
            coachTransferHolder.coachGName = self.coachNameGlobal
            coachTransferHolder.previousWindow = self.kasamTitle.text!
        } else if segue.identifier == "goToChalloActivityViewer" {
            let kasamActivityHolder = segue.destination as! ChalloActivityViewer
            kasamActivityHolder.kasamID = kasamID
            kasamActivityHolder.blockID = blockIDGlobal
            kasamActivityHolder.viewingOnlyCheck = true
            kasamActivityHolder.dayOrder = "0"                  //this field is for saving kasam progress, so set it to zero
        }
    }
    
    //Twitter Parallax-------------------------------------------------------------------------------------------------------------------
    
    let headerHeight = UIScreen.main.bounds.width * 0.65            //Twitter Parallax -- CHANGE THIS VALUE TO MODIFY THE HEADER
    
    func setupTwitterParallax(){
        tableView.contentInset = UIEdgeInsets(top: headerView.frame.height, left: 0, bottom: 0, right: 0)     //setup floating header
        constraintHeightHeaerImages.constant = headerHeight                                                   //setup floating header
        
        //Header - Image
        self.headerImageView = UIImageView(frame: self.headerView.bounds)
        self.headerImageView?.contentMode = UIView.ContentMode.scaleAspectFill
        self.headerView.insertSubview(self.headerImageView, belowSubview: self.headerLabel)
        
        headerBlurImageView = twitterParallaxHeaderSetup(headerBlurImageView: headerBlurImageView, headerImageView: headerImageView, headerView: headerView, headerLabel: headerLabel)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetHeaderStop:CGFloat = headerHeight - 100         //Thickness of navbar that appears when you scroll up
        let offsetLabelHeader:CGFloat = 60.0                      //Distance from top of screen that the headerlabel shows up at
        twitterParallaxScrollDelegate(scrollView: scrollView, headerHeight: headerHeight, headerView: headerView, headerBlurImageView: headerBlurImageView, headerLabel: headerLabel, offsetHeaderStop: offsetHeaderStop, offsetLabelHeader: offsetLabelHeader, shrinkingButton: addButtonText, shrinkingButton2: addButton, mainTitle: kasamTitle)
    }
    
    //-----------------------------------------------------------------------------------------------------------------------------------
    
    //Retrieves Kasam Data using Kasam ID selected
    func getKasamData(){
        Database.database().reference().child("Coach-Kasams").child(kasamID).observe(.value, with: { (snapshot) in
            if let value = snapshot.value as? [String: Any] {
                self.kasamGTitle = value["Title"] as? String ?? ""
                self.headerLabel.text! = self.kasamGTitle
                self.kasamTitle.text! = self.kasamGTitle
                self.kasamDescription.text! = value["Description"] as? String ?? ""
                self.coachName.setTitle(value["CreatorName"] as? String ?? "", for: .normal)        //in the future, get this name from the userdatabase, so it's the most uptodate name
                self.coachIDGlobal = value["CreatorID"] as! String
                self.kasamType.text! = value["Genre"] as? String ?? ""
                self.kasamLevel.text! = value["Level"] as? String ?? ""
                let headerURL = URL(string: value["Image"] as? String ?? "")
                self.headerImageView?.sd_setImage(with: headerURL, placeholderImage: UIImage(named: "placeholder.png"))
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
                        let blockID = snapshot.key
                        let blockURL = URL(string: value["Image"] as? String ?? "")
                        let block = BlockFormat(blockID: blockID, title: value["Title"] as? String ?? "", order: String(dayNumber), duration: value["Duration"] as? String ?? "", imageURL: blockURL ?? self.placeholder() as! URL, image: nil)
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
            addKasamPopup()
            observer = NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "saveTime"), object: nil, queue: OperationQueue.main) { (notification) in
                let timeVC = notification.object as! AddKasamController
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
        //STEP 1: Adds the user to the kasam-following list
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
                //STEP 4: Adds the user preferences to the Challo they just followed
                Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Kasam-Following").child(self.kasamID).updateChildValues(["Kasam Name" : self.kasamTitle.text!, "Date Joined": self.startDate, "Day Joined": self.startDay, "Time": self.chosenTime, "Days": self.chosenDate]) {(error, reference) in
                    if error != nil {
                        print(error!)
                    } else {
                        Analytics.logEvent("following_Challo", parameters: ["challo_name":self.kasamTitle.text ?? "Challo Name"])
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
                Analytics.logEvent("unfollowing_Challo", parameters: ["challo_name":self.kasamTitle.text ?? "Challo Name"])
                NotificationCenter.default.post(name: Notification.Name(rawValue: "RetrieveTodayKasams"), object: self)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "ProfileUpdate"), object: self)
            }
        }
    }
    
    func countFollowers(){
        var count = 0
        Database.database().reference().child("Coach-Kasams").child(kasamID).child("Followers").observe(.childAdded) { (snapshot) in
            count += 1
            if count == 1 {
                self.followersNo.text = "\(count) Follower"
            } else {
                self.followersNo.text = "\(count) Followers"
            }
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
    
    //REVIEW ONLY------------------------------------------------------------------------------------------------------------------------
    
    func setupReviewOnly(){
        //load in values
        coachName.isEnabled = false
        coachName.setTitle(Auth.auth().currentUser?.displayName, for: .normal)
        kasamTitle.text = NewChallo.kasamName
        headerLabel.text = NewChallo.kasamName
        kasamDescription.text = NewChallo.kasamDescription
        kasamType.text = "Personal"
        kasamLevel.text = "Beginner"
        var blockImage = UIImage()
        if NewChallo.challoImageToSave == UIImage() {
            headerImageView.image = NewChallo.loadedInChalloImage
            blockImage = NewChallo.loadedInChalloImage
        } else {
            headerImageView.image = NewChallo.challoImageToSave
            blockImage = NewChallo.challoImageToSave
        }
        let ratio = 30 / NewChallo.numberOfBlocks
        for day in 1...ratio {
            for blockNo in 1...NewChallo.numberOfBlocks {
            let duration = String(NewChallo.challoTransferArray[blockNo - 1]!.duration)
            let durationMetric = NewChallo.challoTransferArray[blockNo - 1]!.durationMetric
                let block = BlockFormat(blockID: "", title: NewChallo.challoTransferArray[blockNo - 1]?.blockTitle ?? "", order: String(day * blockNo), duration: "\(duration) \(durationMetric)", imageURL: nil, image: blockImage)
                self.kasamBlocks.append(block)
            }
            if day == ratio {
                self.tableView.reloadData()
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }
        }
    }
    
    @IBAction func createChalloButtonPressed(_ sender: Any) {
        if NewChallo.loadedInChalloImage == UIImage() {
            createChallo(existingKasamID: nil)
        } else {
            createChallo(existingKasamID: NewChallo.kasamID)
        }
    }
    
    @IBAction func deleteChalloButtonPressed(_ sender: Any) {
        if NewChallo.loadedInChalloImage == UIImage() {
            //User trying to create a new Challo, so do not save Challo
            self.navigationController?.popToRootViewController(animated: true)
        } else {
            //delete the existing Challo
            let popupImage = UIImage.init(icon: .fontAwesomeRegular(.trashAlt), size: CGSize(width: 30, height: 30), textColor: .white)
            showPopupConfirmation(title: "Are you sure?", description: "You won't be able to undo this action", image: popupImage, buttonText: "Delete Challo") {(success) in
                Database.database().reference().child("Coach-Kasams").child(self.kasamID).removeValue()                //delete challo
                Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Kasams").child(self.kasamID).removeValue()
                self.navigationController?.popToRootViewController(animated: true)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "ShowCompletionAnimation"), object: self)
            }
        }
    }
    
    //STEP 1 - Saves Challo Text Data
    func createChallo(existingKasamID: String?) {
        //all fields filled, so can create the Challo now
        loadingAnimation(animationView: animationView, animation: "rocket-fast", height: 200, overlayView: animationOverlay, loop: true, completion: nil)
        self.view.isUserInteractionEnabled = false
        var kasamID = Database.database().reference().child("Coach-Kasams").childByAutoId()
        if existingKasamID != nil {
            //creating a new Challo, so assign a new ChalloID
            kasamID = Database.database().reference().child("Coach-Kasams").child(existingKasamID!)
            kasamIDGlobal = kasamID.key ?? ""
        }
        if NewChallo.challoImageToSave != NewChallo.loadedInChalloImage {
            //user has uploaded a new image, so save it
            saveImage(image: self.headerImageView!.image!, location: "kasam/\(kasamID.key!)/kasam_header", completion: {uploadedImageURL in
                if uploadedImageURL != nil {
                    self.registerKasamData(kasamID: kasamID, imageUrl: uploadedImageURL!)
                } else {
                    //no image added, so use the default one
                    self.registerKasamData(kasamID: kasamID, imageUrl: "https://firebasestorage.googleapis.com/v0/b/kasam-coach.appspot.com/o/kasam%2Fimage-add-placeholder.jpg?alt=media&token=491fdb83-2612-4423-9d2e-cdd44ab8157e")
                }
            })
        } else {
            //user using same image, so no need to save image
            let uploadedImageURL = NewChallo.loadedInChalloImageURL?.absoluteString
            registerKasamData(kasamID: kasamID, imageUrl: uploadedImageURL!)
        }
    }
    
    //STEP 2 - Save Challo Image
    func saveImage(image: UIImage?, location: String, completion: @escaping (String?)->()) {
        //Saves Kasam Image in Firebase Storage
        let imageData = image?.jpegData(compressionQuality: 0.6)
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
    
        if imageData != nil {
            storageRef.child(location).putData(imageData!, metadata: metaData) {(metaData, error) in
                if error == nil, metaData != nil {
                    self.storageRef.child(location).downloadURL { url, error in
                        completion(url!.absoluteString)
                    }
                }
            }
        } else {completion(nil)}
    }
    
    //STEP 3 - Register Challo Data in Firebase Database
    func registerKasamData (kasamID: DatabaseReference, imageUrl: String) {
        kasamImageGlobal = imageUrl
        let kasamDictionary = ["Title": NewChallo.kasamName, "Genre": "Personal", "Description": NewChallo.kasamDescription, "Timing": "6:00pm - 7:00pm", "Image": imageUrl, "KasamID": kasamID.key, "CreatorID": Auth.auth().currentUser?.uid, "CreatorName": Auth.auth().currentUser?.displayName, "Followers": "", "Type": "User", "Rating": "5", "Blocks": "blocks", "Level":"Beginner", "Metric": NewChallo.chosenMetric]
    
        kasamID.setValue(kasamDictionary) {(error, reference) in
            if error != nil {
                print(error!)
            } else {
            //kasam successfully created
        Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Kasams").child(self.kasamIDGlobal).setValue(NewChallo.kasamName)
            self.saveBlocks()
            }
        }
    }
    
    //STEP 4 - Save block info under Challo
    func saveBlocks(){
        self.view.endEditing(true)                  //for adding last text field value with dismiss keyboard
        let newBlock = Database.database().reference().child("Coach-Kasams").child(kasamIDGlobal).child("Blocks")
        var successBlockCount = 0
        for j in 1...NewChallo.numberOfBlocks {
            let blockID = newBlock.childByAutoId()
            let transferBlockDuration = "\(NewChallo.challoTransferArray[j - 1]?.duration ?? 15) \(NewChallo.challoTransferArray[j - 1]?.durationMetric ?? "secs")"
            let blockActivity = NewChallo.fullActivityMatrix[j]
            var metric = 0
            var increment = 1
            switch NewChallo.chosenMetric {
                case "Reps":
                    metric = blockActivity?[0]?.reps ?? 0          //using 0 as only one activity loaded per block
                    increment = blockActivity?[0]?.interval ?? 1
                case "Timer": do {
                    let hour = (blockActivity?[0]?.hour ?? 0) * 3600
                    let min = (blockActivity?[0]?.min ?? 0) * 60
                    let sec = (blockActivity?[0]?.sec ?? 0)
                    metric = hour + min + sec
                }
                default: metric = 0
            }
            let defaultActivityImage = "https://firebasestorage.googleapis.com/v0/b/kasam-coach.appspot.com/o/kasam%2Fgiphy%20(1).gif?alt=media&token=e91fd36a-1e2a-43db-b211-396b4b8d65e1"
            saveImage(image: (blockActivity?[0]?.imageToSave), location: "kasam/\(kasamIDGlobal)/activity/activity\(j)") {(savedImageURL) in
                let activity = ["Description" : blockActivity?[0]?.description ?? "",
                                "Image" : savedImageURL ?? defaultActivityImage,
                                "Metric" : String(metric * increment),
                                "Interval" : String(increment),
                                "Title" : blockActivity?[0]?.title ?? "",
                                "Type" : NewChallo.chosenMetric] as [String : Any]
                let activityMatrix = ["1":activity]
                let blockDictionary = ["Activity": activityMatrix, "Duration": transferBlockDuration, "Image": self.kasamImageGlobal, "Order": String(j), "Rating": "5", "Title": NewChallo.challoTransferArray[j - 1]?.blockTitle ?? "Block Title", "BlockID": blockID.key!] as [String : Any]
                blockID.setValue(blockDictionary) {
                    (error, reference) in
                    if error != nil {
                        print(error!)
                    } else {
                        //Challo successfully created
                        successBlockCount += 1
                        //All the blocks and their images are saved, so go back to the profile view
                        if successBlockCount == NewChallo.numberOfBlocks {
                            self.animationView.removeFromSuperview()
                            self.animationOverlay.removeFromSuperview()
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "ShowCompletionAnimation"), object: self)
                            self.view.isUserInteractionEnabled = true
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if reviewOnly == true {
            setupReviewOnly()
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
            self.navigationController?.navigationBar.shadowImage = UIImage()
            self.navigationController?.navigationBar.isTranslucent = true
            self.navigationController?.navigationBar.backgroundColor = UIColor.clear            //set navigation bar color to clear
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if reviewOnly == true {
            self.navigationController?.navigationBar.tintColor = UIColor.white                  //change back arrow color to white
        }
    }
}

//------------------------------------------------------------------------------------------------------------

extension ChalloHolder: UITableViewDataSource, UITableViewDelegate {
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
        print("hello")
        blockIDGlobal = kasamBlocks[indexPath.row].blockID
        performSegue(withIdentifier: "goToChalloActivityViewer", sender: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
