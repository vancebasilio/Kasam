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
import youtube_ios_player_helper

class KasamHolder: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var tableView: UITableView! {didSet {tableView.estimatedRowHeight = 100}}
    @IBOutlet var headerView : UIView!
    @IBOutlet var profileView : UIView!
    @IBOutlet weak var profileViewRadius: UIView!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var addButtonText: UIButton!
    @IBOutlet var kasamTitle : UILabel!
    @IBOutlet weak var completionCheck: UIButton!
    @IBOutlet weak var coachName: UIButton!
    @IBOutlet weak var kasamDescription: UILabel!
    @IBOutlet weak var kasamDescriptionTrailingMargin: NSLayoutConstraint!
    @IBOutlet weak var kasamType: UILabel!
    @IBOutlet weak var kasamLevel: UILabel!
    @IBOutlet weak var followersNo: UILabel!
    @IBOutlet var headerLabel : UILabel!
    @IBOutlet weak var constraintHeightHeaerImages: NSLayoutConstraint!
    @IBOutlet weak var createKasamButton: UIButton!
    @IBOutlet weak var deleteKasamButton: UIButton!
    @IBOutlet weak var createDeleteButtonStackView: UIStackView!
    @IBOutlet weak var kasamDeetsStackView: UIStackView!
    @IBOutlet weak var previewButton: UIButton!
    @IBOutlet weak var playerView: YTPlayerView!
    
    var headerBlurImageView:UIImageView!
    var headerImageView:UIImageView!
    var observer: NSObjectProtocol?
    var chosenTime = ""
    var chosenTimeHour = 0
    var chosenTimeMin = 0
    var chosenRepeat = ""
    var chosenDate : [String:Int] = [:]
    var startDate = ""
    var previewLink = ""
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
    let animationView = AnimationView()
    
    //Review Only Variables
    var reviewOnly = false
    let animationOverlay = UIView()
    var storageRef = Storage.storage().reference()
    var kasamImageGlobal = ""
    var reviewOnlyBlockNo = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLoad()
        setupTwitterParallax()
        self.playerView.delegate = self
        if reviewOnly == false {
            getKasamData()
            getBlocksData()
            countFollowers()
            registeredCheck()
        }
    }
    
    func setupLoad(){
        previewButton.layer.cornerRadius = 15
        previewButton.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight:.regular), prefixTextColor: UIColor.white, icon: .fontAwesomeSolid(.play), iconColor: UIColor.white, postfixText: "  Preview", postfixTextFont: UIFont.systemFont(ofSize: 15, weight:.medium), postfixTextColor: UIColor.white, backgroundColor: UIColor.black, forState: .normal, iconSize: 15)
        
        profileViewRadius.layer.cornerRadius = 16.0
        profileViewRadius.clipsToBounds = true
        headerLabel.text = kasamGTitle
        var createKasamTitle = "  Create Kasam"
        if NewKasam.loadedInKasamImage != UIImage() {
            createKasamTitle = "  Update Kasam"
        }
        if reviewOnly == true {
            previewButton.isHidden = true
            kasamDeetsStackView.isHidden = true
            createDeleteButtonStackView.isHidden = false
            addButton.isHidden = true
            addButtonText.isHidden = true
            
            createKasamButton.layer.cornerRadius = 20.0
            createKasamButton.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight:.regular), prefixTextColor: UIColor.white, icon: .fontAwesomeSolid(.magic), iconColor: UIColor.white, postfixText: createKasamTitle, postfixTextFont: UIFont.systemFont(ofSize: 15, weight:.medium), postfixTextColor: UIColor.white, backgroundColor: UIColor.black, forState: .normal, iconSize: 15)
            
            deleteKasamButton.layer.cornerRadius = 20.0
            deleteKasamButton.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight:.regular), prefixTextColor: UIColor.white, icon: .fontAwesomeSolid(.trashAlt), iconColor: UIColor.white, postfixText: "  Delete Kasam", postfixTextFont: UIFont.systemFont(ofSize: 15, weight:.medium), postfixTextColor: UIColor.white, backgroundColor: UIColor.init(hex: 0xDB482D), forState: .normal, iconSize: 15)
        }
    }
    
    @IBAction func coachNamePress(_ sender: Any) {
        if reviewOnly == false {
            self.performSegue(withIdentifier: "goToCoach", sender: self)
        }
    }
    
    @IBAction func previewButtonPressed(_ sender: Any) {
        playerView.load(withVideoId: previewLink)
        playerView.isHidden = false
        loadingAnimation(animationView: animationView, animation: "fireworks-loading", height: 200, overlayView: nil, loop: true, completion: nil)
        self.view.isUserInteractionEnabled = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToCoach" {
            let coachTransferHolder = segue.destination as! CoachHolder
            coachTransferHolder.coachID = self.coachIDGlobal
            coachTransferHolder.coachGName = self.coachNameGlobal
            coachTransferHolder.previousWindow = self.kasamTitle.text!
        } else if segue.identifier == "goToKasamActivityViewer" {
            let kasamActivityHolder = segue.destination as! KasamActivityViewer
            if reviewOnly == false {
                kasamActivityHolder.kasamID = kasamID
                kasamActivityHolder.blockID = blockIDGlobal
                kasamActivityHolder.viewingOnlyCheck = true
                kasamActivityHolder.dayOrder = "0"          //this field is for saving kasam progress, so set it to zero as we're only reviewing
            } else if reviewOnly == true {
                kasamActivityHolder.reviewOnly = true
                kasamActivityHolder.blockID = blockIDGlobal        //this is the block No that gets transferred
            }
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
                self.previewLink = value["Preview"] as? String ?? ""
                if self.previewLink != "" {
                    self.previewButton.isHidden = false
                }
                self.headerImageView?.sd_setImage(with: headerURL, placeholderImage: PlaceHolders.kasamLoadingImage)
            }
        })
    }
    
    //Retrieves Blocks based on Kasam selected
    func getBlocksData() {
        Database.database().reference().child("Coach-Kasams").child(kasamID).child("Blocks").observeSingleEvent(of: .value, with:{ (snap) in
            var blockNo = snap.childrenCount
            if blockNo == 0 {
                blockNo = 1
            }
            let ratio = 30 / (blockNo)
            var dayNumber = 1
            for _ in 1...ratio {
                Database.database().reference().child("Coach-Kasams").child(self.kasamID).child("Blocks").observe(.childAdded, with: { (snapshot) in
                    if let value = snapshot.value as? [String: Any] {
                        let blockID = snapshot.key
                        let blockURL = URL(string: value["Image"] as? String ?? "")
                        let block = BlockFormat(blockID: blockID, title: value["Title"] as? String ?? "", order: String(dayNumber), duration: value["Duration"] as? String ?? "", imageURL: blockURL ?? URL(string:PlaceHolders.kasamLoadingImageURL), image: nil)
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
                self.chosenTimeHour = timeVC.hour
                self.chosenTimeMin = timeVC.min
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
    
    func setupNotifications(){
        // Ask permission for notifications
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            if granted {
                //Permission granted
            } else {
                //Permission denied
            }
        }
        scheduleNotification()
    }
    
    private func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "\(kasamGTitle) Reminder"
        content.body = "Time to get cracking on your '\(kasamGTitle)' Kasam"
        content.categoryIdentifier = "\(kasamGTitle) \(self.startDate) \(self.chosenTime)"
        content.sound = UNNotificationSound.default
        content.userInfo = ["example": "information"] // You can retrieve this when displaying notification

        //Set notification to trigger at the chosen time
        let startDate = stringToDate(date: self.startDate)
        let endDate = Calendar.current.date(byAdding: .day, value: 30, to: startDate)!
        
        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: startDate, to: endDate)
        dateComponents.hour = self.chosenTimeHour
        dateComponents.minute = self.chosenTimeMin
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create request
        let uniqueID = "Notification-\(kasamID)"        // Keep a record of this
        let request = UNNotificationRequest(identifier: uniqueID, content: content, trigger: trigger)
        let center = UNUserNotificationCenter.current()
        center.add(request) {(error : Error?) in        // Add the notification request
            if let theError = error {
                print(theError.localizedDescription)
            }
        }
    }
    
    
    
    func registerUserToKasam() {
        setupNotifications()
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
                //STEP 4: Adds the user preferences to the Kasam they just followed
                Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Kasam-Following").child(self.kasamID).updateChildValues(["Kasam Name" : self.kasamTitle.text!, "Date Joined": self.startDate, "Day Joined": self.startDay, "Time": self.chosenTime, "Days": self.chosenDate]) {(error, reference) in
                    if error != nil {
                        print(error!)
                    } else {
                        Analytics.logEvent("following_Kasam", parameters: ["kasam_name":self.kasamTitle.text ?? "Kasam Name"])
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
                Analytics.logEvent("unfollowing_Kasam", parameters: ["kasam_name":self.kasamTitle.text ?? "Kasam Name"])
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
        self.addButton.setImage(UIImage(named:"kasam-add"), for: .normal)
        Database.database().reference().child("Coach-Kasams").child(kasamID).child("Followers").observeSingleEvent(of: .value, with: {(snapshot) in
            if SavedData.kasamDict[self.kasamID]?.status == "completed" {
                //kasam completed in the past
                self.kasamDescriptionTrailingMargin.constant = 79.5
                self.completionCheck.isHidden = false
                self.completionCheck.setIcon(icon: .fontAwesomeSolid(.trophy), iconSize: 18, color: .white, backgroundColor: .darkGray, forState: .normal)
                self.completionCheck.layer.cornerRadius = self.completionCheck.frame.height / 2
                self.completionCheck.clipsToBounds = true
                self.addButtonText.setIcon(icon: .fontAwesomeSolid(.redo), iconSize: 20, color: .white, backgroundColor: .clear, forState: .normal)
            } else {
                if snapshot.hasChild((Auth.auth().currentUser?.uid)!) {
                    //user registered to kasam
                    self.registerCheck = 1
                    self.addButtonText.setIcon(icon: .fontAwesomeSolid(.check), iconSize: 20, color: .white, backgroundColor: .clear, forState: .normal)
                } else{
                    //user not registered to kasam
                    self.registerCheck = 0
                    self.addButtonText.setIcon(icon: .fontAwesomeSolid(.plus), iconSize: 20, color: .white, backgroundColor: .clear, forState: .normal)
                }
            }
        })
    }
    
    //REVIEW ONLY-------------------------------------------------------------------------------------------
    
    func setupReviewOnly(){
        //load in values from add Kasam pages
        self.kasamBlocks.removeAll()
        coachName.isEnabled = false
        coachName.setTitle(Auth.auth().currentUser?.displayName, for: .normal)
        kasamTitle.text = NewKasam.kasamName
        headerLabel.text = NewKasam.kasamName
        kasamDescription.text = NewKasam.kasamDescription
        kasamType.text = "Personal"
        kasamLevel.text = "Beginner"
        var blockImage = UIImage()
        if NewKasam.kasamImageToSave != UIImage() && NewKasam.loadedInKasamImage == UIImage() {
        //CASE 1 - creating a new Kasam, and image added
            headerImageView.image = NewKasam.kasamImageToSave
            blockImage = NewKasam.kasamImageToSave
        } else if NewKasam.kasamImageToSave == UIImage() && NewKasam.loadedInKasamImage == UIImage() {
        //CASE 2 - creating new kasam, and hasn't uploaded an image
           headerImageView.image = PlaceHolders.kasamHeaderPlaceholderImage
           blockImage = PlaceHolders.kasamHeaderPlaceholderImage!
        } else if NewKasam.kasamImageToSave != UIImage() && NewKasam.loadedInKasamImage != UIImage() {
        //CASE 3 - editing existing Kasam, and user is using a new image, so save new image
            headerImageView.image = NewKasam.kasamImageToSave
            blockImage = NewKasam.kasamImageToSave
        } else if NewKasam.kasamImageToSave == UIImage() && NewKasam.loadedInKasamImage != UIImage() {
        //CASE 4 - editing existing Kasam, and user has NOT changed header image, so use existing image
            headerImageView.image = NewKasam.loadedInKasamImage
            blockImage = NewKasam.loadedInKasamImage
        }
        let ratio = 30 / NewKasam.numberOfBlocks
        for day in 1...ratio {
            for blockNo in 1...NewKasam.numberOfBlocks {
                let duration = NewKasam.kasamTransferArray[blockNo]?.duration
                let durationMetric = NewKasam.kasamTransferArray[blockNo]?.durationMetric
                let block = BlockFormat(blockID: String(blockNo), title: NewKasam.kasamTransferArray[blockNo]?.blockTitle ?? "", order: String(day * blockNo), duration: "\(duration ?? 15) \(durationMetric ?? "secs")", imageURL: nil, image: blockImage)
                self.kasamBlocks.append(block)
            }
            if day == ratio {
                self.tableView.reloadData()
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }
        }
    }
    
    @IBAction func createKasamButtonPressed(_ sender: Any) {
        completeCheck {(check) in
            if check == true {
                if NewKasam.loadedInKasamImage == UIImage() {
                    //creating a new kasam
                    self.createKasam(existingKasamID: nil)
                } else {
                    //updating an existing kasam
                    self.createKasam(existingKasamID: NewKasam.kasamID)
                }
            } else {
                let popupImage = UIImage.init(icon: .fontAwesomeSolid(.cookieBite), size: CGSize(width: 30, height: 30), textColor: .white)
                showPopupConfirmation(title: "You're missing a few fields...", description: "", image: popupImage, buttonText: "Fill them in") {(success) in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "GoToBack"), object: self)
                    SwiftEntryKit.dismiss()
                }
            }
        }
    }
    
    @IBAction func deleteKasamButtonPressed(_ sender: Any) {
        if NewKasam.loadedInKasamImage == UIImage() {
            //User trying to create a new Kasam, so do not save Kasam
            self.navigationController?.popToRootViewController(animated: true)
        } else {
            //delete the existing Kasam
            let popupImage = UIImage.init(icon: .fontAwesomeRegular(.trashAlt), size: CGSize(width: 30, height: 30), textColor: .white)
            showPopupConfirmation(title: "Are you sure?", description: "You won't be able to undo this action", image: popupImage, buttonText: "Delete Kasam") {(success) in
                let coachKasamDB = Database.database().reference().child("Coach-Kasams")
                let userKasamDB = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Kasams")
                
                coachKasamDB.child(NewKasam.kasamID).removeValue()                 //delete kasam
                userKasamDB.child(NewKasam.kasamID).removeValue()                  //remove kasam from creator's list
                
                //delete the pictures from the Kasam if it's not the placeholder image
                if let headerImageToDelete = NewKasam.loadedInKasamImageURL {self.deleteFileFromURL(from: headerImageToDelete)}
                for block in 1...NewKasam.fullActivityMatrix.count {
                    if let activityImageToDelete = NewKasam.fullActivityMatrix[block]?[0]?.imageToLoad {
                        self.deleteFileFromURL(from: activityImageToDelete)
                    }
                }
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: "getUserKasams"), object: self)
                self.navigationController?.popToRootViewController(animated: true)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "ShowCompletionAnimation"), object: self)
            }
        }
    }
    
    func deleteFileFromURL(from photoURL: URL) {
        if photoURL != URL(string:PlaceHolders.kasamHeaderPlaceholderURL) || photoURL != URL(string:PlaceHolders.kasamActivityPlaceholderURL) {
            let photoStorageRef = Storage.storage().reference(forURL: photoURL.absoluteString)
            photoStorageRef.delete(completion: {(error) in
                if let error = error {
                    print(error)
                } else {
                    // success
                    print("deleted \(photoURL)")
                }
            })
        }
    }
    
    func completeCheck(completion:@escaping (Bool) -> ()) {
        var checkCount = 0
        for blockNo in 1...NewKasam.numberOfBlocks {
            if NewKasam.kasamTransferArray[blockNo]?.complete == true {
                checkCount += 1
            }
        }
        if checkCount == NewKasam.numberOfBlocks {
            completion(true)
        } else {
            completion(false)
        }
    }
    
    //STEP 1 - Saves Kasam Text Data
    func createKasam(existingKasamID: String?) {
        print("1. creating kasam")
        //all fields filled, so can create the Kasam now
        loadingAnimation(animationView: animationView, animation: "rocket-fast", height: 200, overlayView: animationOverlay, loop: true, completion: nil)
        self.view.isUserInteractionEnabled = false
        var kasamID = Database.database().reference().child("Coach-Kasams").childByAutoId()
        if existingKasamID != nil {
            //creating a new Kasam, so assign a new KasamID
            kasamID = Database.database().reference().child("Coach-Kasams").child(existingKasamID!)
        }
        if NewKasam.kasamImageToSave != NewKasam.loadedInKasamImage {
            //CASE 1 - user has uploaded a new image, so save it
            saveImage(image: self.headerImageView!.image!, location: "kasam/\(kasamID.key!)/kasam_header", completion: {uploadedImageURL in
                if uploadedImageURL != nil {
                    self.registerKasamData(kasamID: kasamID, imageUrl: uploadedImageURL!)
                }
            })
        } else if NewKasam.kasamImageToSave == UIImage() {
            //CASE 2 - no image added, so use the default one
            self.registerKasamData(kasamID: kasamID, imageUrl: PlaceHolders.kasamHeaderPlaceholderURL)
        } else {
            //CASE 3 - user editing a kasam and using same kasam image, so no need to save image
            let uploadedImageURL = NewKasam.loadedInKasamImageURL?.absoluteString
            registerKasamData(kasamID: kasamID, imageUrl: uploadedImageURL!)
        }
    }
    
    //STEP 2 - Save Kasam Image
    func saveImage(image: UIImage?, location: String, completion: @escaping (String?)->()) {
        print("2. saving image")
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
    
    //STEP 3 - Register Kasam Data in Firebase Database
    func registerKasamData(kasamID: DatabaseReference, imageUrl: String) {
        print("3. registering kasam")
        kasamImageGlobal = imageUrl
        let kasamDB = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Kasams").child(kasamID.key!)
        let kasamDictionary = ["Title": NewKasam.kasamName, "Genre": "Personal", "Description": NewKasam.kasamDescription, "Timing": "6:00pm - 7:00pm", "Image": imageUrl, "KasamID": kasamID.key, "CreatorID": Auth.auth().currentUser?.uid, "CreatorName": Auth.auth().currentUser?.displayName, "Type": "User", "Rating": "5", "Blocks": "blocks", "Level":"Beginner", "Metric": NewKasam.chosenMetric]
    
        if NewKasam.kasamID != "" {
            //updating existing kasam
            kasamID.updateChildValues(kasamDictionary as [AnyHashable : Any]) {(error, reference) in
            if error != nil {
                    print(error!)
                } else {
                //kasam successfully created
             kasamDB.setValue(NewKasam.kasamName)
                self.saveBlocks(kasamID: kasamID)
                }
            }
        } else {
            //creating new kasam
            kasamID.setValue(kasamDictionary) {(error, reference) in
                if error != nil {
                    print(error!)
                } else {
                //kasam successfully created
                kasamDB.setValue(NewKasam.kasamName)
                self.saveBlocks(kasamID: kasamID)
                }
            }
        }
    }
    
    //STEP 4 - Save block info under Kasam
    func saveBlocks(kasamID: DatabaseReference){
        print("4. saving blocks")
        let newBlockDB = Database.database().reference().child("Coach-Kasams").child(kasamID.key!).child("Blocks")
        print(newBlockDB)
        var successBlockCount = 0
        for j in 1...NewKasam.numberOfBlocks {
            let blockID = newBlockDB.childByAutoId()
            let transferBlockDuration = "\(NewKasam.kasamTransferArray[j]?.duration ?? 15) \(NewKasam.kasamTransferArray[j]?.durationMetric ?? "secs")"
            let blockActivity = NewKasam.fullActivityMatrix[j]
            var metric = 0
            var increment = 1
            switch NewKasam.chosenMetric {
                case "Reps":
                    metric = blockActivity?[0]?.reps ?? 0          //using 0 as only one activity loaded per block
                    increment = blockActivity?[0]?.interval ?? 1
                case "Timer": do {
                    let hour = (blockActivity?[0]?.hour ?? 0) * 3600
                    let min = (blockActivity?[0]?.min ?? 0) * 60
                    let sec = (blockActivity?[0]?.sec ?? 0)
                    increment = 1
                    metric = hour + min + sec
                }
                case "Checkmark" : do {
                    metric = 100
                    increment = 1
                }
                default: metric = 0
            }
            let defaultActivityImage = PlaceHolders.kasamActivityPlaceholderURL
            saveImage(image: (blockActivity?[0]?.imageToSave), location: "kasam/\(kasamID.key!)/activity/activity\(j)") {(savedImageURL) in
                let activity = ["Description" : blockActivity?[0]?.description ?? "",
                                "Image" : savedImageURL ?? defaultActivityImage,
                                "Metric" : String(metric * increment),
                                "Interval" : String(increment),
                                "Title" : blockActivity?[0]?.title ?? "",
                                "Type" : NewKasam.chosenMetric] as [String : Any]
                let activityMatrix = ["1":activity]
                let blockDictionary = ["Activity": activityMatrix, "Duration": transferBlockDuration, "Image": self.kasamImageGlobal, "Order": String(j), "Rating": "5", "Title": NewKasam.kasamTransferArray[j]?.blockTitle ?? "Block Title", "BlockID": blockID.key!] as [String : Any]
                blockID.setValue(blockDictionary) {
                    (error, reference) in
                    if error != nil {
                        print(error!)
                    } else {
                        //Kasam successfully created
                        successBlockCount += 1
                        //All the blocks and their images are saved, so go back to the profile view
                        if successBlockCount == NewKasam.numberOfBlocks {
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
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
            self.navigationController?.navigationBar.shadowImage = UIImage()
            self.navigationController?.navigationBar.isTranslucent = true
            self.navigationController?.navigationBar.backgroundColor = UIColor.clear            //set navigation bar color to clear
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if reviewOnly == true {
            setupReviewOnly()
            self.navigationController?.navigationBar.tintColor = UIColor.white                  //change back arrow color to white
        }
    }
}

//------------------------------------------------------------------------------------------------------------

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
        blockIDGlobal = kasamBlocks[indexPath.row].blockID
        performSegue(withIdentifier: "goToKasamActivityViewer", sender: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension KasamHolder: YTPlayerViewDelegate {
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        self.playerView.playVideo()
        animationView.removeFromSuperview()
        self.view.isUserInteractionEnabled = true
    }
}
