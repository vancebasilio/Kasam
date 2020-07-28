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
    
    var weeklyStats: [weekStatsFormat] = []
    var myKasamsArray: [EditMyKasamFormat] = []
    var completedStats: [CompletedKasamFormat] = []
    var totalKasamDays = 0
    var dayDictionary = [Int:String]()
    var metricDictionary = [Int:Double]()
    let animationView = AnimationView()
    var userKasamDBHandle: DatabaseHandle!
    var saveStorageRef = Storage.storage().reference()
    var completedTableRowHeight = CGFloat(90)
    
    //Kasam Following
    var kasamIDGlobal: String = ""
    var kasamImageGlobal: URL!
    var currentKasamTransfer: Bool!
    var userHistoryTransfer: CompletedKasamFormat?
    
    var tableViewHeight = CGFloat(0)
    var noUserKasams = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        profileSetup()
        profilePicture()
        setupDateDictionary()
        getDetailedStats()
        viewSetup()
        setupImageHolders()
        setupNavBar(clean: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        profileUpdate()
    }
    
    func updateScrollViewSize(){
        collectionViewHeight.constant = kasamStatsHeight.constant + CGFloat(57.5)       //57.5 is the collectionView Title height
        let additional = kasamStatsHeight.constant + 120 + topViewHeight.constant
        updateContentViewHeight(contentViewHeight: contentView, tableViewHeight: completedKasamTableHeight, tableRowHeight: completedTableRowHeight, rowCount: completedStats.count, additionalHeight: additional)
    }
    
    func viewSetup(){
        levelLineBack.layer.cornerRadius = 4
        levelLineBack.clipsToBounds = true
        levelLine.layer.cornerRadius = 4
        levelLine.clipsToBounds = true
        navigationController?.navigationBar.barTintColor = UIColor.init(red: 249, green: 249, blue: 249)
        
        let showCompletionAnimation = NSNotification.Name("ShowCompletionAnimation")
               NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.showCompletionAnimation), name: showCompletionAnimation, object: nil)
        
        userFirstName.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(changeDisplayName)))
    }
    
    @objc func changeDisplayName(){
        changeDisplayNamePopup() {(success) in
            self.userFirstName.text =  Auth.auth().currentUser?.displayName
        }
    }
    
    @objc func showCompletionAnimation(){
        animationView.loadingAnimation(view: view, animation: "checkmark", width: 400, overlayView: nil, loop: false, buttonText: nil){
            self.animationView.removeFromSuperview()
        }
    }
    
    //GET ALL THE STATS-------------------------------------------------------------------------------------------------
    
    //STEP 1
    @objc func getDetailedStats() {
        completedStats.removeAll()
        weeklyStats.removeAll()
        metricDictionary.removeAll()
    
        self.totalKasamDays = 0
        DBRef.userHistory.observe(.childAdded, with:{(snap) in
            self.addKasamStats(snap: snap, kasamID: snap.key)
        })
        DBRef.userHistory.observe(.childChanged, with:{(snap) in
            self.editKasamStats(snap: snap, kasamID: snap.key)
        })
        DBRef.userHistory.observe(.childRemoved, with:{(snap) in
            if let index = self.completedStats.index(where: {($0.kasamID == snap.key)}) {
                self.completedStats.remove(at: index)
                self.totalKasamDays -= 1
                self.completedKasamsTable.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                self.updateScrollViewSize()
                self.setKasamLevel()
            }
        })
    }
    
    func addKasamStats(snap: DataSnapshot, kasamID: String){
        var kasamImage = URL(string: SavedData.kasamDict[kasamID]?.image ?? "")
        var kasamName = SavedData.kasamDict[kasamID]?.kasamName
        //History for kasams that aren't being followed right now
        if SavedData.kasamDict[kasamID] == nil {
            DBRef.coachKasams.child(kasamID).child("Image").observeSingleEvent(of: .value) {(image) in
                kasamImage = URL(string: image.value as! String)
                DBRef.coachKasams.child(kasamID).child("Title").observeSingleEvent(of: .value) {(name) in
                    kasamName = name.value as? String
                    self.loadCompletedTable(kasamID: kasamID, kasamName: kasamName ?? "Kasam", kasamImage: kasamImage ?? URL(string:PlaceHolders.kasamLoadingImageURL)!, snap: snap)
                }
            }
        //History for kasams that ARE being followed
        } else {
            self.getWeeklyStats(kasamID: kasamID, snap: snap)
            self.loadCompletedTable(kasamID: kasamID, kasamName: kasamName ?? "Kasam", kasamImage: kasamImage ?? URL(string:PlaceHolders.kasamLoadingImageURL)!, snap: snap)
        }
    }
    
    func editKasamStats(snap: DataSnapshot, kasamID: String){
        if let index = completedStats.index(where: {($0.kasamID == kasamID)}) {
            completedStats[index].userHistorySnap = snap
            if let value = snap.value as? [String:[String:Any]] {
                let newDaysCompleted = value.values.flatMap{$0}.count
                self.totalKasamDays += (newDaysCompleted - completedStats[index].daysCompleted)
                completedStats[index].daysCompleted = newDaysCompleted
            }
            self.completedStats = self.completedStats.sorted(by: { $0.daysCompleted > $1.daysCompleted })
            self.completedKasamsTable.reloadData()
            self.setKasamLevel()
        }
    }
    
    func loadCompletedTable(kasamID: String, kasamName: String, kasamImage: URL, snap: DataSnapshot){
        var historyCount = 0
        if let value = snap.value as? [String:[String:Any]] {
            historyCount = value.values.flatMap{$0}.count
        }
        let completedStats = CompletedKasamFormat(kasamID: kasamID, kasamName: kasamName, daysCompleted: historyCount, imageURL: kasamImage, userHistorySnap: snap)
        self.totalKasamDays += historyCount
        self.completedStats.append(completedStats)
        
        //Order the table by #days completed
        self.completedStats = self.completedStats.sorted(by: { $0.daysCompleted > $1.daysCompleted })
        self.completedKasamsTable.reloadData()
        updateScrollViewSize()
        self.setKasamLevel()
    }
    
    func setKasamLevel(){
        //Kasam Level
        self.totalDays.text = self.totalKasamDays.pluralUnit(unit: "Kasam Day")
        if self.totalKasamDays <= 30 {
            self.startLevel.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 12, weight:.semibold), prefixTextColor: self.startLevel.textColor, icon: .fontAwesomeSolid(.leaf), iconColor: self.startLevel.textColor, postfixText: " Beginner", postfixTextFont: UIFont.systemFont(ofSize: 12, weight:.semibold), postfixTextColor: self.startLevel.textColor, iconSize: 15)
            self.levelLineProgress.constant = self.levelLineBack.frame.size.width * CGFloat(Double(self.totalKasamDays) / 30.0)
        } else if self.totalKasamDays > 30 && self.totalKasamDays <= 90 {
            self.startLevel.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 12, weight:.semibold), prefixTextColor: self.startLevel.textColor, icon: .fontAwesomeBrands(.pagelines), iconColor: self.startLevel.textColor, postfixText: " Intermediate", postfixTextFont: UIFont.systemFont(ofSize: 12, weight:.semibold), postfixTextColor: self.startLevel.textColor, iconSize: 15)
            self.levelLineProgress.constant = self.levelLineBack.frame.size.width * CGFloat(Double(self.totalKasamDays) / 90.0)
        } else if self.totalKasamDays > 90 && self.totalKasamDays <= 360 {
            self.startLevel.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 12, weight:.semibold), prefixTextColor: self.startLevel.textColor, icon: .fontAwesomeSolid(.tree), iconColor: self.startLevel.textColor, postfixText: " Pro", postfixTextFont: UIFont.systemFont(ofSize: 12, weight:.semibold), postfixTextColor: self.startLevel.textColor, iconSize: 15)
            self.levelLineProgress.constant = self.levelLineBack.frame.size.width * CGFloat(Double(self.totalKasamDays) / 360.0)
        }
    }
    
    //STEP 2
    func getWeeklyStats(kasamID: String, snap: DataSnapshot) {
        let kasam = SavedData.kasamDict[kasamID]!
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
                self.weeklyStats.append(weekStatsFormat(kasamID: kasam.kasamID, kasamTitle: kasam.kasamName, imageURL: imageURL ?? URL(string:PlaceHolders.kasamLoadingImageURL)!, daysLeft: (kasam.repeatDuration - kasam.streakInfo.currentStreak.value), metricType: kasam.metricType, metricDictionary: self.metricDictionary, avgMetric: avgMetric))
                weekStatsCollectionView.reloadData()
            }
        }
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
        userFirstName.text =  Auth.auth().currentUser?.displayName
        if let truncUserFirst = Auth.auth().currentUser?.displayName?.split(separator: " ").first.map(String.init), let truncUserLast = Auth.auth().currentUser?.displayName?.split(separator: " ").last.map(String.init) {
            userFirstName.text = truncUserFirst + " " + truncUserLast
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(allTrophiesPopup))
        badgesView.addGestureRecognizer(tap)
    }
    
    @objc func allTrophiesPopup() {
        showTrophiesPopup(kasamID: nil)
    }
    
    @objc func profileUpdate() {
        let kasamcount = SavedData.personalKasamBlocks.count + SavedData.groupKasamBlocks.count
        kasamFollowingNo.text = String(kasamcount)
        if kasamcount == 1 {kasamFollowingLabel.text = "kasam"}
        
        //Badge Count
        SavedData.trophiesCount = 0
        for _ in SavedData.trophiesAchieved {
            SavedData.trophiesCount += 1
        }
        badgeNo.text = String(describing: SavedData.trophiesCount)
        if SavedData.trophiesCount == 1 {badgeLabel.text = "trophy"}
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
}

//CollectionView---------------------------------------------------------------------------------------------------

extension ProfileViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if weeklyStats.count == 0 {
            return 1                                                     //user not following any kasams
        } else {
            return weeklyStats.count                                     //user following active kasams
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "KasamStatsCell", for: indexPath) as! WeeklyStatsCell
        cell.height = kasamStatsHeight.constant
        if weeklyStats.count == 0 {
//                let blankStat = detailedStats[indexPath.row]
//                cell.setBlankBlock(cell: blankStat)                                       //user following kasams that aren't active yet
        } else {
            let stat = weeklyStats[indexPath.row]
            cell.setBlock(cell: stat)                                                 //user following active kasams
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        kasamStatsHeight.constant = (view.bounds.size.width * (2/5))
        return CGSize(width: (view.frame.size.width - 30), height: view.frame.size.width * (2/5))
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //OPTION 1 - User not following any kasams
        if weeklyStats.count == 0 {
//                if let index = completedStats.index(where: {($0.kasamID == detailedStats[indexPath.row].kasamID)}) {
//                    userHistoryTransfer = completedStats[index]; currentKasamTransfer = true
//                }
//                self.performSegue(withIdentifier: "goToStats", sender: indexPath)
    //OPTION 3 - User following active kasam
        } else {
//                if let index = completedStats.index(where: {($0.kasamID == detailedStats[indexPath.row].kasamID)}) {
//                    userHistoryTransfer = completedStats[index]; currentKasamTransfer = true
//                }
//                self.performSegue(withIdentifier: "goToStats", sender: indexPath)
        }
    }
}

//TableView---------------------------------------------------------------------------------------------------

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if completedStats.count > 0 {
            completedLabel.isHidden = false
        }
        return completedStats.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return completedTableRowHeight
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

//ImagePicker---------------------------------------------------------------------------------------------------

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
                animationView.loadingAnimation(view: view, animation: "success", width: 100, overlayView: nil, loop: false, buttonText: nil) {
                    self.animationView.removeFromSuperview()
                }
                saveImage(image: self.profileImage!.image!, location: "users/"+Auth.auth().currentUser!.uid+"/manual_profile_pic.jpg", completion: {uploadedProfileImageURL in
                    if uploadedProfileImageURL != nil {
                        DBRef.currentUser.child("ProfilePic").setValue(uploadedProfileImageURL)
                    }
                })
            }
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.profileImage?.image = originalImage.withRenderingMode(.alwaysOriginal)
            if self.profileImage?.image != PlaceHolders.kasamHeaderPlaceholderImage {
                animationView.loadingAnimation(view: view, animation: "success", width: 100, overlayView: nil, loop: false, buttonText: nil) {
                    self.animationView.removeFromSuperview()
                }
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
