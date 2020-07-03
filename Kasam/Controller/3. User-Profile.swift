//
//  ProfileViewController.swift
//  Kasam 1.0
//
//  Created by Vance Basilio on 2019-04-22.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit
import SwiftEntryKit
import SkeletonView
import GoogleSignIn
import Lottie

class ProfileViewController: UIViewController, UIPopoverPresentationControllerDelegate {
   
    @IBOutlet weak var userFirstName: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var profileImageClickArea: UIView!
    @IBOutlet weak var kasamFollowingNo: UILabel!
    @IBOutlet weak var kasamFollowingLabel: UILabel!
    @IBOutlet weak var badgeNo: UILabel!
    @IBOutlet weak var badgeLabel: UILabel!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var levelLine: UIView!
    @IBOutlet weak var levelLineProgress: NSLayoutConstraint!
    @IBOutlet weak var levelLineBack: UIView!
    @IBOutlet weak var startLevel: UILabel!
    @IBOutlet weak var totalDays: UILabel!
    @IBOutlet weak var weekStatsCollectionView: UICollectionView!
    @IBOutlet weak var kasamStatsHeight: NSLayoutConstraint!
    @IBOutlet weak var topViewHeight: NSLayoutConstraint!
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var completedStatsHeight: NSLayoutConstraint!
    @IBOutlet weak var contentView: NSLayoutConstraint!
    @IBOutlet weak var badgesView: UIStackView!
    
    @IBOutlet weak var completedKasamsTable: SelfSizedTableView!
    @IBOutlet weak var completedKasamTableHeight: NSLayoutConstraint!
    @IBOutlet weak var completedLabel: UILabel!
    
    @IBOutlet weak var editKasamLabel: UILabel!
    @IBOutlet weak var editKasamsCollectionView: UICollectionView!
    @IBOutlet weak var editKasamsHeight: NSLayoutConstraint!
    
    var weeklyStats: [weekStatsFormat] = []
    var detailedStats: [UserStatsFormat] = []
    var myKasamsArray: [EditMyKasamFormat] = []
    var completedStats: [CompletedKasamFormat] = []
    var daysCompletedDict: [String:Int] = [:]
    var dayDictionary = [Int:String]()
    var metricDictionary = [Int:Double]()
    let animationView = AnimationView()
    var userKasamDBHandle: DatabaseHandle!
    var saveStorageRef = Storage.storage().reference()
    
    //Kasam Following
    var kasamIDGlobal: String = ""
    var kasamImageGlobal: URL!
    var currentKasamTransfer: Bool!
    var userHistoryTransfer: CompletedKasamFormat?
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
        setupNavBar(clean: true)
    }
    
    override func viewDidLayoutSubviews(){
    //Table Resizing
        completedKasamsTable.frame = CGRect(x: completedKasamsTable.frame.origin.x, y: completedKasamsTable.frame.origin.y, width: completedKasamsTable.frame.size.width, height: completedKasamsTable.contentSize.height)
        self.completedKasamTableHeight.constant = self.completedKasamsTable.contentSize.height
        completedKasamsTable.reloadData()
        let frame = self.view.safeAreaLayoutGuide.layoutFrame
        
    //STEP 1 - Titles
        var multiplier = 0
        if myKasamsArray.count != 0 {multiplier += 1}
        let titleHeights = 52.5 + (57.5 * (Double(multiplier)))
    //STEP 2 - CollectionViews
        collectionViewHeight.constant = kasamStatsHeight.constant + editKasamsHeight.constant + CGFloat(titleHeights)
    //STEP 3 - TableView
        if completedStats.count > 0 {
            tableViewHeight = completedKasamTableHeight.constant + 42.5                //42.5 is the completed label height
            completedStatsHeight.constant = completedKasamTableHeight.constant
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
        levelLineBack.layer.cornerRadius = 4
        levelLineBack.clipsToBounds = true
        levelLine.layer.cornerRadius = 4
        levelLine.clipsToBounds = true
        navigationController?.navigationBar.barTintColor = UIColor.init(red: 249, green: 249, blue: 249)
        
        let notificationName = NSNotification.Name("ProfileUpdate")
        NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.profileUpdate), name: notificationName, object: nil)
        
        let kasamStatsUpdate = NSNotification.Name("KasamStatsUpdate")
        NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.getDetailedStats), name: kasamStatsUpdate, object: nil)
        
        let showCompletionAnimation = NSNotification.Name("ShowCompletionAnimation")
               NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.showCompletionAnimation), name: showCompletionAnimation, object: nil)
    }
    
    @objc func showCompletionAnimation(){
        getMyKasams()
        animationView.loadingAnimation(view: view, animation: "checkmark", height: 400, overlayView: nil, loop: false){
            self.animationView.removeFromSuperview()
        }
    }
    
    //GET ALL THE STATS-------------------------------------------------------------------------------------------------
    
    //STEP 1
    @objc func getDetailedStats() {
        detailedStats.removeAll()
        completedStats.removeAll()
        weeklyStats.removeAll()
        metricDictionary.removeAll()
        var count = 0
        //Loops through all kasams that user is following and get kasamID
        for kasam in SavedData.kasamDict.values {
            DBRef.coachKasams.child(kasam.kasamID).observeSingleEvent(of: .value) {(snap) in
                let snapshot = snap.value as! Dictionary<String,Any>
                let imageURL = URL(string:snapshot["Image"]! as! String)        //getting the image and saving it to SavedData
                kasam.image = snapshot["Image"]! as! String
                kasam.metricType = snapshot["Metric"]! as! String               //getting the metricType and saving it to SavedData
                
                DBRef.userHistory.child(kasam.kasamID).observeSingleEvent(of: .value, with:{(snap) in
                //PART 1 - Weekly Stats for Current Kasams
                    if kasam.currentStatus == "active" {
                        self.getWeeklyStats(kasamID: kasam.kasamID, snap: snap)
                    }
                //PART 2 - Completed Stats Table
                    if Int(snap.childrenCount) == 0 && kasam.currentStatus == "inactive" {
                        count += 1
                    } else {
                        let stats = CompletedKasamFormat(kasamID: kasam.kasamID, kasamName: kasam.kasamName, daysCompleted: Int(snap.childrenCount), imageURL: imageURL ?? URL(string:PlaceHolders.kasamLoadingImageURL)!, userHistorySnap: snap)
                        self.completedStats.append(stats)
                        count += 1
                        //Order the table by #days completed
                        DispatchQueue.main.async {
                            if count == SavedData.kasamDict.count {
                                self.completedStats = self.completedStats.sorted(by: { $0.daysCompleted > $1.daysCompleted })
                            }
                        }
                    }
                })
                
                //PART 3 - Current Stats CollectionView
                if kasam.currentStatus == "active" {
                    let endDate = Calendar.current.date(byAdding: .day, value: kasam.repeatDuration, to: kasam.joinedDate)
                    let userStats = UserStatsFormat(kasamID: kasam.kasamID, kasamTitle: kasam.kasamName, imageURL: imageURL ?? URL(string:PlaceHolders.kasamLoadingImageURL)!, joinedDate: kasam.joinedDate, endDate: endDate, metricType: kasam.metricType, order: kasam.kasamOrder)
                    self.detailedStats.append(userStats)
                    self.weekStatsCollectionView.reloadData()
                }
                    
                //Kasam Level
                self.kasamHistoryRefHandle = DBRef.userHistory.child(kasam.kasamID).observe(.childAdded, with:{(snapshot) in
                    self.daysCompletedDict[snapshot.key] = 1
                    let total = self.daysCompletedDict.count
                    self.totalDays.text = total.pluralUnit(unit: "Kasam Day")
                    if total <= 30 {
                        self.startLevel.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 12, weight:.semibold), prefixTextColor: self.startLevel.textColor, icon: .fontAwesomeSolid(.leaf), iconColor: self.startLevel.textColor, postfixText: " Beginner", postfixTextFont: UIFont.systemFont(ofSize: 12, weight:.semibold), postfixTextColor: self.startLevel.textColor, iconSize: 15)
                        self.levelLineProgress.constant = self.levelLineBack.frame.size.width * CGFloat(Double(total) / 30.0)
                    } else if total > 30 && total <= 90 {
                        self.startLevel.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 12, weight:.semibold), prefixTextColor: self.startLevel.textColor, icon: .fontAwesomeBrands(.pagelines), iconColor: self.startLevel.textColor, postfixText: " Intermediate", postfixTextFont: UIFont.systemFont(ofSize: 12, weight:.semibold), postfixTextColor: self.startLevel.textColor, iconSize: 15)
                        self.levelLineProgress.constant = self.levelLineBack.frame.size.width * CGFloat(Double(total) / 90.0)
                    } else if total > 90 && total <= 360 {
                        self.startLevel.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 12, weight:.semibold), prefixTextColor: self.startLevel.textColor, icon: .fontAwesomeSolid(.tree), iconColor: self.startLevel.textColor, postfixText: " Pro", postfixTextFont: UIFont.systemFont(ofSize: 12, weight:.semibold), postfixTextColor: self.startLevel.textColor, iconSize: 15)
                        self.levelLineProgress.constant = self.levelLineBack.frame.size.width * CGFloat(Double(total) / 360.0)
                    }
                })
                DispatchQueue.main.async {
                    //Orders the array as kasams with no history will always show up first, even though they were loaded later
                    self.detailedStats = self.detailedStats.sorted(by: { $0.order < $1.order })
                }
            }
        }
    }
    
    //STEP 2
    func getWeeklyStats(kasamID: String, snap: DataSnapshot) {
        let kasam = SavedData.kasamDict[kasamID]!
        var daysLeft = 0
        if kasam.sequence == "streak" {
            daysLeft = kasam.repeatDuration - kasam.streakInfo.currentStreakCompleteProgress
        } else {
            daysLeft = kasam.repeatDuration - kasam.streakInfo.daysWithAnyProgress
        }
        
        var metricMatrix = 0
        var checkerCount = 0
        let imageURL = URL(string:kasam.image)
        for x in 1...7 {
            checkerCount += 1
            self.metricDictionary[x] = 0                                      //To set the base as zero for each day
            var avgMetric = 0
            for kasamStats in snap.children {
                let kasamStats = kasamStats as! DataSnapshot
                if kasamStats.key == self.dayDictionary[x]! {
                    //OPTION 1 - BASIC Kasam
                    if let value = kasamStats.value as? Int {
                        self.metricDictionary[x] = Double(value)
                        metricMatrix += 1
                    }
                    //OPTION 2 - COMPLEX KASAM
                    else if let value = kasamStats.value as? [String: Any] {
                        self.metricDictionary[x] = value["Metric Percent"] as? Double
                        metricMatrix += Int(value["Total Metric"] as? Double ?? 0.0)
                    }
                }
            }
            if checkerCount == 7 {
                if kasam.metricType == "Checkmark" {
                    //For Basic Kasams, show avg %
                    avgMetric = Int((Double(metricMatrix) / Double(Date().dayNumberOfWeek() ?? 7)) * 100)
                } else {
                    //For Complex Kasams, show total for the weeks
                    avgMetric = (metricMatrix)
                }
                self.weeklyStats.append(weekStatsFormat(kasamID: kasam.kasamID, kasamTitle: kasam.kasamName, imageURL: imageURL ?? URL(string:PlaceHolders.kasamLoadingImageURL)!, daysLeft: daysLeft, metricType: kasam.metricType, metricDictionary: self.metricDictionary, avgMetric: avgMetric, order: kasam.kasamOrder))
                
                //Orders the array as kasams with no history will always show up first, even though they were loaded later
                self.weeklyStats = self.weeklyStats.sorted(by: { $0.order < $1.order })
                self.weekStatsCollectionView.reloadData()
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
                    }
                    //remove observer
                    Database.database().reference().child("Coach-Kasams").child(snapshot.key).removeAllObservers()
                })
            })
        })
    }
    
    func setupDateDictionary(){
        let todayDay = Date().dayNumberOfWeek()
        if todayDay == 7 {
            for x in 1...7 {
                self.dayDictionary[x] = (Calendar.current.date(byAdding: .day, value: x - (todayDay!), to: Date())!).dateToString()
            }
        } else {
            for x in 1...7 {
                self.dayDictionary[x] = (Calendar.current.date(byAdding: .day, value: x - (todayDay!), to: Date())!).dateToString()
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
        let tap = UITapGestureRecognizer(target: self, action: #selector(badgesAchievedPopup))
        badgesView.addGestureRecognizer(tap)
    }
    
    @objc func badgesAchievedPopup() {
        showCenterPopup(kasamID: nil)
    }
    
    @objc func profileUpdate() {
        //PART 1 - KASAM FOLLOWING COUNT
        var kasamcount = 0
//        var followingcount: [String: String] = [:]
        kasamFollowingNo.text = String(kasamcount)
            self.kasamUserFollowRefHandle = DBRef.userKasamFollowing.observe(.childAdded) {(snapshot) in
                kasamcount += 1
//                followingcount = [snapshot.key: "1"]                    //this shows no of coaches the user is following
                self.kasamFollowingNo.text = String(kasamcount)
        }
        if kasamcount == 1 {kasamFollowingLabel.text = "kasam"}
        badgeNo.text = String(describing: SavedData.badgesCount)
        if SavedData.badgesCount == 1 {badgeLabel.text = "trophy"}
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
            let statsTransfer = segue.destination as! StatisticsViewController
            statsTransfer.currentKasam = currentKasamTransfer
            statsTransfer.userHistoryTransfer = userHistoryTransfer
        } else if segue.identifier == "goToEditKasam" {
            NewKasam.editKasamCheck = true
            NewKasam.kasamID = kasamIDGlobal
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
            return CGSize(width: cellWidth, height: cellWidth + 40)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == weekStatsCollectionView {
        //OPTION 1 - User not following any kasams
            if detailedStats.count == 0 {
                //go to Discover Page when clicked
                animateTabBarChange(tabBarController: self.tabBarController!, to: self.tabBarController!.viewControllers![0])
                self.tabBarController?.selectedIndex = 0
        //OPTION 2 - User following kasams that aren't active yet
            } else if detailedStats.count != 0 && weeklyStats.count == 0 {
                if let index = completedStats.index(where: {($0.kasamID == detailedStats[indexPath.row].kasamID)}) {
                    userHistoryTransfer = completedStats[index]; currentKasamTransfer = true
                }
                self.performSegue(withIdentifier: "goToStats", sender: indexPath)
        //OPTION 3 - User following active kasam
            } else {
                if let index = completedStats.index(where: {($0.kasamID == detailedStats[indexPath.row].kasamID)}) {
                    userHistoryTransfer = completedStats[index]; currentKasamTransfer = true
                }
                self.performSegue(withIdentifier: "goToStats", sender: indexPath)
            }
        } else if collectionView == editKasamsCollectionView {
            kasamIDGlobal = myKasamsArray[indexPath.row].kasamID
            kasamImageGlobal = myKasamsArray[indexPath.row].imageURL
            self.performSegue(withIdentifier: "goToEditKasam", sender: indexPath)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "CompletedKasamCell") as! CompletedKasamCell
        cell.setCompletedBlock(block: completedStats[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        userHistoryTransfer = completedStats[indexPath.row]; currentKasamTransfer = false
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
                animationView.loadingAnimation(view: view, animation: "success", height: 100, overlayView: nil, loop: false) {
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
                    animationView.loadingAnimation(view: view, animation: "success", height: 100, overlayView: nil, loop: false) {
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
}
