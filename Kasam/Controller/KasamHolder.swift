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
import AVFoundation

class KasamHolder: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var tableView: UITableView! {didSet {tableView.estimatedRowHeight = 100}}
    @IBOutlet var headerView : UIView!
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var kasamBadgeHolder: UIView!
    @IBOutlet weak var headerBadgeMask: UIView!
    @IBOutlet weak var badgeInfo: UILabel!
    @IBOutlet weak var badgeCompletion: UILabel!
    @IBOutlet weak var editKasamButton: UIButton!
    
    @IBOutlet var profileView : UIView!
    @IBOutlet weak var profileViewRadius: UIView!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var addButtonText: UIButton!
    @IBOutlet weak var trophiesView: UIStackView!
    @IBOutlet weak var trophyIcon: UIButton!
    @IBOutlet weak var noTrophiesAchieved: UILabel!
    @IBOutlet var kasamTitle : UILabel!
    @IBOutlet weak var coachName: UIButton!
    @IBOutlet weak var kasamDescription: UILabel!
    @IBOutlet weak var kasamDescriptionTrailingMargin: NSLayoutConstraint!
    
    //Kasam Details Bar
    @IBOutlet weak var followingIcon: UIButton!
    @IBOutlet weak var TypeIcon: UIButton!
    @IBOutlet weak var kasamGenre: UILabel!
    @IBOutlet weak var kasamLevelIcon: UIButton!
    @IBOutlet weak var kasamLevel: UILabel!
    @IBOutlet weak var followersNo: UILabel!
    @IBOutlet weak var kasamBadgeHeight: NSLayoutConstraint!
    
    @IBOutlet var headerLabel: UILabel!
    
    @IBOutlet weak var finishIcon: UIButton!
    @IBOutlet weak var finishLabel: UILabel!
    @IBOutlet weak var finishHolder: UIView!
    @IBOutlet weak var extendHolder: UIView!
    @IBOutlet weak var extendIcon: UIButton!
    @IBOutlet weak var extendLabel: UILabel!
    
    @IBOutlet weak var constraintHeightHeaerImages: NSLayoutConstraint!
    @IBOutlet weak var createKasamButton: UIButton!
    @IBOutlet weak var deleteKasamButton: UIButton!
    @IBOutlet weak var createDeleteButtonStackView: UIStackView!
    @IBOutlet weak var kasamDeetsStackView: UIStackView!
    @IBOutlet weak var previewButton: UIButton!
    @IBOutlet weak var playerView: YTPlayerView!
    
    var headerBlurImageView: UIImageView!
    var saveTimeObserver: NSObjectProtocol?
    var unfollowObserver: NSObjectProtocol?
    var userKasam = false
    
    var initialRepeat: Int?             //used to compare against new repeatDuration; if user switching from one-time to repeat
    
    var chosenTime = ""
    var chosenTimeHour = 0
    var chosenTimeMin = 0
    var chosenRepeat = 30
    var startDate = ""
    var notificationCheck = true
    
    var previewLink = ""
    var kasamBlocks: [BlockFormat] = []
    var followerCountGlobal = 0
    var kasamID: String = ""            //transfered in values from previous vc
    var kasamGTitle: String = ""        //transfered in values from previous vc
    var timelineDuration: Int?          //only for timeline Kasams
    var kasamCompletedRadio = 0.0
    
    var kasamTracker: [Tracker] = [Tracker]()
    var badgeThresholds = 30
    var registerCheck = 0
    var coachIDGlobal = ""
    var coachNameGlobal = ""
    var blockURLGlobal = ""
    var blockIDGlobal = ""
    var pastJoinDate = ""
    let animationView = AnimationView()
    let animationOverlay = UIView()
    var kasamMetric = ""
    var benefitsArray = [""]
    var singleBlock = true
    var ratio = 0.0
    var headerBadgeIcon = AnimationView()
    let gradientLayer = CAGradientLayer()
    var setupCheck = false
    
    let keypath = AnimationKeypath(keypath: "**.Color")
    let colorProvider = ColorValueProvider(UIColor.lightGray.lighter.lottieColorValue)
    
    //Review Only Variables
    var reviewOnly = false
    
    var reviewOnlyBlockNo = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTwitterParallax()
        setupButtons()
        notificationCenter()
        self.playerView.delegate = self
        if reviewOnly == false {
            getKasamData()
            getBlocksData()
            countFollowers()
            registeredCheck()
        }
    }
    
    func notificationCenter(){
        let refreshBadge = NSNotification.Name("RefreshKasamHolderBadge")
        NotificationCenter.default.addObserver(self, selector: #selector(KasamHolder.refreshBadge), name: refreshBadge, object: nil)
    }
    
    @objc func refreshBadge(){
        self.getKasamBadgeInfo()
        self.registeredCheck()
    }
    
    func setupButtons(){
        previewButton.layer.cornerRadius = 15
        previewButton.setTitle("Preview", for: .normal)
        followingIcon.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight:.regular), prefixTextColor: UIColor.white, icon: .fontAwesomeSolid(.userFriends), iconColor: UIColor.darkGray, postfixText: "", postfixTextFont: UIFont.systemFont(ofSize: 15, weight:.medium), postfixTextColor: UIColor.white, backgroundColor: UIColor.clear, forState: .normal, iconSize: 15)
        profileViewRadius.layer.cornerRadius = 16.0
        profileViewRadius.clipsToBounds = true
        headerLabel.text = kasamGTitle
        var createKasamTitle = "  Create Kasam"
        if NewKasam.loadedInKasamImage != UIImage() {
            createKasamTitle = "  Update Kasam"
        }
        self.kasamDescriptionTrailingMargin.constant = 79.5
        self.trophyIcon.layer.cornerRadius = self.kasamLevelIcon.frame.height / 2
        
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
            trophiesView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(badgesAchievedPopup)))
        }
        
        @objc func badgesAchievedPopup() {
            showBadgesPopup(kasamID: kasamID)
        }
    
    //KASAM BADGE------------------------------------------------------------------------------------
    
    func setupKasamBadge(){
        DispatchQueue.global(qos: .background).sync {
            self.getKasamBadgeInfo()
        }
        self.kasamBadgeHolder.alpha = 1.0
        self.badgeInfo.backgroundColor = UIColor.colorFive.lighter
        self.badgeInfo.layer.cornerRadius = 8.0
        let animation = CATransition()
        animation.type = .fade
        animation.duration = 0.4
        self.kasamBadgeHolder.layer.add(animation, forKey: nil)
    }
    
    func getKasamBadgeInfo(){        //Only for active kasams
        //STEP 1 - BADGES ACHIEVED
        badgesAchieved()
        
        if SavedData.kasamDict[kasamID]?.currentDay != nil && SavedData.kasamDict[kasamID]?.repeatDuration != nil  {
            //STEP 2 - Header Badge & Info (if Kasam is being followed and is a repeat Kasam)
            headerBadge()
            
            //STEP 3 - PREP TO SHOW
            if SavedData.kasamDict[kasamID]?.currentStatus == "active" && self.setupCheck == false {
                DispatchQueue.main.async {                      //Only unhide the badge when everything is done loading
                    self.headerBadgeIcon.frame = self.headerBadgeMask.bounds
                    self.headerBadgeMask.backgroundColor = UIColor.colorFive.lighter
                    self.gradientLayer.frame = self.headerBadgeMask.bounds
                    let fillColor = UIColor.colorFive.lighter.cgColor
                    let bgColor = UIColor.lightGray.lighter.cgColor
                    self.gradientLayer.colors = [bgColor, bgColor, fillColor, fillColor]
                    self.headerBadgeMask.layer.addSublayer(self.gradientLayer)
                    self.headerBadgeMask.mask = self.headerBadgeIcon
                    self.kasamBadgeHolder.isHidden = false
                    self.headerBadgeIcon.backgroundBehavior = .pauseAndRestore
                    self.headerBadgeIcon.play()
                    self.setupCheck = true
                }
            }
        }
    }
    
    func headerBadge(){
        if SavedData.kasamDict[kasamID]!.repeatDuration > 0 && SavedData.kasamDict[kasamID]?.currentStatus == "active" {
            self.headerImageView.alpha = 0.7
            var daysCompleted = Double(SavedData.kasamDict[kasamID]?.streakInfo.daysWithAnyProgress ?? 0)
            finishIcon.setIcon(icon: .fontAwesomeRegular(.checkCircle), iconSize: 35, color: UIColor.colorFive.lighter, forState: .normal)
            extendIcon.setIcon(icon: .fontAwesomeSolid(.arrowCircleRight), iconSize: 30, color: UIColor.colorFive.lighter, forState: .normal)
            finishLabel.textColor = UIColor.colorFive.lighter
            extendLabel.textColor = UIColor.colorFive.lighter
            if SavedData.kasamDict[kasamID]!.currentDay >= SavedData.kasamDict[kasamID]!.repeatDuration {
                //OPTION 1 - Kasam completed, but not closed out or extended
                if SavedData.kasamDict[kasamID]?.repeatDuration == 0 {daysCompleted = Double(SavedData.kasamDict[kasamID]?.percentComplete ?? 0)}
                ratio = (daysCompleted / Double(SavedData.kasamDict[kasamID]!.repeatDuration))
                self.badgeInfo.text = "  \(SavedData.kasamDict[kasamID]!.repeatDuration) day trophy  "
                if ratio.isNaN {ratio = 0}
                self.badgeCompletion.text = "\(Int(ratio * 100))%"
                headerBadgeIcon.animation = Animations.kasamBadges[1]
            } else {
                //OPTION 2 - Kasam ongoing currently
                if SavedData.kasamDict[kasamID]?.sequence == "streak" {
                    daysCompleted = Double(SavedData.kasamDict[kasamID]?.streakInfo.currentStreak.value ?? 0)
                }
                ratio = (daysCompleted / Double(SavedData.kasamDict[kasamID]!.repeatDuration))
                self.badgeInfo.text = "  \(SavedData.kasamDict[kasamID]!.repeatDuration) day trophy  "
                self.badgeCompletion.text = "\(Int(ratio * 100))%"
                headerBadgeIcon.animation = Animations.kasamBadges[1]
                if setupCheck == true {
                    self.kasamBadgeHolder.isHidden = false
                    self.headerBadgeIcon.play()
                }
            }
        } else if SavedData.kasamDict[kasamID]!.repeatDuration == 0 {
            ratio = 1
            self.badgeCompletion.isHidden = true
            headerBadgeMask.isHidden = true
            self.badgeInfo.isHidden = true
        } else {
            //Not following or previously completed Kasam, so don't show any header badge
            self.kasamBadgeHolder.isHidden = true
            finishHolder.isHidden = true
            extendHolder.isHidden = true
            self.headerImageView.alpha = 1.0
        }
        let ratioAdjust = 0.95 - ratio
        gradientLayer.locations = [NSNumber(value: 0.15), NSNumber(value: ratioAdjust), NSNumber(value: ratioAdjust), NSNumber(value: 1.0)]
    }
    
    func badgesAchieved(){
        //Highlights trophies completed
        if SavedData.kasamDict[kasamID]?.badgeList != nil {
            if SavedData.kasamDict[kasamID]!.badgeList!.count == 1 {
                self.trophyIcon.setIcon(icon: .fontAwesomeSolid(.trophy), iconSize: 18, color: .white, backgroundColor: .darkGray, forState: .normal)
                noTrophiesAchieved.text = "\(String(describing: SavedData.kasamDict[kasamID]!.badgeList!.count)) trophy"
            } else {
                self.trophyIcon.setIcon(icon: .fontAwesomeSolid(.trophy), iconSize: 18, color: .white, backgroundColor: .darkGray, forState: .normal)
                noTrophiesAchieved.text = "\(String(describing: SavedData.kasamDict[kasamID]!.badgeList!.count)) trophies"
            }
        } else {
            self.trophyIcon.setIcon(icon: .fontAwesomeSolid(.trophy), iconSize: 18, color: .white, backgroundColor: .lightGray, forState: .normal)
        }
    }
    
    @IBAction func finishButtonPressed(_ sender: Any) {
        finishKasamPress(kasamID: kasamID, completion: {(success) -> Void in})
    }
    
    @IBAction func extendButtonPressed(_ sender: Any) {
        addButtonPress(reset:false)
    }
    
    //BUTTON PRESSES----------------------------------------------------------------------
    
    @IBAction func coachNamePress(_ sender: Any) {
        if reviewOnly == false {
            self.performSegue(withIdentifier: "goToCoach", sender: self)
        }
    }
    
    @IBAction func previewButtonPressed(_ sender: Any) {
        do {
           try AVAudioSession.sharedInstance().setCategory(.playback)
        } catch(let error) {
            print(error.localizedDescription)
        }
        playerView.load(withVideoId: previewLink)
        playerView.isHidden = false
        animationView.loadingAnimation(view: view, animation: "fireworks-loading", height: 200, overlayView: nil, loop: true, completion: nil)
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
            } else if reviewOnly == true {
                kasamActivityHolder.reviewOnly = true
                kasamActivityHolder.blockID = blockIDGlobal     //this is the block No that gets transferred
            }
        } else if segue.identifier == "goToEditKasam" {
            let transferHolder = segue.destination as! NewKasamPageController
            transferHolder.kasamHolderKasamEdit = true
            NewKasam.editKasamCheck = true
            NewKasam.kasamID = kasamID
        }
    }
    
    //Twitter Parallax-------------------------------------------------------------------------------------------------------------------
    
    //CHANGE THIS VALUE TO MODIFY THE HEADER
    let headerHeight = UIScreen.main.bounds.height - (518 * (UIScreen.main.bounds.width / 375))
    
    func setupTwitterParallax(){
        constraintHeightHeaerImages.constant = headerHeight
        headerView.layoutIfNeeded()
        tableView.contentInset = UIEdgeInsets(top: headerView.frame.height, left: 0, bottom: 0, right: 0)
        headerBlurImageView = twitterParallaxHeaderSetup(headerBlurImageView: headerBlurImageView, headerImageView: headerImageView, headerView: headerView, headerLabel: headerLabel)
        kasamBadgeHolder.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: kasamBadgeHolder, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: profileViewRadius, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: -40).isActive = true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        kasamBadgeHeight.constant = headerView.frame.height - 50
        let offsetHeaderStop:CGFloat = headerHeight - 100         //Thickness of navbar that appears when you scroll up
        let offsetLabelHeader:CGFloat = 60.0                      //Distance from top of screen that the headerlabel shows up at
        twitterParallaxScrollDelegate(scrollView: scrollView, headerHeight: headerHeight, headerView: headerView, headerBlurImageView: headerBlurImageView, headerLabel: headerLabel, offsetHeaderStop: offsetHeaderStop, offsetLabelHeader: offsetLabelHeader, shrinkingButton: addButtonText, shrinkingButton2: addButton, mainTitle: kasamTitle)
    }
    
    //-----------------------------------------------------------------------------------------------------------------------------------
    
    //Retrieves Kasam Data using Kasam ID selected
    func getKasamData(){
        var kasamDB = DatabaseReference()
        if userKasam == true {
            kasamDB = DBRef.userKasams.child(kasamID)
        } else {
            kasamDB = DBRef.coachKasams.child(kasamID)
        }
        kasamDB.observe(.value, with: {(snapshot) in
            if let value = snapshot.value as? [String: Any] {
                self.kasamGTitle = value["Title"] as? String ?? ""
                self.headerLabel.text! = self.kasamGTitle
                self.kasamTitle.text! = self.kasamGTitle
                self.kasamDescription.text! = value["Description"] as? String ?? ""
                self.coachName.setTitle(value["CreatorName"] as? String ?? "", for: .normal)  //in the future, get this from the userdatabase, so it's the most uptodate name
                self.coachIDGlobal = value["CreatorID"] as! String
                if self.coachIDGlobal == Auth.auth().currentUser?.uid {
                    self.editKasamButton.layer.cornerRadius = self.editKasamButton.frame.height / 2
                    self.editKasamButton.fadeIn()
                }
                self.kasamGenre.text! = value["Genre"] as? String ?? ""
                self.kasamLevel.text! = Assets.levelsArray[value["Level"] as? Int ?? 1]
                self.benefitsArray = (value["Benefits"] as? String ?? "").components(separatedBy: ";")
                self.kasamMetric = value["Metric"] as? String ?? "Checkmark"
                self.chosenRepeat = (value["Duration"] as? Int ?? 30)
                if self.kasamMetric == "Checkmark" {self.tableView.allowsSelection = false; self.tableView.reloadData()}
                if let duration = value["Duration"] as? Int {self.timelineDuration = duration}
                
                //Set icons
                self.TypeIcon = self.TypeIcon.setKasamTypeIcon(kasamType: self.kasamGenre.text!, button: self.TypeIcon, location: "kasamHolder")
                self.kasamLevelIcon = self.kasamLevelIcon.setKasamTypeIcon(kasamType: self.kasamLevel.text!, button: self.kasamLevelIcon, location: "kasamHolder")
        
                let headerURL = URL(string: value["Image"] as? String ?? "")
                self.previewLink = value["Preview"] as? String ?? ""
                if self.previewLink != "" {self.previewButton.isHidden = false}
                self.headerImageView?.sd_setImage(with: headerURL, placeholderImage: PlaceHolders.kasamHeaderPlaceholderImage)
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    self.setupKasamBadge()
                }
            }
        })
    }
    
    //Retrieves Blocks based on Kasam selected
    func getBlocksData() {
        DBRef.coachKasams.child(kasamID).child("Blocks").observeSingleEvent(of: .value, with:{(snap) in
            if snap.childrenCount > 1 {self.singleBlock = false}
            var dayNumber = 1
            DBRef.coachKasams.child(self.kasamID).child("Blocks").observe(.childAdded, with: {(snapshot) in
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
        })
    }
    
//REGISTER TO KASAM-------------------------------------------------------------------------------------------------
    
    //Add Kasam to Following List of user
    @IBAction func addButtonPress(_ sender: Any) {
        addButtonPress(reset: false)
    }
    
    func addButtonPress(reset: Bool){
        //OPENS THE POPUP TO ENTER PREFERENCES
        if registerCheck == 0 || reset == true {
            //Adding new Kasam
            addKasamPopup(kasamID: kasamID, percentComplete: ratio, new: true, timelineDuration: timelineDuration, duration: chosenRepeat, fullView: true)
        } else {
            //Existing Kasam prefernces being updated
            addKasamPopup(kasamID: kasamID, percentComplete: ratio, new: false, timelineDuration: timelineDuration, duration: chosenRepeat, fullView: true)
        }
        //If the user presses save:
        saveTimeObserver = NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "SaveTime\(kasamID)"), object: nil, queue: OperationQueue.main) {(notification) in
            let timeVC = notification.object as! AddKasamController
            self.chosenTime = timeVC.formattedTime
            self.chosenTimeHour = timeVC.hourAMPM
            self.chosenTimeMin = timeVC.min
            self.startDate = timeVC.formattedDate
            self.chosenRepeat = timeVC.repeatDuration
            self.notificationCheck = timeVC.notificationCheck
            
            if self.registerCheck == 0 {
                self.registerUserToKasam()                          //only gets executed once user presses save
            } else {
                self.addUserPreferncestoKasam(restart: reset)         //updating kasam that user is already following
                //manually change values below so if the user opens this window again, the values are updated. Can't rely on the todaykasamreload, since it takes too long and if the user opens this window earlier, it'll show old values
                SavedData.kasamDict[self.kasamID]?.repeatDuration = self.chosenRepeat
                SavedData.kasamDict[self.kasamID]?.startTime = self.chosenTime
            }
            NotificationCenter.default.removeObserver(self.saveTimeObserver as Any)
            NotificationCenter.default.removeObserver(self.unfollowObserver as Any)
        }
        //If the user presses unfollow:
        unfollowObserver = NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "UnfollowKasam\(kasamID)"), object: nil, queue: OperationQueue.main) {(notification) in
            showPopupConfirmation(title: "You sure?", description: "Your past progress will be saved.", image: UIImage.init(icon: .fontAwesomeSolid(.heartbeat), size: CGSize(width: 35, height: 35), textColor: .white), buttonText: "Unfollow") {(success) in
                SavedData.kasamDict[self.kasamID] = nil
                self.unregisterUseFromKasam()
            }
            NotificationCenter.default.removeObserver(self.unfollowObserver as Any)
            NotificationCenter.default.removeObserver(self.saveTimeObserver as Any)
        }
    }
    
    func registerUserToKasam() {
        var endDate: Date?
        let startDateConverted = startDate.stringToDate()
        if self.chosenRepeat != 0 {
            endDate = Calendar.current.date(byAdding: .day, value: self.chosenRepeat, to: startDateConverted)!
        }
        if notificationCheck == true {
            kasamID.setupNotifications(kasamName: kasamGTitle, startDate: startDateConverted, endDate: endDate, chosenTime: self.chosenTime)
        }
        
        //STEP 1: Adds the user to the Kasam-following list
        DBRef.coachKasams.child(kasamID).child("Followers").updateChildValues([(Auth.auth().currentUser?.uid)!: (Auth.auth().currentUser?.displayName)!])
        
        //STEP 2: Adds the user to the Coach-following list
        DBRef.userCreator.child(coachIDGlobal).child("Followers").updateChildValues([(Auth.auth().currentUser?.uid)!: (Auth.auth().currentUser?.displayName)!])
        countFollowers()
                
        //STEP 3: Adds the user preferences to the Kasam they just followed
        self.addUserPreferncestoKasam(restart: false)
    }
    
    func unregisterUseFromKasam() {
        self.registerCheck = 0
        self.initialRepeat = nil    //set to nil so that all kasams will be reloaded when user re-follows kasam (look at if function in above function)
        
        //Removes the user from the Kasam following
        DBRef.coachKasams.child(kasamID).child("Followers").child((Auth.auth().currentUser?.uid)!).setValue(nil)
        
        //Removes the user from the Coach following
        DBRef.userCreator.child(coachIDGlobal).child("Followers").child((Auth.auth().currentUser?.uid)!).setValue(nil)
        
        //Remove notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [kasamID])
        
        //Removes the kasam from the user's following list
        DBRef.userKasamFollowing.child(kasamID).child("Status").setValue("inactive") {(error, reference) in
            Analytics.logEvent("unfollowing_Kasam", parameters: ["kasam_name":self.kasamTitle.text ?? "Kasam Name"])
            NotificationCenter.default.post(name: Notification.Name(rawValue: "ResetTodayKasam"), object: self)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "ProfileUpdate"), object: self)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "KasamStatsUpdate"), object: self)
        }
    }
    
        
    func addUserPreferncestoKasam(restart: Bool){
        DBRef.userKasamFollowing.child(self.kasamID).updateChildValues(["Kasam Name" : self.kasamTitle.text!, "Date Joined": self.startDate, "Repeat": self.chosenRepeat, "Time": self.chosenTime, "Metric": kasamMetric, "Status": "active", "Duration": timelineDuration as Any]) {(error, reference) in
          Analytics.logEvent("following_Kasam", parameters: ["kasam_name":self.kasamTitle.text ?? "Kasam Name"])
            //OPTION 1 - Add new kasam to the today page
            if self.initialRepeat == nil {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "AddKasamToday"), object: self, userInfo: ["kasamID": self.kasamID])
            //OPTION 2 - Switching from FUN kasam to Tracked kasam
            } else if self.initialRepeat == 0 && self.chosenRepeat > 0 {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "ResetTodayKasam"), object: self)
            //OPTION 3 - Switching from Tracked kasam to FUN Kasam
            } else if self.initialRepeat! > 0 && self.chosenRepeat == 0 {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "ResetTodayKasam"), object: self)
            //OPTION 4 - Updating existing kasam, keeping FUN and Tracked status same
            } else {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "ResetTodayKasam"), object: self, userInfo: ["kasamID": self.kasamID])
                if restart == true {
                    DBRef.userKasamFollowing.child(self.kasamID).child("Past Join Dates").child(( SavedData.kasamDict[self.kasamID]!.joinedDate).dateToString()).setValue(SavedData.kasamDict[self.kasamID]?.repeatDuration)
                }
            }
            NotificationCenter.default.post(name: Notification.Name(rawValue: "ProfileUpdate"), object: self)
        }
    }
    
    func countFollowers(){
        var count = 0
        DBRef.coachKasams.child(kasamID).child("Followers").observe(.childAdded) {(snapshot) in
            count += 1
            self.followersNo.text = count.pluralUnit(unit: "Follower")
        }
    }
    
    func registeredCheck(){
        self.addButton.setImage(UIImage(named:"kasam-add"), for: .normal)
        DBRef.userKasamFollowing.child(kasamID).child("Status").observeSingleEvent(of: .value, with:{(snap) in
            let kasamStatus = snap.value as? String
            if kasamStatus == "completed" || kasamStatus == "inactive" {
                //OPTION 1 - User compeleted kasam in past, and may now want to rejoin
                self.registerCheck = 0
                self.addButtonText.setIcon(icon: .fontAwesomeSolid(.plus), iconSize: 25, color: .white, backgroundColor: .clear, forState: .normal)
            } else if kasamStatus == "active" {
                //OPTION 2 - User registered to kasam (GEAR ICON)
                self.registerCheck = 1
                self.initialRepeat = SavedData.kasamDict[self.kasamID]?.repeatDuration
                self.addButtonText.setIcon(icon: .fontAwesomeSolid(.cog), iconSize: 25, color: .white, backgroundColor: .clear, forState: .normal)
            } else if kasamStatus == nil {
                //OPTION 3 - User not registered to kasam (PLUS ICON)
                self.registerCheck = 0
                self.addButtonText.setIcon(icon: .fontAwesomeSolid(.plus), iconSize: 25, color: .white, backgroundColor: .clear, forState: .normal)
            }
        })
    }
    
    @IBAction func editKasamButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "goToEditKasam", sender: nil)
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
        kasamGenre.text = "Personal"
        kasamLevel.text = "Beginner"
        var blockImage = UIImage()
        if NewKasam.kasamImageToSave != UIImage() && NewKasam.loadedInKasamImage == UIImage() {
        //CASE 1 - creating a new Kasam, and image added
            headerImageView.image = NewKasam.kasamImageToSave
            blockImage = NewKasam.kasamImageToSave
        } else if NewKasam.kasamImageToSave == UIImage() && NewKasam.loadedInKasamImage == UIImage() {
        //CASE 2 - creating new kasam, and hasn't uploaded an image
            headerImageView.image = PlaceHolders.kasamHeaderPlaceholderImage
            blockImage = PlaceHolders.kasamHeaderPlaceholderImage
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
                    self.animationView.loadingAnimation(view: self.view, animation: "rocket-fast", height: 200, overlayView: self.animationOverlay, loop: true, completion: nil)
                    self.createKasam(existingKasamID: nil, basicKasam: false) {(success) in
                        if success == true {
                            self.animationView.removeFromSuperview()
                            self.animationOverlay.removeFromSuperview()
                        }
                    }
                } else {
                    //updating an existing kasam
                    self.animationView.loadingAnimation(view: self.view, animation: "rocket-fast", height: 200, overlayView: self.animationOverlay, loop: true, completion: nil)
                    self.createKasam(existingKasamID: NewKasam.kasamID, basicKasam: false) {(success) in
                        if success == true {
                            self.animationView.removeFromSuperview()
                            self.animationOverlay.removeFromSuperview()
                        }
                    }
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
        deleteUserKasam {(success) in
            self.navigationController?.popViewController(animated: true)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "ShowCompletionAnimation"), object: self)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "GetUserKasams"), object: self)
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
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.backgroundColor = UIColor.white.withAlphaComponent(0)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()         //remove bottom border on navigation bar
        self.navigationController?.navigationBar.tintColor = UIColor.white       //makes the back button white
        for subview in self.navigationController!.navigationBar.subviews {
            if subview.restorationIdentifier == "rightButton" {subview.isHidden = true}
        }
        if reviewOnly == true {
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
            self.navigationController?.navigationBar.shadowImage = UIImage()
            self.navigationController?.navigationBar.isTranslucent = true
            self.navigationController?.navigationBar.backgroundColor = UIColor.clear            //set navigation bar color to clear
        } else {
            self.navigationItem.backBarButtonItem?.title = ""
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.navigationBar.isTranslucent = false
        for subview in self.navigationController!.navigationBar.subviews {
            if subview.restorationIdentifier == "rightButton" {subview.isHidden = false}
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if reviewOnly == true {
            setupReviewOnly()
            self.navigationController?.navigationBar.tintColor = UIColor.white                  //change back arrow color to white
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self.unfollowObserver as Any)
        NotificationCenter.default.removeObserver(self.saveTimeObserver as Any)
        NotificationCenter.default.removeObserver(self.refreshBadge as Any)
    }
}

//------------------------------------------------------------------------------------------------------------

extension KasamHolder: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if kasamMetric == "Checkmark" {
            return 1
        } else {
            return kasamBlocks.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "KasamBlock") as! BlocksCell
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        if kasamMetric == "Checkmark" {
            cell.benefitsArray = benefitsArray
            cell.setBasicKasamBenefits()
        } else {
            let block = kasamBlocks[indexPath.row]
            if singleBlock == true {
                cell.benefitsArray = benefitsArray
                cell.setBlock(block: block, single: true)
            } else {
                cell.setBlock(block: block, single: false)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if kasamMetric == "Checkmark" {
            //do nothing
        } else {
            blockIDGlobal = kasamBlocks[indexPath.row].blockID
            performSegue(withIdentifier: "goToKasamActivityViewer", sender: indexPath)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
       if singleBlock == true {
            return 180      //for one block, set twice the height
        } else {
            return 90
        }
    }
}

extension KasamHolder: YTPlayerViewDelegate {
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        self.playerView.playVideo()
        animationView.removeFromSuperview()
        self.view.isUserInteractionEnabled = true
    }
}
