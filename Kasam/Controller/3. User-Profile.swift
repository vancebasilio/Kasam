//
//  ProfileViewController.swift
//  Kasam 1.0
//
//  Created by Vance Basilio on 2019-04-22.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Firebase
import Parchment
import FBSDKLoginKit
import SwiftEntryKit
import SkeletonView
import GoogleSignIn
import Lottie

class ProfileViewController: UIViewController {
   
    @IBOutlet weak var userFirstName: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var profileImageClickArea: UIView!
    @IBOutlet weak var kasamFollowingNo: UILabel!
    @IBOutlet weak var badgeNo: UILabel!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var levelLine: UIView!
    @IBOutlet weak var levelLineProgress: NSLayoutConstraint!
    @IBOutlet weak var levelLineBack: UIView!
    @IBOutlet weak var startLevel: UILabel!
    @IBOutlet weak var totalDays: UILabel!
    @IBOutlet weak var weekStatsCollectionView: UICollectionView!
    @IBOutlet weak var detailedStatsCollectionView: UICollectionView!
    @IBOutlet weak var detailedStatsCollectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var kasamStatsHeight: NSLayoutConstraint!
    @IBOutlet weak var topViewHeight: NSLayoutConstraint!
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var contentView: NSLayoutConstraint!
    @IBOutlet weak var sideMenuButton: UIButton!
    
    @IBOutlet weak var completedKasamsTable: SelfSizedTableView!
    @IBOutlet weak var completedKasamTableHeight: NSLayoutConstraint!
    @IBOutlet weak var completedLabel: UILabel!
    
    @IBOutlet weak var editKasamLabel: UILabel!
    @IBOutlet weak var editKasamsCollectionView: UICollectionView!
    @IBOutlet weak var editKasamsHeight: NSLayoutConstraint!
    
    var weeklyStats: [weekStatsFormat] = []
    var detailedStats: [UserStatsFormat] = []
    var myKasamsArray: [EditMyKasamFormat] = []
    var completedStats: [UserStatsFormat] = []
    var daysCompletedDict: [String:Int] = [:]
    var dayDictionary = [Int:String]()
    var metricDictionary = [Int:Double]()
    let animationView = AnimationView()
    var userKasamDBHandle: DatabaseHandle!
    var saveStorageRef = Storage.storage().reference()
    
    //Kasam Following
    var kasamIDGlobal: String = ""
    var kasamTitleGlobal: String = ""
    var kasamMetricTypeGlobal: String = ""
    var kasamImageGlobal: URL!
    var joinedDateGlobal: Date?
    var kasamHistoryRefHandle: DatabaseHandle!
    var kasamUserRefHandle: DatabaseHandle!
    var kasamUserFollowRefHandle: DatabaseHandle!
    
    var tableViewHeight = CGFloat(0)
    var noUserKasams = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        profileSetup()
        profileUpdate()
        profilePicture()
        setupDateDictionary()
        getDetailedStats()
        getMyKasams()
        viewSetup()
        setupImageHolders()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //hides the nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidLayoutSubviews(){
    //Table Resizing
        completedKasamsTable.frame = CGRect(x: completedKasamsTable.frame.origin.x, y: completedKasamsTable.frame.origin.y, width: completedKasamsTable.frame.size.width, height: completedKasamsTable.contentSize.height)
        self.completedKasamTableHeight.constant = self.completedKasamsTable.contentSize.height
        completedKasamsTable.reloadData()
        let frame = self.view.safeAreaLayoutGuide.layoutFrame
        
    //STEP 1 - Titles
        var titleHeights = 52.5 * 3
        if editKasamsHeight.constant == 0 {
            titleHeights = 52.5 * 2
            editKasamsHeight.constant = 0
        }
    //STEP 2 - CollectionViews
        collectionViewHeight.constant = detailedStatsCollectionViewHeight.constant + kasamStatsHeight.constant + editKasamsHeight.constant + CGFloat(titleHeights)
    //STEP 3 - TableView
        if completedStats.count > 0 {
            tableViewHeight = completedKasamTableHeight.constant + 42.5                //42.5 is the completed label height
        }
        let contentViewHeight = topViewHeight.constant + collectionViewHeight.constant + tableViewHeight
        if contentViewHeight > frame.height {
            contentView.constant = contentViewHeight
        } else if contentViewHeight <= frame.height {
            let diff = frame.height - contentViewHeight
            contentView.constant = contentViewHeight + diff + 1
        }
    }
    
    func viewSetup(){
        profileImage.showAnimatedSkeleton()
        levelLineBack.layer.cornerRadius = 4
        levelLineBack.clipsToBounds = true
        levelLine.layer.cornerRadius = 4
        levelLine.clipsToBounds = true
        sideMenuButton.setIcon(icon: .fontAwesomeSolid(.bars), iconSize: 20, color: UIColor.darkGray, backgroundColor: .clear, forState: .normal)
        self.navigationItem.title = ""
        navigationController?.navigationBar.barTintColor = UIColor.init(red: 249, green: 249, blue: 249)
        
        let notificationName = NSNotification.Name("ProfileUpdate")
        NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.profileUpdate), name: notificationName, object: nil)
        
        let kasamStatsUpdate = NSNotification.Name("KasamStatsUpdate")
        NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.getDetailedStats), name: kasamStatsUpdate, object: nil)
        
        let goToCreateKasam = NSNotification.Name("GoToCreateKasam")
        NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.goToCreateKasam), name: goToCreateKasam, object: nil)
        
        let showCompletionAnimation = NSNotification.Name("ShowCompletionAnimation")
               NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.showCompletionAnimation), name: showCompletionAnimation, object: nil)
    }
    
    @IBAction func showUserOptionsButton(_ sender: Any) {
        showUserOptions(viewHeight: view.frame.height)
    }
    
    @objc func goToCreateKasam() {
        NewKasam.resetKasam()
        performSegue(withIdentifier: "goToCreateKasam", sender: nil)
    }
    
    @objc func showCompletionAnimation(){
        getMyKasams()
        loadingAnimation(animationView: animationView, animation: "checkmark", height: 400, overlayView: nil, loop: false){
            self.animationView.removeFromSuperview()
        }
    }
    
    //GET ALL THE STATS-------------------------------------------------------------------------------------------------
    
    //STEP 1
    @objc func getDetailedStats() {
        detailedStats.removeAll()
        completedStats.removeAll()
        //loops through all kasams that user is following and get kasamID
        for kasam in SavedData.kasamArray {
            Database.database().reference().child("Coach-Kasams").child(kasam.kasamID).observeSingleEvent(of: .value) {(snap) in
                if snap.exists() {
                let snapshot = snap.value as! Dictionary<String,Any>
                let imageURL = URL(string:snapshot["Image"]! as! String)        //getting the image and saving it to SavedData
                kasam.image = snapshot["Image"]! as! String
                kasam.metricType = snapshot["Metric"]! as! String               //getting the metricType and saving it to SavedData
                let userStats = UserStatsFormat(kasamID: kasam.kasamID, kasamTitle: kasam.kasamName, imageURL: imageURL ?? URL(string:PlaceHolders.kasamLoadingImageURL)!, joinedDate: kasam.joinedDate, endDate: kasam.endDate, metricType: kasam.metricType, order: kasam.kasamOrder)
                if kasam.currentStatus == "completed" {
                    //if the kasam has been completed, and not rejoined
                    self.completedStats.append(userStats)
                    self.completedKasamsTable.reloadData()
                } else {
                    self.detailedStats.append(userStats)
                    self.detailedStats = self.detailedStats.sorted(by: { $0.order < $1.order })     //orders the array as kasams with no history will always show up first, even though they were loaded later
                    self.detailedStatsCollectionView.reloadData()
                    self.weekStatsCollectionView.reloadData()
                }
                  
                //get past joined dates (if kasam was completed and rejoined)
                if kasam.pastKasamJoinDates.count != 0 {
                    for pastJoinDate in kasam.pastKasamJoinDates {
                        let pastDateJoined = self.stringToDate(date: pastJoinDate)
                        let pastEndDate = Calendar.current.date(byAdding: .day, value: 30, to: pastDateJoined)!
                        let userStats = UserStatsFormat(kasamID: kasam.kasamID, kasamTitle: kasam.kasamName, imageURL: imageURL ?? URL(string:PlaceHolders.kasamLoadingImageURL)!, joinedDate: pastDateJoined, endDate: pastEndDate, metricType: kasam.metricType, order: kasam.kasamOrder)
                        self.completedStats.append(userStats)
                        self.completedKasamsTable.reloadData()
                    }
                }
                
                if self.detailedStats.count == SavedData.kasamArray.count {
                    self.getWeeklyStats()
                }
            
            //Kasam Level
            self.startLevel.setIcon(prefixText: "", icon: .fontAwesomeSolid(.grin), postfixText: " Beginner", size: 15)
                self.kasamHistoryRefHandle = DBRef.userHistory.child(kasam.kasamID).observe(.childAdded, with:{(snapshot) in
                self.daysCompletedDict[snapshot.key] = 1
                let total = self.daysCompletedDict.count
                if total == 1 {
                     self.totalDays.text = "\(String(total)) Kasam Day"
                } else {
                    self.totalDays.text = "\(String(total)) Kasam Days"
                }
                if total <= 30 {
                    self.levelLineProgress.constant = self.levelLineBack.frame.size.width * CGFloat(Double(total) / 30.0)
                } else if total > 30 && total <= 90 {
                    self.startLevel.setIcon(prefixText: "", icon: .fontAwesomeSolid(.laugh), postfixText: " Hard", size: 15)
                    self.levelLineProgress.constant = self.levelLineBack.frame.size.width * CGFloat(Double(total) / 90.0)
                }
            })
            }
        }
        }
    }
    
    //STEP 2
    func getWeeklyStats() {
        weeklyStats.removeAll()
        metricDictionary.removeAll()
        for kasam in SavedData.kasamTodayArray {
            let daysPast = (Calendar.current.dateComponents([.day], from: kasam.joinedDate, to: Date()).day!) + 1
            var metricCount = 0
            var metricMatrix = 0
            var checkerCount = 0
            let imageURL = URL(string:kasam.image)
            for x in 1...7 {
                var avgMetric = 0
                DBRef.userHistory.child(kasam.kasamID).child(self.dayDictionary[x]!).observe(.value, with:{(snapshot) in
                    checkerCount += 1
                    self.metricDictionary[x] = 0                                      //to set the base as zero for each day
                    
                    //only records progress bar if the joined date is after the kasam date
                    if self.stringToDate(date: self.dayDictionary[x]!) >= kasam.joinedDate {
                        if let value = snapshot.value as? Int {
                            self.metricDictionary[x] = Double(value)                        //Basic Kasam
                            metricMatrix += 1
                            metricCount += 1
                        }
                        else if let value = snapshot.value as? [String: Any] {
                            self.metricDictionary[x] = value["Metric Percent"] as? Double   //Challange Kasam: Get metric for each day
                            metricMatrix += Int(value["Total Metric"] as? Double ?? 0.0)
                            metricCount += 1
                        }
                    }
                    if checkerCount == 7 && metricCount != 0 {
                        if kasam.metricType == "Checkmark" {
                            let daysPast = (Date().dayNumberOfWeek() ?? 7)   //divide 100% checkmark days by no of days in the week completed
                            if daysPast != 0 {
                                avgMetric = Int((Double(metricMatrix) / Double(daysPast)) * 100)          //for Basic Kasams
                            }
                            
                        } else {
                            avgMetric = (metricMatrix / metricCount)             //for Complex Kasams
                        }
                        self.weeklyStats.append(weekStatsFormat(kasamID: kasam.kasamID, kasamTitle: kasam.kasamName, imageURL: imageURL ?? URL(string:PlaceHolders.kasamLoadingImageURL)!, daysLeft: daysPast, metricType: kasam.metricType, metricDictionary: self.metricDictionary, avgMetric: avgMetric, order: kasam.kasamOrder))
                        
                        //orders the array as kasams with no history will always show up first, even though they were loaded later
                        self.weeklyStats = self.weeklyStats.sorted(by: { $0.order < $1.order })
                        self.weekStatsCollectionView.reloadData()
                    }
                })
            }
        }
    }
    
    @objc func getMyKasams(){
        myKasamsArray.removeAll()
        DBRef.userKasams.observeSingleEvent(of: .value, with:{(snap) in
            let count = Int(snap.childrenCount)
            if count == 0 {
                //not following any kasams
                self.noUserKasams = true
                self.editKasamsHeight.constant = 0
            } else {
                let cellWidth = ((self.view.frame.size.width - (15 * 4)) / 3)
                self.editKasamsHeight.constant = cellWidth + 40
            }
            self.userKasamDBHandle = DBRef.userKasams.observe(.childAdded, with: {(snapshot) in
                Database.database().reference().child("Coach-Kasams").child(snapshot.key).observe(.value, with: {(snapshot) in
                    if let value = snapshot.value as? [String: Any] {
                        let imageURL = URL(string: value["Image"] as? String ?? "")
                        let myKasamsBlock = EditMyKasamFormat(kasamID: value["KasamID"] as? String ?? "", kasamTitle: value["Title"] as? String ?? "", imageURL: imageURL ?? URL(string:PlaceHolders.kasamLoadingImageURL)!)
                        self.myKasamsArray.append(myKasamsBlock)
                        self.editKasamsCollectionView.reloadData()
                        self.editKasamLabel.isHidden = false
                        self.editKasamsCollectionView.isHidden = false
                        self.viewDidLayoutSubviews()
                    }
                    //remove observer
                    Database.database().reference().child("Coach-Kasams").child(snapshot.key).removeAllObservers()
                })
            })
        })
    }
    
    func setupDateDictionary(){
        let todayDay = Date().dayNumberOfWeek()
        if todayDay == 1 {
            for x in 1...7 {
                self.dayDictionary[x] = self.dateFormat(date: Calendar.current.date(byAdding: .day, value: x - 7, to: Date())!)
            }
        } else {
            for x in 1...7 {
                self.dayDictionary[x] = self.dateFormat(date: Calendar.current.date(byAdding: .day, value: x - (todayDay! - 1), to: Date())!)
            }
        }
    }
    
    //PROFILE SETUP-------------------------------------------------------------------------------------------------
    
    func profileSetup(){
        self.profileImage.layer.cornerRadius = self.profileImage.frame.width / 2
        self.profileImage.clipsToBounds = true
        let userName = Auth.auth().currentUser?.displayName
        userFirstName.text = userName
        if let truncUserFirst = Auth.auth().currentUser?.displayName?.split(separator: " ").first.map(String.init), let truncUserLast = Auth.auth().currentUser?.displayName?.split(separator: " ").last.map(String.init) {
            userFirstName.text = truncUserFirst + " " + truncUserLast
        }
    }
    
    @objc func profileUpdate() {
        var kasamcount = 0
        var followingcount: [String: String] = [:]
        kasamFollowingNo.text = String(kasamcount)
            self.kasamUserFollowRefHandle = DBRef.userKasamFollowing.observe(.childAdded) {(snapshot) in
                kasamcount += 1
                followingcount = [snapshot.key: "1"]            //this shows no of coaches the user is following
                self.kasamFollowingNo.text = String(kasamcount)
        }
    }
    
    func profilePicture() {
        if let user = Auth.auth().currentUser {
            let storageRef = Storage.storage().reference(forURL: "gs://kasam-coach.appspot.com")
            //check if user has manually set a profile image
            DBRef.currentUser.child("ProfilePic").observeSingleEvent(of: .value, with:{(snap) in
                if snap.exists() {
                    //get the manually set Image
                    let profilePicRef = storageRef.child("users/"+user.uid+"/manual_profile_pic.jpg")
                    self.setProfileImage(profilePicRef: profilePicRef)
                } else {
                    //get the Facebook or Google Image
                    let profilePicRef = storageRef.child("users/"+user.uid+"/profile_pic.jpg")
                    self.setProfileImage(profilePicRef: profilePicRef)
                }
            })
        }
    }
    
    func setProfileImage(profilePicRef: StorageReference){
        //Check if the image is stored in Firebase
        profilePicRef.downloadURL {(url, error) in
            if url != nil {
                //Get the image from Firebase
                self.profileImage?.sd_setImage(with: url, placeholderImage: PlaceHolders.kasamLoadingImage, options: [], completed: { (image, error, cache, url) in
                    self.profileImage.hideSkeleton()
                })
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToStats" {
            let segueTransferHolder = segue.destination as! StatisticsViewController
            segueTransferHolder.kasamID = kasamIDGlobal
            segueTransferHolder.kasamName = kasamTitleGlobal
            segueTransferHolder.kasamMetricType = kasamMetricTypeGlobal
            segueTransferHolder.kasamImage = kasamImageGlobal
            segueTransferHolder.joinedDate = joinedDateGlobal
        } else if segue.identifier == "goToEditKasam" {
            NewKasam.editKasamCheck = true
            NewKasam.kasamID = kasamIDGlobal
            NewKasam.kasamName = kasamTitleGlobal
        }
    }
    
    //Stops the observer
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if kasamUserRefHandle != nil {
            DBRef.currentUser.removeObserver(withHandle: self.kasamUserRefHandle!)
        }
        if kasamHistoryRefHandle != nil {
            DBRef.userHistory.removeObserver(withHandle: self.kasamHistoryRefHandle)
        }
    }
}

extension ProfileViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == weekStatsCollectionView {
            if detailedStats.count == 0 {
                return 1                                                     //user not following any kasams
            } else if detailedStats.count != 0 && weeklyStats.count == 0 {
                return detailedStats.count                                   //user following kasams that aren't active yet
            } else {
                return weeklyStats.count                                     //user following active kasams
            }
        } else if collectionView == editKasamsCollectionView {
            return myKasamsArray.count
        } else {
            if detailedStats.count == 0 {
                return 1
            } else {
                return detailedStats.count
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == weekStatsCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "KasamStatsCell", for: indexPath) as! WeeklyStatsCell
            cell.height = kasamStatsHeight.constant
            if detailedStats.count == 0 {
                cell.setPlaceholder()                                                     //user not following any kasams
            } else if detailedStats.count != 0 && weeklyStats.count == 0 {
                let blankStat = detailedStats[indexPath.row]
                cell.setBlankBlock(cell: blankStat)                                       //user following kasams that aren't active yet
            } else {
                let stat = weeklyStats[indexPath.row]
                cell.setBlock(cell: stat)                                                 //user following active kasams
            }
            return cell
        } else if collectionView == editKasamsCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EditKasamCell", for: indexPath) as! KasamFollowingCell
            let block = myKasamsArray[indexPath.row]
            cell.setMyKasamBlock(cell: block)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "KasamStatsCell", for: indexPath) as! KasamFollowingCell
            if detailedStats.count == 0 {
                cell.setPlaceholder()
            } else {
                let kasam = detailedStats[indexPath.row]
                cell.setBlock(cell: kasam)
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == weekStatsCollectionView {
            kasamStatsHeight.constant = (view.bounds.size.width * (2/5))
            return CGSize(width: (view.frame.size.width - 30), height: view.frame.size.width * (2/5))
        } else if collectionView == editKasamsCollectionView {
            //for edit kasams -- which has a longer width
            let cellWidth = ((view.frame.size.width - (15 * 4)) / 3)
            editKasamsHeight.constant = cellWidth + 40
            return CGSize(width: cellWidth, height: cellWidth + 40)
        } else {
            //for active kasam stats + completed kasam stats
            let cellWidth = ((view.frame.size.width - (15 * 4)) / 3)
            detailedStatsCollectionViewHeight.constant = cellWidth + 40
            return CGSize(width: cellWidth, height: cellWidth + 40)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == weekStatsCollectionView {
            if detailedStats.count == 0 {                                   //user not following any kasams
                //go to Discover Page when clicked
                animateTabBarChange(tabBarController: self.tabBarController!, to: self.tabBarController!.viewControllers![0])
                self.tabBarController?.selectedIndex = 0
            } else if detailedStats.count != 0 && weeklyStats.count == 0 {  //user following kasams that aren't active yet
                kasamTitleGlobal = detailedStats[indexPath.row].kasamTitle
                kasamIDGlobal = detailedStats[indexPath.row].kasamID
                kasamMetricTypeGlobal = detailedStats[indexPath.row].metricType
                kasamImageGlobal = detailedStats[indexPath.row].imageURL
                joinedDateGlobal = detailedStats[indexPath.row].joinedDate
                self.performSegue(withIdentifier: "goToStats", sender: indexPath)
            } else {
                kasamTitleGlobal = weeklyStats[indexPath.row].kasamTitle
                kasamIDGlobal = weeklyStats[indexPath.row].kasamID
                kasamMetricTypeGlobal = weeklyStats[indexPath.row].metricType
                kasamImageGlobal = weeklyStats[indexPath.row].imageURL
                self.performSegue(withIdentifier: "goToStats", sender: indexPath)
            }
        } else if collectionView == editKasamsCollectionView {
            kasamTitleGlobal = myKasamsArray[indexPath.row].kasamTitle
            kasamIDGlobal = myKasamsArray[indexPath.row].kasamID
            kasamImageGlobal = myKasamsArray[indexPath.row].imageURL
            self.performSegue(withIdentifier: "goToEditKasam", sender: indexPath)
        } else if collectionView == detailedStatsCollectionView {
            if detailedStats.count == 0 {
               //go to Discover Page when clicked
               animateTabBarChange(tabBarController: self.tabBarController!, to: self.tabBarController!.viewControllers![0])
               self.tabBarController?.selectedIndex = 0
            } else {
                kasamTitleGlobal = detailedStats[indexPath.row].kasamTitle
                kasamIDGlobal = detailedStats[indexPath.row].kasamID
                kasamMetricTypeGlobal = detailedStats[indexPath.row].metricType
                kasamImageGlobal = detailedStats[indexPath.row].imageURL
                joinedDateGlobal = detailedStats[indexPath.row].joinedDate
                self.performSegue(withIdentifier: "goToStats", sender: indexPath)
            }
        }
    }
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if completedStats.count > 0 {
            completedLabel.isHidden = false
        }
        return completedStats.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let block = completedStats[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "CompletedKasamCell") as! CompletedKasamCell
        cell.setBlock(block: block)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        kasamTitleGlobal = completedStats[indexPath.row].kasamTitle
        kasamIDGlobal = completedStats[indexPath.row].kasamID
        kasamMetricTypeGlobal = completedStats[indexPath.row].metricType
        kasamImageGlobal = completedStats[indexPath.row].imageURL
        joinedDateGlobal = completedStats[indexPath.row].joinedDate
        self.performSegue(withIdentifier: "goToStats", sender: indexPath)
    }
}

//Changing the profile image
extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func setupImageHolders(){
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(openImagePicker))
        profileImageClickArea.addGestureRecognizer(imageTap)
    }
    
    @objc func openImagePicker(_ sender:Any) {
        // Open Image Picker
        showChooseSourceTypeAlertController()
    }
    
    func showChooseSourceTypeAlertController() {
        let photoLibraryAction = UIAlertAction(title: "Choose a Photo", style: .default) { (action) in
            self.showImagePickerController(sourceType: .photoLibrary)
        }
        let cameraAction = UIAlertAction(title: "Take a New Photo", style: .default) { (action) in
            self.showImagePickerController(sourceType: .camera)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        AlertService.showAlert(style: .actionSheet, title: nil, message: nil, actions: [photoLibraryAction, cameraAction, cancelAction], completion: nil)
    }
    
    func showImagePickerController(sourceType: UIImagePickerController.SourceType) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        imagePickerController.sourceType = sourceType
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            self.profileImage.image = editedImage.withRenderingMode(.alwaysOriginal)
            if self.profileImage?.image != PlaceHolders.kasamHeaderPlaceholderImage {
                loadingAnimation(animationView: animationView, animation: "success", height: 100, overlayView: nil, loop: false) {
                    self.animationView.removeFromSuperview()
                }
                profileImage.hideSkeleton()
                saveImage(image: self.profileImage!.image!, location: "users/"+Auth.auth().currentUser!.uid+"/manual_profile_pic.jpg", completion: {uploadedProfileImageURL in
                    if uploadedProfileImageURL != nil {
                        DBRef.currentUser.child("ProfilePic").setValue(uploadedProfileImageURL)
                    }
                })
            }
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.profileImage?.image = originalImage.withRenderingMode(.alwaysOriginal)
            if self.profileImage?.image != PlaceHolders.kasamHeaderPlaceholderImage {
                loadingAnimation(animationView: animationView, animation: "success", height: 100, overlayView: nil, loop: false) {
                    self.animationView.removeFromSuperview()
                }
                profileImage.hideSkeleton()
                saveImage(image: self.profileImage!.image!, location: "users/"+Auth.auth().currentUser!.uid+"/manual_profile_pic.jpg", completion: {uploadedProfileImageURL in
                    if uploadedProfileImageURL != nil {
                        DBRef.currentUser.child("ProfilePic").setValue(uploadedProfileImageURL)
                    }
                })
            }
        }
        dismiss(animated: true, completion: nil)
    }
    
    func saveImage(image: UIImage?, location: String, completion: @escaping (String?)->()) {
        //Saves Profile Image in Firebase Storage
        let imageData = image?.jpegData(compressionQuality: 0.5)
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
    
        if imageData != nil {
            saveStorageRef.child(location).putData(imageData!, metadata: metaData) {(metaData, error) in
                if error == nil, metaData != nil {
                    self.saveStorageRef.child(location).downloadURL { url, error in
                        completion(url!.absoluteString)
                    }
                }
            }
        } else {completion(nil)}
    }
}
