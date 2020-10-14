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

class ProfileViewController: UIViewController, UIPopoverPresentationControllerDelegate, MoodCellDelegate {
   
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
    
    @IBOutlet weak var moodViewHeight: NSLayoutConstraint!
    @IBOutlet weak var moodView: UIView!
    @IBOutlet weak var moodDate: UILabel!
    @IBOutlet weak var moodCollectionView: UICollectionView!
    @IBOutlet weak var moodPieChart: PieChartView!
    @IBOutlet weak var moodTotalScore: UILabel!
    @IBOutlet weak var moodSettings: UIButton!
    
    @IBOutlet weak var topViewHeight: NSLayoutConstraint!
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var contentView: NSLayoutConstraint!
    @IBOutlet weak var badgesView: UIStackView!
    
    @IBOutlet weak var completedKasamsTable: SelfSizedTableView!
    @IBOutlet weak var completedKasamTableHeight: NSLayoutConstraint!
    @IBOutlet weak var completedLabel: UILabel!
    
    var myKasamsArray: [EditMyKasamFormat] = []
    var completedStats: [CompletedKasamFormat] = []
    var totalKasamDays = 0
    var dayDictionary = [Int:String]()
    var metricDictionary = [Int:Double]()
    let animationView = AnimationView()
    var userKasamDBHandle: DatabaseHandle!
    var saveStorageRef = Storage.storage().reference()
    var completedTableRowHeight = CGFloat(90)
    let popTip = PopTip()
    var popTipStatus = false
    
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
        getMoodStats()
        setupNavBar(clean: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.badgeNo.text = String(describing: SavedData.trophiesCount)
        if SavedData.trophiesCount == 1 {self.badgeLabel.text = "trophy"}
        profileUpdate()
    }
    
    func updateScrollViewSize(){
        collectionViewHeight.constant = moodViewHeight.constant + CGFloat(57.5)       //57.5 is the collectionView Title height
        updateContentViewHeight(contentViewHeight: contentView, tableViewHeight: completedKasamTableHeight, tableRowHeight: completedTableRowHeight, additionalTableHeight: nil, rowCount: completedStats.count, additionalHeight: moodViewHeight.constant + 120 + topViewHeight.constant)
    }
    
    func viewSetup(){
        moodView.layer.cornerRadius = 15.0
        moodViewHeight.constant = (view.bounds.size.width * (2/5))
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
        completedStats.removeAll()
        metricDictionary.removeAll()
    
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
                    self.completedKasamsTable.reloadData()
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
                self.completedKasamsTable.reloadData()
                self.updateScrollViewSize()
            }
        })
        DispatchQueue.main.async {
            self.updateScrollViewSize()
        }
    }
    
    func loadCompletedTable(kasamID: String, kasamName: String, kasamImage: URL, metric: String, program: Bool, historySnap: DataSnapshot){
        if let value = historySnap.value as? [String: Any] {
            let daysCompleted = value["Days"] as? Int ?? 0
            self.totalKasamDays += daysCompleted
            self.completedStats.append(CompletedKasamFormat(kasamID: kasamID, kasamName: kasamName, daysCompleted: daysCompleted , imageURL: kasamImage, firstDate: value["First"] as? String, lastDate: value["Last"] as? String, metric: metric, program: program))
            
            //Order the table by #days completed
            self.completedStats = self.completedStats.sorted(by: { $0.daysCompleted > $1.daysCompleted })
            self.completedKasamsTable.reloadData()
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
    
    //MOOD SETUP-------------------------------------------------------------------------------------------------
    
    func getMoodStats(){
        moodSettings.setIcon(icon: .fontAwesomeSolid(.cog), iconSize: 16, color: .darkGray, backgroundColor: .clear, forState: .normal)
        DBRef.userMood.child("current").observeSingleEvent(of: .value) {(snap) in
            if let currentDeets = snap.value as? [String:Any] {
                if let values = currentDeets["value"] as? [Double] {
                    SavedData.moodStats = values
                    self.setupMoodChart()
                    self.loadMoodPieChart{self.moodCollectionView.reloadData()}
                }
                if let date = currentDeets["date"] as? String {
                    self.moodDate.text = date.shortDateToLongDate()
                }
            }
        }
        DBRef.userMood.child("current").child("value").observe(.childChanged) {(snap) in
            if let stat = snap.value as? Double {
                let row = Int(snap.key)!
                SavedData.moodStats[row] = stat
                if let cell = self.moodCollectionView.cellForItem(at: IndexPath(item: row, section: 0)) as? MoodCell {
                    cell.setLevel(value: stat)
                    self.loadMoodPieChart {}
                    self.moodDate.text = self.getCurrentDate().shortDateToLongDate()
                }
            }
        }
    }
    
    func setupMoodChart(){
        moodPieChart.holeColor = .clear
        moodPieChart.legend.enabled = false
        moodPieChart.drawSlicesUnderHoleEnabled = false
        moodPieChart.chartDescription?.enabled = false
        moodPieChart.drawCenterTextEnabled = true
        moodPieChart.drawHoleEnabled = false
        moodPieChart.rotationEnabled = false
        moodPieChart.holeRadiusPercent = 1.5
        moodPieChart.setExtraOffsets(left: 0, top: 0, right: 0, bottom: 0)
        moodPieChart.highlightPerTapEnabled = false
    }
    
    func loadMoodPieChart (completion:@escaping () -> ()) {
        var moodScore = 0.0
        var moodPieChartStats = [Double]()
        var count = 0
        for stat in SavedData.moodStats {
            count += 1
            let moodPercent = (stat / 8.0)
            moodScore += moodPercent
            if count % 2 != 0 {moodPieChartStats.append(moodPercent)}
            else {moodPieChartStats[(count / 2) - 1] = moodPieChartStats[(count / 2) - 1] + moodPercent}
        }
        moodPieChartStats.append(1.0 - moodScore)
        let entries = (0..<moodPieChartStats.count).map {(i) -> PieChartDataEntry in
            return PieChartDataEntry(value: moodPieChartStats[i], label: nil, icon: nil)
        }
        moodTotalScore.text = "\(Int(moodScore * 100))%"
        
        let set = PieChartDataSet(entries: entries, label: "")
        let fillColor = UIColor.darkGray.withAlphaComponent(0.7)
        set.colors = [fillColor, fillColor, fillColor, fillColor, UIColor.clear]
        moodPieChart.data = PieChartData(dataSet: set)
        for set in moodPieChart.data!.dataSets {set.drawValuesEnabled = false}
        moodPieChart.animate(xAxisDuration: 1, easingOption: .easeOutBack)
        completion()
    }
    
    @IBAction func changeMoodPressed(_ sender: Any) {
        showCenterMoodChange()
    }
    
    func showPopTipInfo(row: Int, frame: CGRect, type: String){
        popTip.shouldDismissOnTapOutside = true
        popTip.shouldDismissOnTap = true
        popTip.shouldDismissOnSwipeOutside = true
        popTip.bubbleColor = .darkGray
        popTip.appearHandler = {popTip in self.popTipStatus = true}
        popTip.dismissHandler = {popTip in self.popTipStatus = false}
        let frameX = self.moodCollectionView.layoutAttributesForItem(at: IndexPath(row: row, section: 0))!.frame.minX + 5
        let modifiedFrame = CGRect(x: frameX, y: frame.minY - 5, width: frame.width, height: frame.height)
        if popTipStatus == false {popTip.show(text: type, direction: .autoVertical, maxWidth: 80, in: moodCollectionView, from: modifiedFrame, duration: 2)}
        else {popTip.hide()}
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
        let kasamcount = SavedData.personalKasamBlocks.count + SavedData.groupKasamBlocks.count
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

//CollectionView---------------------------------------------------------------------------------------------------

extension ProfileViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return SavedData.moodStats.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MoodCell", for: indexPath) as! MoodCell
        cell.cellDelegate = self
        cell.setBlock(position: indexPath.row, value: SavedData.moodStats[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (moodCollectionView.frame.size.width / 8), height: (moodCollectionView.frame.size.height))
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
}
