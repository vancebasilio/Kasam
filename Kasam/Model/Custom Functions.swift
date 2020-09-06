//
//  Custom Functions.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-06-10.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Foundation
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase
import AVKit
import Lottie
import var CommonCrypto.CC_MD5_DIGEST_LENGTH
import func CommonCrypto.CC_MD5
import typealias CommonCrypto.CC_LONG

class ProgessView: UIProgressView {
    override func layoutSubviews() {
        super.layoutSubviews()
        let maskLayerPath = UIBezierPath(roundedRect: bounds, cornerRadius: 4.0)
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.bounds
        maskLayer.path = maskLayerPath.cgPath
        layer.mask = maskLayer
    }
}

extension UICollectionViewCell {
    
    func dateFormat(date: Date) -> String {
        let date = date
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateFormat = "yyyy-MM-dd"                                     //***keep this value the same as above
        let finalDate = formatter.string(from: date)
        return finalDate
    }
}

extension UIViewController {
    
    func allTrophiesAchieved() {
        SavedData.trophiesCount = 0
        DBRef.userTrophies.observe(.childAdded) {(trophySnap) in
            let kasamID = trophySnap.key
            DBRef.coachKasams.child(kasamID).child("Info").child("Title").observeSingleEvent(of: .value, with: {(kasamNameSnap) in
                let kasamName = kasamNameSnap.value as! String
                if let kasamIDTrophy = trophySnap.value as? [String: Any] {
                    SavedData.trophiesAchieved[kasamID] = ("",[])
                    SavedData.trophiesAchieved[kasamID]?.kasamName = kasamName
                    for trophyStartDate in kasamIDTrophy {
                        if let badge = trophyStartDate.value as? [String:String] {
                            for badgeDeets in badge {
                                SavedData.trophiesAchieved[kasamID]?.kasamTrophies.append((completedDate: badgeDeets.value, trophyThreshold: Int(badgeDeets.key)!))
                                SavedData.trophiesCount += 1
                            }
                        }
                    }
                }
            })
        }
    }
    
    func updateContentViewHeight(contentViewHeight: NSLayoutConstraint, tableViewHeight: NSLayoutConstraint, tableRowHeight: CGFloat, additionalTableHeight: CGFloat?, rowCount: Int, additionalHeight: CGFloat?){
        //sets the height of the whole tableview, based on the numnber of rows
        tableViewHeight.constant = (tableRowHeight * CGFloat(rowCount)) + (additionalTableHeight ?? 0)
        
        //elongates the entire scrollview, based on the tableview height
        let frameHeight = self.view.safeAreaLayoutGuide.layoutFrame.height
        let contentHeightToSet = tableViewHeight.constant + (additionalHeight ?? 0)
        if contentHeightToSet > frameHeight {
            contentViewHeight.constant = contentHeightToSet
        } else if contentHeightToSet <= frameHeight {
            let diff = frameHeight - contentHeightToSet
            contentViewHeight.constant = contentHeightToSet + diff + 1
        }
    }
    
    func singleKasamUpdate(kasamOrder: Int, tableView: UITableView, type: String) {
        tableView.reloadData()
        var block = SavedData.personalKasamBlocks
        if type == "group" {block = SavedData.groupKasamBlocks}
        if let cell = tableView.cellForRow(at: IndexPath(item: kasamOrder, section: 0)) as? TodayBlockCell {
            tableView.beginUpdates()
            if (cell.kasamName.text == "") {
                if type == "personal" {cell.type = "personal"; cell.setBlock(block: block[kasamOrder].data)}
                else {cell.type = "group"; cell.setBlock(block: block[kasamOrder].data)}
                cell.centerCollectionView()
                cell.collectionCoverUpdate()
            } else if (cell.blockSubtitle.text != block[kasamOrder].data.blockTitle)  {
                cell.blockSubtitle.text = block[kasamOrder].data.blockTitle
            }
            cell.statusUpdate(nil)
            cell.dayTrackerCollectionView.reloadData()
            tableView.endUpdates()
        }
        print("Step 6 - Update \(block[kasamOrder].data.blockTitle)")
    }
    
    func getDayTracker(kasamID: String, tableView: UITableView, type: String) {
        //For the active Kasams on the Personal or Group page
        if let kasam = SavedData.kasamDict[kasamID] {
            //Gets the DayTracker info - only goes into this loop if the user has kasam history
            var db = DBRef.userPersonalHistory.child(kasam.kasamID).child(kasam.joinedDate.dateToString())
            var block = SavedData.personalKasamBlocks
            if type == "group" {
                db = DBRef.groupKasams.child((kasam.groupID)!).child("History").child(Auth.auth().currentUser!.uid)
                block = SavedData.groupKasamBlocks
            }
            db.observe(.value, with: {(snap) in
                if snap.exists() {
                    var displayStatus = "Checkmark"
                    var order = 0
                    var dayTrackerArrayInternal = [Int:(Date,Double)]()
                    var dayPercent = 1.0
                    var percentComplete = 0.0
                    var internalCount = 0
                    var blockDeets: (blockID: String, blockName: String)? = nil
                    
                    for history in snap.children.allObjects as! [DataSnapshot] {
                        internalCount += 1
                        if history.key != "Goal" {
                            let kasamDate = history.key.stringToDate()
                            order = (Calendar.current.dateComponents([.day], from: kasam.joinedDate, to: kasamDate)).day! + 1
                            dayPercent = self.statusPercentCalc(snapshot: history).0
                            dayTrackerArrayInternal[order] = (kasamDate, dayPercent)
                            
                            //Status for Current day
                            if history.key == self.getCurrentDate() {
                                percentComplete = dayPercent
                                if dayPercent == 1 {displayStatus = "Check"}
                                else if dayPercent < 1 && dayPercent > 0 {displayStatus = "Progress"}
                                //Manually set the block title and ID if the user changed it manually
                                if kasam.programDuration != nil {
                                    if let value = history.value as? [String:Any] {
                                        blockDeets = (blockID: value["BlockID"] as? String ?? "", blockName: value["Block Name"] as! String)}
                                    if blockDeets?.blockName == "Rest Day" {displayStatus = "Check"; percentComplete = -1}
                                }
                            }
                        }
                        if internalCount == snap.childrenCount {
                            //DayTrackerArrayInternal adds the status of each day
                            kasam.displayStatus = displayStatus
                            kasam.percentComplete = percentComplete         //only for COMPLEX kasams
                            kasam.dayTrackerArray = dayTrackerArrayInternal
                            
                            if let index = block.index(where: {($0.kasamID == kasam.kasamID)}) {
                                if blockDeets != nil {block[index].data.blockTitle = blockDeets!.blockName; block[index].data.blockID = blockDeets!.blockID}
                                kasam.streakInfo = self.currentStreak(dictionary: dayTrackerArrayInternal, currentDay: block[index].data.dayOrder)
                                NotificationCenter.default.post(name: Notification.Name(rawValue: "RefreshKasamHolderBadge"), object: self)
                                self.singleKasamUpdate(kasamOrder: index, tableView: tableView, type: type)
                            }
                        }
                    }
                } else {
                    kasam.dayTrackerArray = nil
                    kasam.displayStatus = "Checkmark"
                    kasam.streakInfo = (currentStreak:(value:0, date:nil), daysWithAnyProgress:0, longestStreak:0)
                    kasam.percentComplete = 0
                    if let index = block.index(where: {($0.kasamID == kasam.kasamID)}) {
                        self.singleKasamUpdate(kasamOrder: index, tableView: tableView, type: type)
                    }
                }
            })
        }
    }
    
    //STEP 6
    func currentStreak(dictionary: [Int:(Date, Double)], currentDay: Int) -> (currentStreak:(value:Int, date:Date?), daysWithAnyProgress:Int, longestStreak:Int) {
        print("Step 6 - Streak Calc hell6")
        var daysWithAnyProgress = 0
        var currentStreak = 0
        var currentStreakDate: Date?
        var anyProgressCheck = 0
        var longestStreak = 0
        var streak = [0]
        var streakEndDate = [0]
        for day in stride(from: currentDay, through: 1, by: -1) {
            if dictionary[day] != nil {
                streak[streak.count - 1] += 1
                if dictionary[day]!.1 >= 0.0 {
                    daysWithAnyProgress += 1                                        //all days with some progress
                    if streakEndDate.count != streak.count {streakEndDate[streakEndDate.count - 1] = day}
                } else {
                    currentStreak = daysWithAnyProgress                             //current streak days with some progress
                }
            } else if day != currentDay {
                streak += [0]
                streakEndDate += [0]
                if anyProgressCheck == 0 {
                    currentStreak = daysWithAnyProgress                             //current streak days with some progress
                }
                anyProgressCheck = 1
            }
        }
        longestStreak = streak.max() ?? 0
        daysWithAnyProgress = streak.reduce(0, +)
        if anyProgressCheck == 0 {                                                  //in case all days have some progress
            currentStreak = daysWithAnyProgress
        }
        currentStreakDate = dictionary[30]?.0
        return ((currentStreak,currentStreakDate), daysWithAnyProgress, longestStreak)
    }
    
    func statusPercentCalc (snapshot: DataSnapshot) -> (percent: Double, displayStatus: String){
        var percent = 0.0
        var displayStatus = "Checkmark"
        //COMPLEX KASAM
        if let dictionary = snapshot.value as? Dictionary<String,Any> {
            if dictionary["Block Name"] as? String ?? "" == "Rest Day" {
                percent = -1.0
                displayStatus = "Rest Day"
            } else {
                percent = dictionary["Metric Percent"] as? Double ?? 0.0
                if percent < 1 {
                    displayStatus = "Progress"
                    Analytics.logEvent("working_Kasam", parameters: ["metric_percent": percent.rounded(toPlaces: 2) ])
                } else {
                    displayStatus = "Check"
                }
            }
        //SIMPLE KASAM
        } else if snapshot.value as? Int == 1 {
            displayStatus = "Check"
            percent = 1.0
            Analytics.logEvent("completed_Kasam", parameters: nil)
        } else if snapshot.value as? Int == 0 {
            percent = 0.0
            displayStatus = "Checkmark"
        }
        return (percent, displayStatus)
    }
    
    func openKasamBlock(type: String, kasamOrder: Int, day: Int?, date: Date, viewOnly: Bool?, animationView: AnimationView, completion: @escaping ((blockID: String, blockName: String)) -> ()) {
        animationView.loadingAnimation(view: view, animation: "loading", width: 100, overlayView: nil, loop: true, buttonText: nil, completion: nil)
        UIApplication.shared.beginIgnoringInteractionEvents()
        var block = SavedData.personalKasamBlocks; if type == "group" {block = SavedData.groupKasamBlocks}
        let kasamID = block[kasamOrder].kasamID
        var blockIDGlobal = block[kasamOrder].data.blockID
        var blockNameGlobal = block[kasamOrder].data.blockTitle    //DAY TRACKER FUNC WILL LOAD MANUALLY CHANGED BLOCKS FOR PROGRAM KASAMS
        
        var db = DBRef.userPersonalHistory.child(kasamID).child((SavedData.kasamDict[kasamID]?.joinedDate.dateToString())!)
        if type == "group" {db = DBRef.groupKasams.child((SavedData.kasamDict[kasamID]?.groupID)!).child("History").child(Auth.auth().currentUser!.uid)}
        
        //OPTION 1 - Opening a past day's block
        if (day != nil) && (date.dateToString() != Date().dateToString()) {
            db.child(date.dateToString()).observeSingleEvent(of: .value) {(pastProgress) in
                //There's past progress, so the user may have manually completed another kasam
                if pastProgress.exists() {
                    if let value = pastProgress.value as? [String:Any] {
                        blockIDGlobal = value["BlockID"] as? String ?? ""
                        blockNameGlobal = value["Block Name"] as? String ?? ""
                        completion((blockIDGlobal, blockNameGlobal))
                   }
                } else {
                    DBRef.coachKasams.child(kasamID).child("Blocks").observeSingleEvent(of: .value, with: {(blockCountSnapshot) in
                        let blockCount = Int(blockCountSnapshot.childrenCount)
                        var blockOrder = 1
                        if SavedData.kasamDict[kasamID]?.programDuration != nil {
                            //OPTION 1A - Day in past, so find the correct block to show
                            blockOrder = day! & blockCount
                            if blockOrder == 0 {blockOrder = blockCount}
                            DBRef.coachKasams.child(kasamID).child("Timeline").observe(.value, with: {(snapshot) in
                                if let value = snapshot.value as? [String:String] {
                                    blockIDGlobal = value["D\(blockOrder)"]!
                                    self.definesPresentationContext = true
                                    completion((blockIDGlobal, blockNameGlobal))
                                }
                            })
                        } else {
                            //OPTION 1B - Day in past and Kasam has only 1 block, so no point finding the correct block
                            if day! <= blockCount {blockOrder = day!}
                            else {blockOrder = (blockCount / day!) + 1}
                            completion((blockIDGlobal, blockNameGlobal))
                        }
                    })
                }
            }
        //OPTION 2 - Open Today's block
        } else {
            completion((blockIDGlobal, blockNameGlobal))
        }
    }
    
    func updateKasamDayButtonPressed(type: String, kasamOrder: Int, day: Int){
        var kasamID = SavedData.personalKasamBlocks[kasamOrder].data.kasamID
        var newPercent = 0.0
        let statusDate = (Calendar.current.date(byAdding: .day, value: day - SavedData.personalKasamBlocks[kasamOrder].data.dayOrder, to: Date())!).dateToString()
        var db = DBRef.userPersonalHistory.child(kasamID).child((SavedData.kasamDict[kasamID]?.joinedDate.dateToString())!).child(statusDate)
        if type == "group" {
            kasamID = SavedData.groupKasamBlocks[kasamOrder].data.kasamID
            newPercent = (SavedData.kasamDict[kasamID]?.groupTeam?[Auth.auth().currentUser!.uid] ?? 0)
            db = DBRef.groupKasams.child((SavedData.kasamDict[kasamID]?.groupID)!).child("History").child(Auth.auth().currentUser!.uid).child(statusDate)
        }
        if SavedData.kasamDict[kasamID]?.dayTrackerArray?[day]?.1 == 1.0 {
            db.setValue(nil)
            if type == "group" {newPercent -= (1.0 / Double(SavedData.kasamDict[kasamID]?.repeatDuration ?? 30))}
            setHistoryTotal(kasamID: kasamID, statusDate: statusDate, value: 0)
        } else {
            db.setValue(1)
            if type == "group" {newPercent += (1.0 / Double(SavedData.kasamDict[kasamID]?.repeatDuration ?? 30))}
            setHistoryTotal(kasamID: kasamID, statusDate: statusDate, value: 1)
        }
        if type == "group" {
            DBRef.groupKasams.child((SavedData.kasamDict[kasamID]?.groupID)!).child("Info").child("Team").child(Auth.auth().currentUser!.uid).setValue(newPercent.rounded(toPlaces: 2))
        }
    }
    
    //STEP 1 - Saves Kasam Text Data
    func createKasam(existingKasamID: String?, basicKasam: Bool, userKasam: Bool, completion: @escaping (Bool) -> ()) {
        print("1. creating kasam hell1")
        //all fields filled, so can create the Kasam now
        let semaphore = DispatchSemaphore(value: 0)
        self.view.isUserInteractionEnabled = false
        var kasamDB = DatabaseReference()
        //editing existing kasam
        if existingKasamID != "" {
            if userKasam == true {kasamDB = DBRef.userKasams.child(existingKasamID!)}
            else {kasamDB = DBRef.coachKasams.child(existingKasamID!)}
        }
        //creating a new Kasam, so assign a new KasamID
        else {kasamDB = DBRef.userKasams.childByAutoId()}
        var imageURL = ""
        
        let dispatchQueue = DispatchQueue.global(qos: .background)
        dispatchQueue.async {
            if NewKasam.kasamImageToSave != UIImage() {
                //CASE 1 - user has uploaded a new image, so save it
                self.saveImage(image: NewKasam.kasamImageToSave, location: "kasam/\(kasamDB.key!)/kasam_header", completion: {uploadedImageURL in
                    if uploadedImageURL != nil {
                        imageURL = uploadedImageURL!
                        semaphore.signal()
                        print("Case 1")
                    }
                })
            } else if NewKasam.loadedInKasamImage == UIImage() && NewKasam.kasamImageToSave == UIImage() {
                //CASE 2 - no image added
                print("Case 2")
                semaphore.signal()
            } else if NewKasam.loadedInKasamImage != UIImage() && NewKasam.kasamImageToSave == UIImage() {
                //CASE 3 - user editing a kasam and using same kasam image, so no need to save image
                print("Case 3")
                semaphore.signal()
                imageURL = NewKasam.loadedInKasamImageURL!.absoluteString
            }
            semaphore.wait()
            
            //STEP 3 - Register Kasam Data in Firebase Database
            print("3. registering kasam hell1")
            let kasamDictionary = ["Title": NewKasam.kasamName,
                                   "Benefits": NewKasam.benefits,
                                   "Genre": NewKasam.chosenGenre,
                                   "Description": NewKasam.kasamDescription,
                                   "Image": imageURL,
                                   "KasamID": kasamDB.key!,
                                   "CreatorID": Auth.auth().currentUser!.uid as String,
                                   "Rating": "5",
                                   "Level": 0,
                                   "Metric": NewKasam.chosenMetric] as [String : Any]
        
            if NewKasam.kasamID != "" {
                //updating existing kasam
                kasamDB.child("Info").updateChildValues(kasamDictionary as [AnyHashable : Any]) {(error, reference) in
                    //kasam successfully updated
                    if basicKasam == false {self.saveBlocks(kasamID: kasamDB, imageURL: imageURL)}
                    else {completion(true)}
                }
            } else {
                //creating new kasam
                kasamDB.child("Info").setValue(kasamDictionary) {(error, reference) in
                    if error == nil {
                        //Kasam successfully created
                        if basicKasam == false {self.saveBlocks(kasamID: kasamDB, imageURL: imageURL)}
                        else {completion(true)}
                    }
                }
            }
        }
    }
    
    //STEP 2 - Save Kasam Image
    func saveImage(image: UIImage?, location: String, completion: @escaping (String?)->()) {
        print("2. saving image hell1")
        //Saves Kasam Image in Firebase Storage
        let imageData = image?.jpegData(compressionQuality: 0.6)
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
    
        if imageData != nil {
            Storage.storage().reference().child(location).putData(imageData!, metadata: metaData) {(metaData, error) in
                if error == nil, metaData != nil {
                    Storage.storage().reference().child(location).downloadURL { url, error in
                        completion(url!.absoluteString)
                    }
                }
            }
        } else {completion(nil)}
    }
    
    //STEP 4 - Save block info under Kasam
    func saveBlocks(kasamID: DatabaseReference, imageURL: String){
        print("4. saving blocks hell1")
        let newBlockDB = DBRef.coachKasams.child(kasamID.key!).child("Blocks")
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
                let blockDictionary = ["Activity": activityMatrix, "Duration": transferBlockDuration, "Image": imageURL, "Rating": "5", "Title": NewKasam.kasamTransferArray[j]?.blockTitle ?? "Block Title", "BlockID": blockID.key!] as [String : Any]
                blockID.setValue(blockDictionary) {
                    (error, reference) in
                    if error != nil {
                        print(error!)
                    } else {
                        //Kasam successfully created
                        successBlockCount += 1
                        //All the blocks and their images are saved, so go back to the profile view
                        if successBlockCount == NewKasam.numberOfBlocks {
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "ShowCompletionAnimation"), object: self)
                            self.view.isUserInteractionEnabled = true
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    }
                }
            }
        }
    }
    
    func deleteUserKasam(completion: @escaping (Bool) -> ()) {
//        if NewKasam.loadedInKasamImage == UIImage() {
//            //User trying to create a new Kasam, so do not save Kasam
//            self.navigationController?.popToRootViewController(animated: true)
//        } else {
            //delete the existing Kasam
            let popupImage = UIImage.init(icon: .fontAwesomeRegular(.trashAlt), size: CGSize(width: 30, height: 30), textColor: .white)
            showPopupConfirmation(title: "Are you sure?", description: "You won't be able to undo this action", image: popupImage, buttonText: "Delete Kasam") {(success) in
                
                DBRef.userKasams.child(NewKasam.kasamID).removeValue()                 //delete kasam
                
                //delete the pictures from the Kasam if it's not the placeholder image
                if let headerImageToDelete = NewKasam.loadedInKasamImageURL {self.deleteFileFromURL(from: headerImageToDelete)}
                if NewKasam.fullActivityMatrix.count != 0 {
                    for block in 1...NewKasam.fullActivityMatrix.count {
                        if let activityImageToDelete = NewKasam.fullActivityMatrix[block]?[0]?.imageToLoad {
                            self.deleteFileFromURL(from: activityImageToDelete)
                        }
                    }
                }
                completion(true)
            }
//        }
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
    
    //func to hide keyboard when screen tapped
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    func setStatusBarColor(color: UIColor) {
        if #available(iOS 13.0, *) {
            let app = UIApplication.shared
            let statusBarHeight: CGFloat = app.statusBarFrame.size.height
            
            let statusbarView = UIView()
            statusbarView.backgroundColor = color
            view.addSubview(statusbarView)
          
            statusbarView.translatesAutoresizingMaskIntoConstraints = false
            statusbarView.heightAnchor
                .constraint(equalToConstant: statusBarHeight).isActive = true
            statusbarView.widthAnchor
                .constraint(equalTo: view.widthAnchor, multiplier: 1.0).isActive = true
            statusbarView.topAnchor
                .constraint(equalTo: view.topAnchor).isActive = true
            statusbarView.centerXAnchor
                .constraint(equalTo: view.centerXAnchor).isActive = true
        } else {
            let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView
            statusBar?.backgroundColor = color
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func setupGreeting() -> String {
        let truncUserFirst = Auth.auth().currentUser?.displayName?.split(separator: " ").first.map(String.init) ?? "Username"
        return truncUserFirst
    }
    
    // A percent of 0.0 gives the "from" color
    // A percent of 1.0 gives the "to" color
    // Any other percent gives an appropriate color in between the two
    func blend(from: UIColor, to: UIColor, percent: Double) -> UIColor {
        var fR : CGFloat = 0.0
        var fG : CGFloat = 0.0
        var fB : CGFloat = 0.0
        var tR : CGFloat = 0.0
        var tG : CGFloat = 0.0
        var tB : CGFloat = 0.0
        
        from.getRed(&fR, green: &fG, blue: &fB, alpha: nil)
        to.getRed(&tR, green: &tG, blue: &tB, alpha: nil)
        
        let dR = tR - fR
        let dG = tG - fG
        let dB = tB - fB
        
        let rR = fR + dR * CGFloat(percent)
        let rG = fG + dG * CGFloat(percent)
        let rB = fB + dB * CGFloat(percent)
        
        return UIColor(red: rR, green: rG, blue: rB, alpha: 1.0)
    }
    
    // Pass in the scroll percentage to get the appropriate color
    func scrollColor(percent: Double) -> UIColor {
        var start : UIColor
        var end : UIColor
        var perc = percent
        if percent < 0.5 {
            // If the scroll percentage is 0.0..<0.5 blend between white and black
            start = UIColor.white
            end = UIColor.black
        } else {
            // If the scroll percentage is 0.5..1.0 blend between black and gold
            start = UIColor.black
            end = UIColor.colorFive
            perc -= 0.5
        }
        return blend(from: start, to: end, percent: perc * 2.0)
    }
    
    func getCurrentDateTime() -> String {
        let currentDateTime = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .long
        formatter.dateStyle = .short
        let finalDate = formatter.string(from: currentDateTime)
        return finalDate
    }
    
    func getCurrentTime() -> String {
        let currentDateTime = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .long
        formatter.dateStyle = .none
        let finalDate = formatter.string(from: currentDateTime)
        return finalDate
    }
    
    func convertLongDateToShortYear(date: String) -> String {
        var dateOutput = ""
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd"                              //***keep this value the same as above
        
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "MMM d, yyyy"
        
        if let date = dateFormatterGet.date(from: date) {
            dateOutput = dateFormatterPrint.string(from: date)
        } else {
            print("There was an error converting the date")
        }
        return dateOutput
    }

    func dateShortFormat(date: Date) -> String {
        let date = date
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateFormat = "MMMM dd"
        let finalDate = formatter.string(from: date)
        return finalDate
    }
    
    func convertLongDateToShort(date: String) -> String {
        var dateOutput = ""
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd"                              //***keep this value the same as above
        
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "MMM dd"
        
        if let date = dateFormatterGet.date(from: date) {
            dateOutput = dateFormatterPrint.string(from: date)
        } else {
            print("There was an error converting the date")
        }
        return dateOutput
    }
    
    func dayTrackerDateFormat(date: Date, todayDay: Int, row: Int) -> Date {
        let substract = todayDay - row
        let date = Calendar.current.date(byAdding: .day, value: -substract, to: date) ?? date
        return date
    }
    
    func convertTimeAndMetric(time: Double, metric: String ) -> (Double, String) {
        var convertedTime = time
        var convertedMetric = metric
        if time < 120 {
            convertedMetric = "secs"
        } else if time >= 120 && time < 3600 {
            convertedTime = time / 60.0
            convertedMetric = "mins"
        } else if time >= 3600 && time < 3636 {
            convertedTime = time / 3600.0
            convertedMetric = "hour"
        } else if time >= 3636 {
            convertedTime = time / 3600.0
            convertedMetric = "hours"
        }
        return (convertedTime, convertedMetric)
    }
    
    func twitterParallaxScrollDelegate(scrollView: UIScrollView, headerHeight: CGFloat, headerView: UIView, headerBlurImageView: UIView?, headerLabel: UILabel, offsetHeaderStop: CGFloat, offsetLabelHeader: CGFloat, shrinkingButton: UIButton?, shrinkingButton2: UIButton?, mainTitle: UIView){
        let offset = scrollView.contentOffset.y + headerView.bounds.height
        var avatarTransform = CATransform3DIdentity
        var headerTransform = CATransform3DIdentity
        
        //Controls the image white overlay, when it shows and when it disappears
        let alignToNameLabel = -offset + mainTitle.frame.origin.y + headerView.frame.height + offsetHeaderStop
        headerBlurImageView?.alpha = min (1.0, (offset + 220 - alignToNameLabel)/(offsetLabelHeader + 50))

        // PULL DOWN -----------------
        if offset < 0 {
            let headerScaleFactor:CGFloat = -(offset) / headerView.bounds.height
            let headerSizevariation = ((headerView.bounds.height * (1.0 + headerScaleFactor)) - headerView.bounds.height)/2
            headerTransform = CATransform3DTranslate(headerTransform, 0, headerSizevariation, 0)
            headerTransform = CATransform3DScale(headerTransform, 1.0 + headerScaleFactor, 1.0 + headerScaleFactor, 0)
            
            // Hide views if scrolled super fast
            headerView.layer.zPosition = 0
            headerLabel.isHidden = true
        }
        // SCROLL UP/DOWN ------------
        else {
            //Header -----------
            headerTransform = CATransform3DTranslate(headerTransform, 0, max(-offsetHeaderStop, -offset), 0)
            
            //Label ------------
            headerLabel.isHidden = false
            headerLabel.frame.origin = CGPoint(x: headerLabel.frame.origin.x, y: max(alignToNameLabel, offsetLabelHeader + offsetHeaderStop))
            
            //Blur ------------
            if let navBar = self.navigationController?.navigationBar {
                if alignToNameLabel - offsetLabelHeader > 0 {
                    let scrollPercentage = Double(min (1.0, (offset)/(alignToNameLabel - offsetLabelHeader)))
                    navBar.tintColor = scrollColor(percent: scrollPercentage)
                }
            }
            
            //Avatar -----------
            var avatarScaleFactor = CGFloat(0)
            avatarScaleFactor = (min(offsetHeaderStop, offset)) / (shrinkingButton?.bounds.height ?? 1) / 9.4 // Slow down the animation
            let avatarSizeVariation = (1.0 + avatarScaleFactor) / 2.0
            avatarTransform = CATransform3DTranslate(avatarTransform, 0, avatarSizeVariation, 0)
            avatarTransform = CATransform3DScale(avatarTransform, 1.0 - avatarScaleFactor, 1.0 - avatarScaleFactor, 0)
            
            if offset <= offsetHeaderStop {
                headerView.layer.zPosition = 0
            } else {
                headerView.layer.zPosition = 2
            }
        }
        // Apply Transformations
        headerView.layer.transform = headerTransform
        shrinkingButton?.layer.transform = avatarTransform
        shrinkingButton2?.layer.transform = avatarTransform
    }
    
    func twitterParallaxHeaderSetup(headerBlurImageView: UIImageView?, headerImageView: UIImageView, headerView: UIView, headerLabel: UILabel) -> UIImageView? {
        var headerBlurImageView = headerBlurImageView
        
        //align header image to top
        headerImageView.translatesAutoresizingMaskIntoConstraints = false
        let topConstraint = NSLayoutConstraint(item: headerImageView, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: headerView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: headerImageView, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: headerView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0)
        let trailingConstraint = NSLayoutConstraint(item: headerImageView, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: headerView, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1, constant: 0)
        let leadingConstraint = NSLayoutConstraint(item: headerImageView, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: headerView, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1, constant: 0)
        headerView.addConstraints([topConstraint, bottomConstraint, trailingConstraint, leadingConstraint])
        
        //setup blur image, which creates the white navbar that appears as you scroll up
        headerBlurImageView = UIImageView(frame: view.bounds)
        headerBlurImageView?.backgroundColor = UIColor.white
        headerBlurImageView?.contentMode = UIView.ContentMode.scaleAspectFill
        headerBlurImageView?.alpha = 0.0
        headerView.clipsToBounds = true
        headerView.insertSubview(headerBlurImageView!, belowSubview: headerLabel)
        
        return headerBlurImageView
    }
    
    func finishKasamPress (kasamID: String, completion: @escaping (Bool) -> ()) {
        let popupImage = UIImage.init(icon: .fontAwesomeSolid(.rocket), size: CGSize(width: 30, height: 30), textColor: .white)
        showPopupConfirmation(title: "Finish & Unfollow?", description: "You'll be unfollowing this Kasam.\nYour past progress and badges will be saved.", image: popupImage, buttonText: "Finish & Unfollow", completion: {(success) in
            
            //STEP 1 - Remove notification
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [kasamID])
            
            //STEP 2 - MARK KASAM AS COMPLETED
            DBRef.userPersonalFollowing.child(kasamID).setValue(nil) {(error, reference) in
                completion(success)
            }
        })
    }
    
    //programatically switching tabBars
    func animateTabBarChange(tabBarController: UITabBarController, to viewController: UIViewController) {
        let fromView: UIView = tabBarController.selectedViewController!.view
        let toView: UIView = viewController.view
        if fromView != toView {
            UIView.transition(from: fromView, to: toView, duration: 0.3, options: [.transitionCrossDissolve], completion: nil)
        }
    }
    
    func alert(message: String, title: String = "") {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(OKAction)
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func setupNavBar(clean: Bool?){
        if clean == false {
            let logo = UIImage(named: "Kasam-logo")
            let imageView = UIImageView(image:logo)
            imageView.contentMode = .scaleAspectFit
            self.navigationItem.titleView = imageView
            
            self.navigationController?.navigationBar.layer.shadowColor = UIColor.colorFive.cgColor
            self.navigationController?.navigationBar.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
            self.navigationController?.navigationBar.layer.shadowRadius = 1.0
            self.navigationController?.navigationBar.layer.shadowOpacity = 0.5
            self.navigationController?.navigationBar.layer.masksToBounds = false
        }
        
        //Right Button
        let rightButton = UIButton()
        rightButton.setIcon(icon: .fontAwesomeSolid(.bars), iconSize: 20, color: UIColor.darkGray, backgroundColor: .clear, forState: .normal)
        rightButton.restorationIdentifier = "rightButton"
        rightButton.addTarget(self, action: #selector(showUserOptions), for: .touchUpInside)
        self.navigationController?.navigationBar.addSubview(rightButton)
        rightButton.tag = 1
        let targetView = self.navigationController?.navigationBar
        let trailingContraint = NSLayoutConstraint(item: rightButton, attribute: .trailingMargin, relatedBy: .equal, toItem: targetView, attribute: .trailingMargin, multiplier: 1.0, constant: -20)
        let yConstraint = NSLayoutConstraint(item: rightButton, attribute: .centerY, relatedBy: .equal, toItem: targetView, attribute: .centerY, multiplier: 1, constant: 0)
        rightButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([trailingContraint, yConstraint])
    }
    
    @objc func showUserOptions(button: UIButton){
        showBottomPopup(type: "userOptions", array: nil)
    }
    
    func getBlockVideo (url: String){
        guard let videoURL = URL(string: url) else { return }
        let player = AVPlayer(url: videoURL)
        let controller = AVPlayerViewController()
        controller.player = player
        present(controller, animated: true) {
            controller.player!.play()
        }
    }
    
    func getCurrentDate() -> String {
        let currentDateTime = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateFormat = "yyyy-MM-dd"                                     //***keep this value the same as below
        let finalDate = formatter.string(from: currentDateTime)
        return finalDate
    }
    
    func loginUser() {
        if Auth.auth().currentUser != nil {
            SavedData.userID = Auth.auth().currentUser!.uid
            DBRef.resetDBs()
            DBRef.currentUser.child("Type").observeSingleEvent(of: .value, with:{(snap) in
                SavedData.userType = snap.value as? String ?? "Basic"
            })
        }
    }
    
    func setHistoryTotal(kasamID: String, statusDate: String, value: Double) {
        if value > 0 {
            //Adding progress
            DBRef.userHistoryTotals.child(kasamID).observeSingleEvent(of: .value) {(snap) in
                if snap.exists() {
                    if let value = snap.value as? [String:Any] {
                        if value["Last"] as? String != statusDate {
                            if let daysCompleted = value["Days"] as? Int {DBRef.userHistoryTotals.child(kasamID).child("Days").setValue(daysCompleted + 1)}
                        }
                        else {DBRef.userHistoryTotals.child(kasamID).child("Days").setValue(1)}
                        if (value["First"] as? String) ?? Date().dateToString() >= statusDate {
                            DBRef.userHistoryTotals.child(kasamID).child("First").setValue(statusDate)
                        }
                        if value["Last"] as? String ?? Date().dateToString() <= statusDate {
                            DBRef.userHistoryTotals.child(kasamID).child("Last").setValue(statusDate)
                        }
                    }
                } else {
                    DBRef.userHistoryTotals.child(kasamID).setValue(["Days": 1, "First": statusDate, "Last": statusDate])
                }
            }
        } else {
            //Removing progress
            DBRef.userPersonalHistory.child(kasamID).child((SavedData.kasamDict[kasamID]?.joinedDate.dateToString())!).child(statusDate).setValue(nil)
            DBRef.userHistoryTotals.child(kasamID).observeSingleEvent(of: .value) {(snap) in
                if let value = snap.value as? [String:Any] {
                    if let daysCompleted = value["Days"] as? Int {
                        if daysCompleted == 1 {
                            DBRef.userHistoryTotals.child(kasamID).child("Days").setValue(nil)
                        } else {
                            DBRef.userHistoryTotals.child(kasamID).child("Days").setValue(daysCompleted - 1)
                        }
                    }
                    if value["First"] as? String == statusDate {DBRef.userHistoryTotals.child(kasamID).child("First").setValue(nil)}
                    if value["Last"] as? String == statusDate {
                        DBRef.userHistoryTotals.child(kasamID).child("Last").setValue(nil)
                        DBRef.userPersonalHistory.child(kasamID).child((SavedData.kasamDict[kasamID]?.joinedDate.dateToString())!).observeSingleEvent(of: .value) {(snap) in
                            if snap.exists() {
                                if let value = snap.value as? [String:Any] {
                                    let array = value.map { return $0.key }
                                    let lastDate = array[Int(snap.childrenCount) - 1]
                                    DBRef.userHistoryTotals.child(kasamID).child("Last").setValue(lastDate)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

extension UINavigationItem {
    override open func awakeFromNib() {
        super.awakeFromNib()
        
    //Customize the back button
        let backImage = UIImage(named: "back-button")
        UIGraphicsBeginImageContextWithOptions(CGSize(width: (backImage?.size.width ?? 0.0) + 20, height: backImage?.size.height ?? 0.0), _: false, _: 0)
        backImage?.draw(at: CGPoint(x: 10, y: 0))       // move the pic by 10, change it to the num you want
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        UINavigationBar.appearance().backIndicatorImage = finalImage
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = finalImage
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.clear], for: .normal)
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.clear], for: UIControl.State.highlighted)
        
    //Set the navigation bar title to gold and text color to white
        let navigationFont = UIFont.systemFont(ofSize: 20, weight: .semibold)
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.init(hex: 0x4b3b00), NSAttributedString.Key.font: navigationFont]
        UINavigationBar.appearance().barTintColor = UIColor.white
    }
}

extension AnimationView {
    func loadingAnimation(view: UIView, animation: String, width: Int, overlayView: UIView?, loop: Bool, buttonText: String?, completion: (() -> Void)?){
        var height = width
        let animationView = self
        animationView.animation = Animation.named(animation)
        animationView.contentMode = .scaleAspectFit
        
        //Overlay
        if overlayView != nil  {
            if let window = view.window {
                overlayView?.frame = window.frame
                overlayView?.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
                window.addSubview(overlayView!)
            }
        }
        view.addSubview(animationView)
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.centerXAnchor.constraint(lessThanOrEqualTo: view.centerXAnchor).isActive = true
        animationView.centerYAnchor.constraint(lessThanOrEqualTo: view.centerYAnchor).isActive = true
        NSLayoutConstraint(item: animationView, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: CGFloat(width)).isActive = true
        animationView.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        animationView.play()
        
        //Bottom Button
        if buttonText != nil {
            let iconButton:UIButton = UIButton()
            iconButton.backgroundColor = .colorFour
            self.addSubview(iconButton)
            iconButton.setTitle("    \(buttonText!)    ", for: .normal)
            iconButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
            iconButton.translatesAutoresizingMaskIntoConstraints = false
            iconButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
            iconButton.layer.cornerRadius = 20
            iconButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0).isActive = true
            iconButton.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
            iconButton.addTarget(self, action: #selector(goToDiscover), for: .touchUpInside)
            height += 80
        }
        NSLayoutConstraint(item: animationView, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: CGFloat(height)).isActive = true
        
        //Loop
        if loop == true {
            animationView.loopMode = .loop
        } else if completion != nil {
            animationView.play{(finished) in
                completion!()
            }
        }
    }
    
    @objc func goToDiscover(){
        NotificationCenter.default.post(name: Notification.Name(rawValue: "GoToDiscover"), object: self)
    }
}

extension UIButton {
    func setKasamTypeIcon (kasamType: String, button: UIButton, location: String) -> UIButton {
        var iconColor = UIColor.darkGray
        var iconSize = CGFloat(15)
        var background = UIColor.clear
        switch location {
            case "discover": iconColor = UIColor.white; background = UIColor.colorFour; button.layer.cornerRadius = button.frame.width / 2; iconSize = 15
            case "options": iconColor = UIColor.white; background = UIColor.colorFour; button.layer.cornerRadius = button.frame.width / 2; iconSize = 20
            default: iconColor = UIColor.darkGray
        }
        
        switch kasamType {
            case Assets.levelsArray[0]: button.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight:.regular), prefixTextColor: UIColor.white, icon: .fontAwesomeSolid(.chessPawn), iconColor: iconColor, postfixText: "", postfixTextFont: UIFont.systemFont(ofSize: 15, weight:.medium), postfixTextColor: UIColor.white, backgroundColor: background, forState: .normal, iconSize: iconSize)
            case Assets.levelsArray[1]: button.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight:.regular), prefixTextColor: UIColor.white, icon: .fontAwesomeSolid(.chessKnight), iconColor: iconColor, postfixText: "", postfixTextFont: UIFont.systemFont(ofSize: 15, weight:.medium), postfixTextColor: UIColor.white, backgroundColor: background, forState: .normal, iconSize: iconSize)
            case Assets.levelsArray[2]: button.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight:.regular), prefixTextColor: UIColor.white, icon: .fontAwesomeSolid(.chessRook), iconColor: iconColor, postfixText: "", postfixTextFont: UIFont.systemFont(ofSize: 15, weight:.medium), postfixTextColor: UIColor.white, backgroundColor: background, forState: .normal, iconSize: iconSize)
            case "Fitness": button.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight:.regular), prefixTextColor: UIColor.white, icon: .fontAwesomeSolid(.dumbbell), iconColor: iconColor, postfixText: "", postfixTextFont: UIFont.systemFont(ofSize: 15, weight:.medium), postfixTextColor: UIColor.white, backgroundColor: background, forState: .normal, iconSize: iconSize)
            case "Personal": button.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight:.regular), prefixTextColor: UIColor.white, icon: .fontAwesomeSolid(.seedling), iconColor: iconColor, postfixText: "", postfixTextFont: UIFont.systemFont(ofSize: 15, weight:.medium), postfixTextColor: UIColor.white, backgroundColor: background, forState: .normal, iconSize: iconSize)
            case "Health": button.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight:.regular), prefixTextColor: UIColor.white, icon: .fontAwesomeSolid(.heart), iconColor: iconColor, postfixText: "", postfixTextFont: UIFont.systemFont(ofSize: 15, weight:.medium), postfixTextColor: UIColor.white, backgroundColor: background, forState: .normal, iconSize: iconSize)
            case "Spiritual": button.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight:.regular), prefixTextColor: UIColor.white, icon: .fontAwesomeSolid(.spa), iconColor: iconColor, postfixText: "", postfixTextFont: UIFont.systemFont(ofSize: 15, weight:.medium), postfixTextColor: UIColor.white, backgroundColor: background, forState: .normal, iconSize: iconSize)
            case "Writing": button.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight:.regular), prefixTextColor: UIColor.white, icon: .fontAwesomeSolid(.book), iconColor: iconColor, postfixText: "", postfixTextFont: UIFont.systemFont(ofSize: 15, weight:.medium), postfixTextColor: UIColor.white, backgroundColor: background, forState: .normal, iconSize: iconSize)
            case "Question": button.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight:.regular), prefixTextColor: UIColor.white, icon: .fontAwesomeSolid(.question), iconColor: iconColor, postfixText: "", postfixTextFont: UIFont.systemFont(ofSize: 15, weight:.medium), postfixTextColor: UIColor.white, backgroundColor: background, forState: .normal, iconSize: iconSize)
            default: button.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight:.regular), prefixTextColor: UIColor.white, icon: .fontAwesomeSolid(.dumbbell), iconColor: iconColor, postfixText: "", postfixTextFont: UIFont.systemFont(ofSize: 15, weight:.medium), postfixTextColor: UIColor.white, backgroundColor: background, forState: .normal, iconSize: iconSize)
        }
        return button
    }
}

extension Double {
    func removeZerosFromEnd() -> String {
        let formatter = NumberFormatter()
        let number = NSNumber(value: self)
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 16 //maximum digits in Double after dot (maximum precision)
        return String(formatter.string(from: number) ?? "")
    }
}

class NumberedTextView: UITextView {
    override func willMove(toSuperview newSuperview: UIView?) {
        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidChange), name: UITextView.textDidChangeNotification, object: nil)
    }
    
    @objc func textViewDidChange(notification: Notification) {
        var lines: [String] = []
        for (index, line) in text.components(separatedBy: .newlines).enumerated() {
            if !line.hasPrefix("\(index.advanced(by: 1))") &&
                !line.trimmingCharacters(in: .whitespaces).isEmpty {
                lines.append("\(index.advanced(by: 1)). " + line)
            } else {
                lines.append(line)
            }
        }
        text = lines.joined(separator: "\n")
        // this prevents two empty lines at the bottom
        if text.hasSuffix("\n\n") {
            text = String(text.dropLast())
        }
    }
}

class BulletedTextView: UITextView {
    override func willMove(toSuperview newSuperview: UIView?) {
        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidChange), name: UITextView.textDidChangeNotification, object: nil)
    }
    
    @objc func textViewDidChange(notification: Notification) {
        var lines: [String] = []
        for (_, line) in text.components(separatedBy: .newlines).enumerated() {
            if !line.hasPrefix("\u{2022} ") && !line.trimmingCharacters(in: .whitespaces).isEmpty {
                if line.hasPrefix("\u{2022}") {
                    //To prevent user from removing space after bullet point
                } else {
                    lines.append("\u{2022} " + line)
                }
            }
            else {
                lines.append(line)
            }
        }
        text = lines.joined(separator: "\n")
        if text.hasSuffix("\n\n") {text = String(text.dropLast())}      // This prevents two empty lines at the bottom
    }
}

extension Date {
    func dayOfWeek() -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"                                       //gets the day, e.g. "Wednesday"
        return dateFormatter.string(from: self).capitalized
    }
    
    func dayNumberOfWeek() -> Int? {
        let dayNo = Calendar.current.dateComponents([.weekday], from: self).weekday!
        if  dayNo != 1 {
            return dayNo - 1
        } else {
            return dayNo + 6
        }
    }
    
    static func dates(from fromDate: Date, to toDate: Date) -> [Date] {
        var dates: [Date] = []
        var date = fromDate

        while date <= toDate {
            dates.append(date)
            guard let newDate = Calendar.current.date(byAdding: .day, value: 1, to: date) else { break }
            date = newDate
        }
        return dates
    }
    
    func dateToString() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateFormat = "yyyy-MM-dd"
        let finalDate = formatter.string(from: self)
        return finalDate
    }
    
    func dateToShortString() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateFormat = "MMM d"
        let finalDate = formatter.string(from: self)
        return finalDate
    }
}

extension UIView {
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}

extension UICollectionViewCell {
    func getCurrentDateTime() -> String? {
        let currentDateTime = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .long
        let finalDate = formatter.string(from: currentDateTime)
        return finalDate
    }
    
    func dateShortestFormat(date: Date) -> String {
        let date = date
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateFormat = "MMM d"
        let finalDate = formatter.string(from: date)
        return finalDate
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(red: (rgb >> 16) & 0xFF, green: (rgb >> 8) & 0xFF, blue: rgb & 0xFF)
    }
    
    var isDarkColor: Bool {
        var r, g, b, a: CGFloat
        (r, g, b, a) = (0, 0, 0, 0)
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        let lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return  lum < 0.50 ? true : false
    }
    
    var lighter: UIColor {
        var r:CGFloat = 0, g:CGFloat = 0, b:CGFloat = 0, a:CGFloat = 0
        if self.getRed(&r, green: &g, blue: &b, alpha: &a){
            return UIColor(red: min(r + 0.2, 1.0), green: min(g + 0.2, 1.0), blue: min(b + 0.2, 1.0), alpha: a)
        }
        return UIColor()
    }
    
    var darker: UIColor {
        var r:CGFloat = 0, g:CGFloat = 0, b:CGFloat = 0, a:CGFloat = 0
        if self.getRed(&r, green: &g, blue: &b, alpha: &a){
            return UIColor(red: max(r - 0.2, 0.0), green: max(g - 0.2, 0.0), blue: max(b - 0.2, 0.0), alpha: a)
        }
        return UIColor()
    }
}

extension CGImage {
    var isDark: Bool {
        get {
            guard let imageData = self.dataProvider?.data else { return false }
            guard let ptr = CFDataGetBytePtr(imageData) else { return false }
            let length = CFDataGetLength(imageData)
            let threshold = Int(Double(self.width * self.height) * 0.45)
            var darkPixels = 0
            for i in stride(from: 0, to: length, by: 4) {
                let r = ptr[i]
                let g = ptr[i + 1]
                let b = ptr[i + 2]
                let luminance = (0.299 * Double(r) + 0.587 * Double(g) + 0.114 * Double(b))
                if luminance < 150 {
                    darkPixels += 1
                    if darkPixels > threshold {
                        return true
                    }
                }
            }
            return false
        }
    }
}

extension UIImage {
    var isDark: Bool {
        get {
            return self.cgImage?.isDark ?? false
        }
    }
}

extension String {
    func initials () -> String {
        return self.components(separatedBy: " ").reduce("") { ($0 == "" ? "" : "\($0.first!)") + "\($1.first!)" }
    }
    
    func stringToDate() -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let kasamDate = dateFormatter.date(from: self) ?? Date()
        return kasamDate
    }
    
    func shortDateToLongDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: self)
        dateFormatter.dateFormat = "MMM d, yyyy"
        return  dateFormatter.string(from: date!)
    }
    
    func longDateToShort() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from:self)
        dateFormatter.dateFormat = "MMM dd"
        return dateFormatter.string(from: date ?? Date())
    }
    
    func stringToTime () -> (hour: Int, minute: Int) {
        let dateAsString = self
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        let date = dateFormatter.date(from: dateAsString)
        return (Calendar.current.component(.hour, from: date!), Calendar.current.component(.minute, from: date!))
    }
    
    func restartExistingNotification() {
        let kasamID = self
        let kasam = SavedData.kasamDict[kasamID]
        let startDate = kasam!.joinedDate
        var endDate: Date?
        if kasam?.repeatDuration != 0 {
            endDate = Calendar.current.date(byAdding: .day, value: kasam!.repeatDuration, to: startDate)!
        }
        kasamID.setupNotifications(kasamName: kasam!.kasamName, startDate: Date(), endDate: endDate, chosenTime: kasam!.startTime)
    }
    
    func setupNotifications(kasamName: String, startDate: Date, endDate: Date?, chosenTime: String) {
        // Ask permission for notifications
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) {(granted, error) in
            if granted {
                //Permission granted
            } else {
                //Permission denied
            }
        }
        let content = UNMutableNotificationContent()
        content.title = "\(kasamName) Reminder"
        content.body = "Time to get cracking on your '\(kasamName)' Kasam"
        content.categoryIdentifier = "\(kasamName) \(startDate) \(chosenTime)"
        content.sound = UNNotificationSound.default
        content.userInfo = ["example": "information"] // You can retrieve this when displaying notification
        
        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: startDate)
        dateComponents.hour = chosenTime.stringToTime().hour
        dateComponents.minute = chosenTime.stringToTime().minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create request
        let uniqueID = "\(self)"        // Keep a record of this
        let request = UNNotificationRequest(identifier: uniqueID, content: content, trigger: trigger)
        center.add(request) {(error : Error?) in        // Add the notification request
        }
    }
    
    func benefitThresholds() {
        DBRef.coachKasams.child(self).child("Thresholds").observeSingleEvent(of: .value) {(snap) in
            if let value = snap.value as? [String:String] {
                SavedData.kasamDict[self]?.benefitsThresholds = []
                for benefit in value {
                    SavedData.kasamDict[self]?.benefitsThresholds?.append((Int(benefit.key)!, benefit.value))
                }
                SavedData.kasamDict[self]?.benefitsThresholds = SavedData.kasamDict[self]?.benefitsThresholds!.sorted(by: { $0.0 < $1.0 })
            }
        }
    }
    
    func MD5() -> String {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        let messageData = self.data(using:.utf8)!
        var digestData = Data(count: length)

        _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
            messageData.withUnsafeBytes { messageBytes -> UInt8 in
                if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                    let messageLength = CC_LONG(messageData.count)
                    CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
                }
                return 0
            }
        }
        return digestData.map { String(format: "%02hhx", $0) }.joined()
    }
}

extension UIImage {
    func resizeTopAlignedToFill(newWidth: CGFloat) -> UIImage? {
        let newHeight = size.height
        let newSize = CGSize(width: newWidth, height: newHeight)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, UIScreen.main.scale)
        draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

extension TimeInterval{
    func stringFromTimeInterval() -> String {
        let time = NSInteger(self)
        let ms = Int((self.truncatingRemainder(dividingBy: 1)) * 1000)
        let seconds = time % 60
        let minutes = (time / 60) % 60
        let hours = (time / 3600)
        return String(format: "%0.2d:%0.2d:%0.2d.%0.3d",hours,minutes,seconds,ms)
    }
}

extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}

extension UIView{
    func roundedLeft(){
        let maskPath1 = UIBezierPath(roundedRect: bounds, byRoundingCorners: [.topLeft , .bottomLeft], cornerRadii: CGSize(width: 8, height: 8))
        let maskLayer1 = CAShapeLayer()
        maskLayer1.frame = bounds
        maskLayer1.path = maskPath1.cgPath
        layer.mask = maskLayer1
    }
    
    func roundedRight(){
        let maskPath1 = UIBezierPath(roundedRect: bounds, byRoundingCorners: [.topRight , .bottomRight], cornerRadii: CGSize(width: 8, height: 8))
        let maskLayer1 = CAShapeLayer()
        maskLayer1.frame = bounds
        maskLayer1.path = maskPath1.cgPath
        layer.mask = maskLayer1
    }
    
    func fadeIn(withDuration duration: TimeInterval = 0.5) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 1.0
        })
    }
    
    func fadeOut(withDuration duration: TimeInterval = 0.5) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0.0
        })
    }
    
    func rotate(_ toValue: CGFloat, duration: CFTimeInterval = 0.2) {
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.toValue = toValue
        animation.duration = duration
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards
        self.layer.add(animation, forKey: nil)
    }
}

extension Double {
    // Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

extension BidirectionalCollection where Element: StringProtocol {
    var sentence: String {
        guard let last = last else { return "" }
        return count <= 2 ? joined(separator: " and ") :
            dropLast().joined(separator: ", ") + ", and " + last
    }
    
    var list: String {
        return joined(separator: "\n")
    }
    
    var dayArraySentence: String {
        guard let last = last else { return "" }
        if count == 3 {
            return count > 3 ? joined(separator: ", ") :
            dropLast().joined(separator: ", ") + " and " + last
        } else {
            return count <= 2 ? joined(separator: " and ") :
            dropLast().joined(separator: ", ") + "..." + last
        }
    }
}

extension Int {
    func convertIntTimeToSplitInt(fullIntTime: Int) -> (hours: Int, mins: Int, secs: Int) {
        let hours = fullIntTime / 3600
        let mins = fullIntTime / 60 % 60
        let secs = fullIntTime % 60
        return (hours: hours, mins: mins, secs: secs)
    }
    
    func pluralUnit(unit: String) -> String {
        if self == 1 {
            return "\(self) \(unit)"
        } else {
            return "\(self) \(unit)s"
        }
    }
    
    func nearestElement(array : [(Int,String)]) -> (Int,String)? {
        var result = ""
        for value in array {
            if value.0 > self {break}
            result = value.1
        }
        return (self, result)
    }
}

class CustomUISlider : UISlider {
    @IBInspectable open var trackHeight:CGFloat = 2 {
        didSet {setNeedsDisplay()}
    }
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        //keeps original origin and width, changes height, you get the idea
        let defaultBounds = super.trackRect(forBounds: bounds)
        return CGRect(
            x: defaultBounds.origin.x,
            y: defaultBounds.origin.y + defaultBounds.size.height/2 - trackHeight/2,
            width: defaultBounds.size.width,
            height: trackHeight
        )
    }
    
    override func awakeFromNib() {
        self.setThumbImage(UIImage(named: "kasam-timer-button"), for: .normal)
        super.awakeFromNib()
    }
}

extension UIPageViewController {
    func goToNextPage(animated: Bool = true, completion: ((Bool) -> Void)? = nil) {
        if let currentViewController = viewControllers?[0] {
            if let nextPage = dataSource?.pageViewController(self, viewControllerAfter: currentViewController) {
                setViewControllers([nextPage], direction: .forward, animated: animated, completion: completion)
            }
        }
    }
}

extension UILabel {
    func calculateMaxLines() -> Int {
        let maxSize = CGSize(width: frame.size.width, height: CGFloat(Float.infinity))
        let charSize = font.lineHeight
        let text = (self.text ?? "") as NSString
        let textSize = text.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        let linesRoundedUp = Int(ceil(textSize.height/charSize))
        return linesRoundedUp
    }
}

extension AuthErrorCode {
    var errorMessage: String {
        switch self {
        case .emailAlreadyInUse:
            return "The email is already in use with another account"
        case .userNotFound:
            return "Account not found for the specified user. Please check and try again"
        case .userDisabled:
            return "Your account has been disabled. Please contact support."
        case .invalidEmail, .invalidSender, .invalidRecipientEmail:
            return "Please enter a valid email"
        case .networkError:
            return "Network error. Please try again."
        case .weakPassword:
            return "Your password is too weak. The password must be 6 characters long or more."
        case .wrongPassword:
            return "Your password is incorrect. Please try again or use 'Forgot password' to reset your password"
        case .accountExistsWithDifferentCredential:
            return "An account already exists with the same email address but different sign-in credentials. Sign in using a provider associated with this email address."
        default:
            return "Unknown error occurred"
        }
    }
}

extension UITableViewCell {
    func getCurrentDate() -> String? {
        let currentDateTime = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateFormat = "yyyy-MM-dd"                                     
        let finalDate = formatter.string(from: currentDateTime)
        return finalDate
    }
}

class PassThroughView: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews {
            if !subview.isHidden && subview.isUserInteractionEnabled && subview.point(inside: convert(point, to: subview), with: event) {
                return true
            }
        }
        return false
    }
}

extension NSLayoutConstraint {
    func constraintWithMultiplier(_ multiplier: CGFloat, view: UIView) -> NSLayoutConstraint {
        let newConstraint = NSLayoutConstraint(item: self.firstItem!, attribute: self.firstAttribute, relatedBy: self.relation, toItem: self.secondItem, attribute: self.secondAttribute, multiplier: multiplier, constant: self.constant)
        view.removeConstraint(self)
        view.addConstraint(newConstraint)
        view.layoutIfNeeded()
        return newConstraint
    }
}
