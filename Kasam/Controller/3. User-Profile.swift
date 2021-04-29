//
//  ProfileViewController.swift
//  Kasam 1.0
//
//  Created by Vance Basilio on 2019-04-22.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import FBSDKLoginKit
import SwiftEntryKit
import GoogleSignIn
import Lottie
import Charts
import AMPopTip

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
    
    @IBOutlet weak var topViewHeight: NSLayoutConstraint!
    @IBOutlet weak var contentView: NSLayoutConstraint!
    @IBOutlet weak var badgesView: UIStackView!
    
    @IBOutlet weak var kasamLabel: UILabel!
    @IBOutlet weak var kasamStatsTable: SelfSizedTableView!
    @IBOutlet weak var kasamStatsTableHeight: NSLayoutConstraint!
    
    @IBOutlet weak var friendsLabel: UILabel!
    @IBOutlet weak var friendsTable: SelfSizedTableView!
    @IBOutlet weak var friendsTableHeight: NSLayoutConstraint!
    
    var myKasamsArray: [EditMyKasamFormat] = []
    var completedStats: [CompletedKasamFormat] = []
    var friendsCount: [String] = []
    var totalKasamDays = 0
    var dayDictionary = [Int:String]()
    var metricDictionary = [Int:Double]()
    let animationView = AnimationView()
    var userKasamDBHandle: DatabaseHandle!
    var saveStorageRef = Storage.storage().reference()
    var completedTableRowHeight = CGFloat(90)
    let popTip = PopTip()
    var popTipStatus = false
    
    let kasamsPlaceholderImg = UILabel()
    let kasamsPlaceholderLabel = UILabel()
    let friendsPlaceholderImg = UILabel()
    let friendsPlaceholderLabel = UILabel()
    
    //Kasam Following
    var kasamIDGlobal: String = ""
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
        setupNavBar(clean: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.badgeNo.text = String(describing: SavedData.trophiesCount)
        if SavedData.trophiesCount == 1 {self.badgeLabel.text = "trophy"}
        profileUpdate()
    }
    
    func updateScrollViewSize(){
        print("UserProfile - Update Scroll View")
        //sets the height of the whole tableview, based on the numnber of rows
        if completedStats.count == 0 {
            kasamStatsTableHeight.constant = 150
            setPlaceholderLabel(text: "You aren't following any kasams", underLabel: kasamLabel, img: kasamsPlaceholderImg, label: kasamsPlaceholderLabel)
        } else {
            kasamStatsTableHeight.constant = (completedTableRowHeight * CGFloat(completedStats.count))
            kasamsPlaceholderImg.removeFromSuperview()
            kasamsPlaceholderLabel.removeFromSuperview()
        }
        if friendsCount.count == 0 {
            friendsTableHeight.constant = 150
            setPlaceholderLabel(text: "Add some new friends", underLabel: friendsLabel, img: friendsPlaceholderImg, label: friendsPlaceholderLabel)
        } else {
            friendsPlaceholderImg.removeFromSuperview()
            friendsPlaceholderLabel.removeFromSuperview()
        }
        //elongates the entire scrollview, based on the tableview height
        let frameHeight = self.view.safeAreaLayoutGuide.layoutFrame.height
        let contentHeightToSet = kasamStatsTableHeight.constant + friendsTableHeight.constant + topViewHeight.constant + 30
        if contentHeightToSet > frameHeight {
            contentView.constant = contentHeightToSet
        } else if contentHeightToSet <= frameHeight {
            let diff = frameHeight - contentHeightToSet
            contentView.constant = contentHeightToSet + diff + 1
        }
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
        profileImageClickArea.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showBottomImagePicker)))
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
        self.updateScrollViewSize()
        completedStats = []
        metricDictionary = [:]
        self.totalKasamDays = 0
        DBRef.userHistoryTotals.observe(.childAdded, with:{(snap) in
            let kasamID = snap.key
            //OPTION 1 - History for kasams that aren't being followed right now
            if SavedData.kasamDict[kasamID] == nil {
                DBRef.coachKasams.child(kasamID).child("Info").observeSingleEvent(of: .value) {(kasamInfo) in
                    if let value = kasamInfo.value as? [String:Any] {
                        self.loadCompletedTable(kasamID: kasamID, kasamName: value["Title"] as? String ?? "Kasam", kasamImage: URL(string: value["Image"] as! String) ?? URL(string:PlaceHolders.kasamLoadingImageURL)!, metric: value["Metric"] as? String ?? "", program: (value[
                            "Program"] != nil), historySnap: snap)
                    }
                }
            //OPTION 2 - History for kasams that ARE being followed
            } else {
                self.loadCompletedTable(kasamID: kasamID, kasamName: SavedData.kasamDict[kasamID]?.kasamName ?? "Kasam", kasamImage: URL(string: SavedData.kasamDict[kasamID]?.image ?? "") ?? URL(string:PlaceHolders.kasamLoadingImageURL)!, metric: SavedData.kasamDict[kasamID]?.metricType ?? "", program: SavedData.kasamDict[kasamID]?.programDuration != nil, historySnap: snap)
            }
            self.updateScrollViewSize()
        })
        DBRef.userHistoryTotals.observe(.childChanged, with:{(snap) in
            if let value = snap.value as? [String: Any] {
                if let index = self.completedStats.index(where: {$0.kasamID == snap.key}) {
                    let newDaysCompleted = value["Days"] as? Int ?? 0
                    self.totalKasamDays += newDaysCompleted - self.completedStats[index].daysCompleted
                    self.setKasamLevel()
                    self.completedStats[index].daysCompleted = newDaysCompleted
                    self.completedStats[index].firstDate = value["First"] as? String
                    self.completedStats[index].lastDate = value["Last"] as? String
                    
                    //Order the table by #days completed
                    self.completedStats = self.completedStats.sorted(by: { $0.daysCompleted > $1.daysCompleted })
                    self.kasamStatsTable.reloadData()
                }
            }
        })
        DBRef.userHistoryTotals.observe(.childRemoved, with:{(snap) in
            if let index = self.completedStats.index(where: {$0.kasamID == snap.key}) {
                self.totalKasamDays -= self.completedStats[index].daysCompleted
                self.setKasamLevel()
                self.completedStats.remove(at: index)
                
                //Order the table by #days completed
                self.completedStats = self.completedStats.sorted(by: { $0.daysCompleted > $1.daysCompleted })
                self.kasamStatsTable.reloadData()
                self.updateScrollViewSize()
            }
        })
    }
    
    func loadCompletedTable(kasamID: String, kasamName: String, kasamImage: URL, metric: String, program: Bool, historySnap: DataSnapshot){
        if let value = historySnap.value as? [String: Any] {
            let daysCompleted = value["Days"] as? Int ?? 0
            self.totalKasamDays += daysCompleted
            if daysCompleted > 0 {
                self.completedStats.append(CompletedKasamFormat(kasamID: kasamID, kasamName: kasamName, daysCompleted: daysCompleted , imageURL: kasamImage, firstDate: value["First"] as? String, lastDate: value["Last"] as? String, metric: metric, program: program))
            }
            //Order the table by #days completed
            self.completedStats = self.completedStats.sorted(by: { $0.daysCompleted > $1.daysCompleted })
            self.kasamStatsTable.reloadData()
            updateScrollViewSize()
            self.setKasamLevel()
        }
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
        userFirstName.text =  Auth.auth().currentUser?.displayName
        if let truncUserFirst = Auth.auth().currentUser?.displayName?.split(separator: " ").first.map(String.init), let truncUserLast = Auth.auth().currentUser?.displayName?.split(separator: " ").last.map(String.init) {
            userFirstName.text = truncUserFirst + " " + truncUserLast
        }
        badgesView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(allTrophiesPopup)))
    }
    
    @objc func allTrophiesPopup() {
        showCenterTrophiesPopup(kasamID: nil)
    }
    
    @objc func profileUpdate() {
        let kasamcount = (SavedData.todayKasamBlocks["personal"]?.count ?? 0) + (SavedData.todayKasamBlocks["group"]?.count ?? 0)
        kasamFollowingNo.text = String(kasamcount)
        if kasamcount == 1 {kasamFollowingLabel.text = "kasam"}
    }

    func profilePicture() {
        if let user = Auth.auth().currentUser {
            let storageRef = Storage.storage().reference(forURL: "gs://kasam-coach.appspot.com")
            //Check if user has manually set a profile image
            DBRef.userInfo.child("ProfilePic").observeSingleEvent(of: .value, with:{(snap) in
                if snap.exists() {
                    //get the manually set Image
                    self.profileImage.sd_setImage(with: URL(string:snap.value as! String), completed: nil)
                } else {
                    //get the Facebook or Google Image
                    let profilePicRef = storageRef.child("users/"+user.uid+"/profile_pic.jpg")
                    profilePicRef.downloadURL {(url, error) in
                        //Get the image from Firebase
                        self.profileImage?.sd_setImage(with: url, placeholderImage: PlaceHolders.kasamLoadingImage, options: [], completed: { (image, error, cache, url) in
                        })
                    }
                }
            })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToStats" {
            let statsTransfer = segue.destination as! StatisticsViewController
            statsTransfer.currentKasam = currentKasamTransfer
            statsTransfer.transferArray = userHistoryTransfer
        } else if segue.identifier == "goToEditKasam" {
            NewKasam.editKasamCheck = true
            NewKasam.kasamID = kasamIDGlobal
        }
    }
}

//TableView---------------------------------------------------------------------------------------------------

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if completedStats.count == 0 {
            
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
    
    @objc func showBottomImagePicker() {
        showBottomButtonPopup(title: "Change Kasam Image", buttonText: ["Choose a Photo", "Take a new Photo"]) {(buttonPressed) in
            if buttonPressed == 0 {
                self.showImagePickerController(sourceType: .photoLibrary)
            } else {
                self.showImagePickerController(sourceType: .camera)
            }
        }
    }
    
    func showImagePickerController(sourceType: UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = sourceType
        SwiftEntryKit.dismiss()
        present(imagePicker, animated: true, completion: nil)
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
                        DBRef.userInfo.child("ProfilePic").setValue(uploadedProfileImageURL)
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
                        DBRef.userInfo.child("ProfilePic").setValue(uploadedProfileImageURL)
                    }
                })
            }
        }
        dismiss(animated: true, completion: nil)
    }
    
    func setPlaceholderLabel(text: String, underLabel: UILabel, img: UILabel, label: UILabel){
        let screenSize: CGRect = UIScreen.main.bounds
        let placeHolderHeight = CGFloat(150)    //change these values to adjust
        let imgSize = CGFloat(30)               //change these values to adjust
        let imgTC = (placeHolderHeight / 2) - imgSize
        img.setIcon(icon: .fontAwesomeSolid(.plusCircle), iconSize: imgSize, color: .lightGray, bgColor: .clear)
        label.text = text
        label.textAlignment = .center
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 17)
        self.view.addSubview(label)
        self.view.addSubview(img)
        img.isUserInteractionEnabled = true
        if img == kasamsPlaceholderImg {
            img.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goToCreateNewKasam)))
        } else {
            img.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(addFriend)))
        }
        img.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        let imgHC = NSLayoutConstraint(item: img, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0)
        let imgBC = NSLayoutConstraint(item: img, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: underLabel, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: imgTC)
        let imgWC = NSLayoutConstraint(item: img, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: imgSize)
        let imgHeC = NSLayoutConstraint(item: img, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: imgSize)
        self.view.addConstraints([imgHC, imgBC, imgWC, imgHeC])
        let labelHC = NSLayoutConstraint(item: label, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0)
        let labelTC = NSLayoutConstraint(item: label, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: img, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0)
        let labelWC = NSLayoutConstraint(item: label, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: screenSize.width)
        let labelHeC = NSLayoutConstraint(item: label, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: imgSize)
        view.addConstraints([labelHC, labelTC, labelWC, labelHeC])
    }
    
    @objc func addFriend(){
        showCenterOptionsPopup(kasamID: nil, title: "Feautre coming soon!", subtitle: nil, text: nil, type:"logout", button: "Okay") {(mainButtonPressed) in

        }
    }
}
