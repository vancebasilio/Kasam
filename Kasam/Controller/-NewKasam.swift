//
//  NewKasamController.swift
//  Kasam 1.0
//
//  Created by Vance Basilio on 2019-04-23.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAnalytics
import FirebaseStorage
import SwiftEntryKit
import SkyFloatingLabelTextField
import Lottie

class NewKasamController: UIViewController, UIScrollViewDelegate, UITextViewDelegate {
    
    //Twitter Parallax
    @IBOutlet weak var tableView: UITableView!  {didSet {tableView.estimatedRowHeight = 100}}
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerViewHeight: NSLayoutConstraint!
    @IBOutlet weak var profileView: UIView!
    @IBOutlet weak var profileViewRadius: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    
    @IBOutlet weak var trackingProgressLabel: UILabel!
    @IBOutlet weak var metricTypeCollection: UICollectionView!
    @IBOutlet weak var metricTypeCollectionHeight: NSLayoutConstraint!
    @IBOutlet weak var headerClickViewHeight: NSLayoutConstraint!
    @IBOutlet weak var newKasamTitle: SkyFloatingLabelTextField!
    @IBOutlet weak var newkasamDescriptionLine: SkyFloatingLabelTextField!
    @IBOutlet weak var newKasamDescription: UITextView!
    @IBOutlet weak var newKasamDescriptionCount: UILabel!
    @IBOutlet weak var benefitsTextView: UITextView!
    @IBOutlet weak var benefitsLine: SkyFloatingLabelTextField!
    @IBOutlet weak var addAnImageLabel: UILabel!
    @IBOutlet weak var createActivitiesCircle: UIButton!
    @IBOutlet weak var headerClickView: UIView!
    @IBOutlet weak var createActivitiesLabel: UILabel!
    @IBOutlet weak var newCategoryIcon: UIButton!
    @IBOutlet weak var newCategoryView: UIView!
    @IBOutlet weak var newCategoryChosenLabel: UILabel!
    @IBOutlet weak var deleteKasamButton: UIButton!
    
    var kasamIDforHolder = ""
    var imagePicker: UIImagePickerController!
    var headerBlurImageView: UIImageView!
    var headerImageView: UIImageView!
    var saveCategoryObserver: NSObjectProtocol?
    let animationView = AnimationView()
    let animationOverlay = UIView()
    
    //edit Kasam
    var kasamDatabase = DBRef.userKasams
    var personalKasamBlocksDatabase = DBRef.userKasams
    var blockDuration = [Int:String]()
    var basicKasam = false                  //loaded in
    var userKasam = true                    //change in the future to load in for professional kasams
    var kasamHolderKasamEdit = false        //loaded in
    
    let categoryDefault = "Category (tap to select)"
    let benefitsDefault = "\u{2022} E.g. Improved Endurance"
    
    //No of Blocks Picker Variables
    var numberOfBlocks = 1
    var transferTitle = [Int:String]()
    var transferBlockType = [Int:String]()
    var transferDuration = [Int:String]()
    var transferDurationMetric = [Int:String]()
    var tempBlockNoSelected = 1
    
    //New Kasam Picker Variables
    var chosenLevel = ""            //removed for personal kasams, will include for professional ones
    
    //Metrics
    let metricsArray = ["Count", "Completion", "Timer"]
    let chosenMetricOptions = ["Reps", "Checkmark", "Timer"]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLoad()
        setupTwitterParallax()
        newKasamDescription.delegate = self
        benefitsTextView.delegate = self
    }
    
    func setupLoad(){
        if userKasam == false {
            kasamDatabase = DBRef.coachKasams
            personalKasamBlocksDatabase = DBRef.coachKasams
        } else {
            kasamDatabase = DBRef.userKasams
            personalKasamBlocksDatabase = DBRef.coachKasams
        }
        let backButtonBasicKasam = NSNotification.Name("BackButtonBasicKasam")
        NotificationCenter.default.addObserver(self, selector: #selector(NewKasamController.backButtonBasicKasam), name: backButtonBasicKasam, object: nil)
        
        //When click header, image picker popsup
        headerClickView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showBottomImagePicker)))
        
        //Setup radius for kasam info block
        self.hideKeyboardWhenTappedAround()
        profileViewRadius.layer.cornerRadius = 16.0
        profileViewRadius.clipsToBounds = true
        
        createActivitiesCircle.layer.cornerRadius = createActivitiesCircle.frame.height / 2
        createActivitiesCircle.clipsToBounds = true
        if basicKasam == true {
            trackingProgressLabel.text = "Benefits:"
            createActivitiesCircle.setIcon(icon: .fontAwesomeSolid(.featherAlt), iconSize: 27, color: UIColor.white, backgroundColor: UIColor.black, forState: .normal)
            self.metricTypeCollection.isHidden = true
            self.benefitsTextView.isHidden = false
            self.benefitsLine.isHidden = false
            DispatchQueue.main.async {
                self.metricTypeCollection.selectItem(at: IndexPath(item: 1, section: 0), animated: false, scrollPosition: [.centeredHorizontally])
                self.collectionView(self.metricTypeCollection, didSelectItemAt : IndexPath(item: 1, section: 0))
            }
        } else {
            trackingProgressLabel.text = "Metric:"
            createActivitiesLabel.text = "Edit Activities"
            createActivitiesCircle.setIcon(icon: .fontAwesomeSolid(.arrowRight), iconSize: 25, color: UIColor.white, backgroundColor: UIColor.black, forState: .normal)
            self.metricTypeCollection.isHidden = false
            self.benefitsTextView.isHidden = true
            self.benefitsLine.isHidden = true
            DispatchQueue.main.async {
                self.metricTypeCollection.selectItem(at: IndexPath(item: 1, section: 0), animated: false, scrollPosition: [.centeredHorizontally])
                self.collectionView(self.metricTypeCollection, didSelectItemAt : IndexPath(item: 1, section: 0))
            }
        }
        newKasamDescription.textContainer.maximumNumberOfLines = 3
        newKasamDescription.textContainer.lineBreakMode = .byClipping
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 10
        newKasamDescription.attributedText = NSAttributedString(string: "Description", attributes:[NSAttributedString.Key.paragraphStyle : style, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15.5, weight: UIFont.Weight.medium), NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        benefitsTextView.attributedText = NSAttributedString(string: benefitsDefault, attributes:[NSAttributedString.Key.paragraphStyle : style, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.medium), NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(categoryOptions))
        newCategoryView.addGestureRecognizer(tap)
        
        self.headerImageView = UIImageView(frame: self.headerView.bounds)
        self.headerImageView?.contentMode = UIView.ContentMode.scaleAspectFill
        self.headerImageView?.image = PlaceHolders.kasamHeaderPlaceholderImage
        self.headerView.insertSubview(self.headerImageView, belowSubview: self.headerLabel)
        
        if NewKasam.editKasamCheck == true {
            loadKasam()
            headerLabel.text = "Edit Kasam"
            addAnImageLabel.text = "Change Image"
            if basicKasam == true {
                createActivitiesLabel.text = "Update Kasam"
                deleteKasamButton.layer.cornerRadius = deleteKasamButton.frame.height / 2
                deleteKasamButton.setIcon(icon: .fontAwesomeSolid(.trashAlt), iconSize: 20, color: UIColor.white, backgroundColor: .cancelColor, forState: .normal)
                deleteKasamButton.isHidden = false
            }
        } else {
            deleteKasamButton.isHidden = true
            if basicKasam == true {
                createActivitiesLabel.text = "Save Kasam"
            }
            newCategoryIcon = newCategoryIcon.setKasamTypeIcon(kasamType: "Question", button: newCategoryIcon, location: "options")
        }
    }
    
    @objc func categoryOptions(){
        dismissKeyboard()
        showBottomTablePopup(type: "categoryOptions", programKasamArray: nil)
        saveCategoryObserver = NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "SaveCategory"), object: nil, queue: OperationQueue.main) {(notification) in
            let categoryVC = notification.object as! TablePopupController
            self.newCategoryChosenLabel.text = categoryVC.categoryChosen
            self.newCategoryChosenLabel.textColor = .darkGray
            self.newCategoryIcon = self.newCategoryIcon.setKasamTypeIcon(kasamType: self.newCategoryChosenLabel.text!, button: self.newCategoryIcon, location: "options")
            NotificationCenter.default.removeObserver(self.saveCategoryObserver as Any)
        }
    }
    
    @objc func backButtonBasicKasam(){
        var level = 2
        //OPTION 1 - EDITING A KASAM
        if NewKasam.editKasamCheck == true {
            if newKasamTitle.text == NewKasam.kasamName && newKasamDescription.text == NewKasam.kasamDescription && benefitsTextView.text == NewKasam.benefits && self.newCategoryChosenLabel.text == NewKasam.chosenGenre {
                self.navigationController?.popToRootViewController(animated: true)
                level = 3           //editing kasam, but no info changed
            } else {
                level = 2           //info changed
            }
        } else {
        //OPTION 2 - NEW KASAM
            if newKasamTitle.text == "" && newKasamDescription.text == "Description" && benefitsTextView.text == benefitsDefault && self.newCategoryChosenLabel.text == categoryDefault {
                level = 1           //no fields filled
            } else {
                level = 2           //partial info added
            }
        }
        if level != 3 {
            showCenterSaveKasamPopup(level: level) {(result) in
                if result == 0 {DispatchQueue.main.async {self.saveBasicKasam()}}                  //saveButton
                else if result == 1 {self.dismiss(animated: true, completion: nil)}                //keepEditing
                else {self.dismiss(animated: true, completion: nil)}                               //discard
            }
        }
    }
    
    @IBAction func createActivitiesButtonPressed(_ sender: Any) {
        if basicKasam == true {
            saveBasicKasam()
        } else {
            if newKasamTitle.text == "" || newKasamDescription.text == "" || NewKasam.chosenMetric == "" {
                //there are missing fields that need to be filled
                var missingFields: [String] = []
                if newKasamTitle.text == "" {missingFields.append("Title")}
                if newKasamDescription.text == "" {missingFields.append("Description")}
                if NewKasam.chosenMetric == "" {missingFields.append("Tracking Metric")}
                let description = "Please fill out the Kasam \(missingFields.sentence)"
                floatCellSelected(title: "Missing Fields", description: description)
            } else {
                NewKasam.kasamName = newKasamTitle.text ?? "Kasam Title"
                NewKasam.kasamDescription = newKasamDescription.text ?? "Kasam Description"
                NotificationCenter.default.post(name: Notification.Name(rawValue: "GoToNext"), object: self)
            }
        }
    }
    
    func saveBasicKasam(){
        if newKasamTitle.text == "" || newKasamDescription.text == "Description" || benefitsTextView.text == "\u{2022} E.g. Improved Endurance" || self.newCategoryChosenLabel.text == categoryDefault {
            //There are missing fields that need to be filled
            var missingFields: [String] = []
            if newKasamTitle.text == "" {missingFields.append("Title")}
            if newKasamDescription.text == "Description" {missingFields.append("Description")}
            if benefitsTextView.text == benefitsDefault {missingFields.append("Benefits")}
            if newCategoryChosenLabel.text == categoryDefault {missingFields.append("Category")}
            let description = "\(missingFields.list)"
            let popupImage = UIImage.init(icon: .fontAwesomeSolid(.cookieBite), size: CGSize(width: 30, height: 30), textColor: .colorFour)
            missingFieldsPopup(title: "Missing Fields:", description: description, image: popupImage, buttonText: "Got it")
        } else {
            NewKasam.kasamName = newKasamTitle.text ?? ""
            let tempArray = benefitsTextView.text.components(separatedBy: "\n")
            var benefitsArray = [String]()
            for benefits in tempArray {
                benefitsArray.append(benefits.replacingOccurrences(of: "\u{2022} ", with: "", options: NSString.CompareOptions.literal, range: nil))
            }
            NewKasam.benefits = benefitsArray.joined(separator:";")
            NewKasam.chosenGenre = self.newCategoryChosenLabel.text!
            NewKasam.kasamDescription = newKasamDescription.text
            NewKasam.chosenMetric = "Checkmark"
            if self.headerImageView.image != PlaceHolders.kasamHeaderPlaceholderImage {
                NewKasam.kasamImageToSave = self.headerImageView.image!
            }
            self.animationView.loadingAnimation(view: view, animation: "rocket-fast", width: 200, overlayView: self.animationOverlay, loop: true, buttonText: nil, completion: nil)
            createKasam(existingKasamID: NewKasam.kasamID, basicKasam: true, userKasam: userKasam) {(returnKasamID) in
                if returnKasamID != nil {
                    print("Successfully created kasam")
                    self.animationView.removeFromSuperview()
                    self.animationOverlay.removeFromSuperview()
                    DBRef.userPersonalFollowing.child(returnKasamID!).updateChildValues(["Kasam Name" : NewKasam.kasamName, "Date Joined": Date().dateToString(), "Repeat": 30, "Metric": NewKasam.chosenMetric, "User Kasam": true])
                    Analytics.logEvent("following_Kasam", parameters: ["kasam_name": NewKasam.kasamName])
                    if self.kasamHolderKasamEdit == false {self.dismiss(animated: true, completion: nil)}
                    else {self.navigationController?.popViewController(animated: true)}
                    self.kasamIDforHolder = NewKasam.kasamID
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToKasamHolder" {
            let kasamTransferHolder = segue.destination as! KasamHolder
            kasamTransferHolder.kasamID = kasamIDforHolder
            kasamTransferHolder.userKasam = userKasam
        }
    }
    
    @IBAction func deleteKasamButtonPressed(_ sender: Any) {
        deleteUserKasam {(success) in
            if success == true {
                if self.kasamHolderKasamEdit == false {self.dismiss(animated: true, completion: nil)}
                else {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "ShowCompletionAnimation"), object: self)
                    //Go back two view controllers
                    self.tabBarController?.tabBar.isHidden = false
                    self.tabBarController?.tabBar.isTranslucent = false
                    self.navigationController?.navigationBar.isTranslucent = false
                    if self.navigationController?.navigationBar.subviews != nil {
                        for subview in self.navigationController!.navigationBar.subviews {
                            if subview.restorationIdentifier == "rightButton" {subview.isHidden = false}
                        }
                    }
                    let viewControllers: [UIViewController] = self.navigationController!.viewControllers as [UIViewController]
                    self.navigationController!.popToViewController(viewControllers[viewControllers.count - 3], animated: true)
                }
            }
        }
    }
    
    //Prevents more than xx characters and return button
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView == newKasamDescription {
            let numberOfChars = (textView.text as NSString).replacingCharacters(in: range, with: text).count
            newKasamDescriptionCount.text = "\(numberOfChars)/120"
            guard text.rangeOfCharacter(from: CharacterSet.newlines) == nil else {return false}     //prevents return key
            return numberOfChars < 120
        } else {
            let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
            var textWidth = textView.frame.inset(by: textView.textContainerInset).width
            textWidth -= 2.0 * textView.textContainer.lineFragmentPadding
            let boundingRect = sizeOfString(string: newText, constrainedToWidth: Double(textWidth), font: textView.font!)
            let numberOfLines = boundingRect.height / textView.font!.lineHeight
            return numberOfLines <= 5
        }
    }
    
    func sizeOfString (string: String, constrainedToWidth width: Double, font: UIFont) -> CGSize {
        return (string as NSString).boundingRect(with: CGSize(width: width, height: Double.greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil).size
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView == newKasamDescription && newKasamDescription.text == "Description" {
            newkasamDescriptionLine.isSelected = true
            newKasamDescription.text = nil
            newKasamDescription.textColor = UIColor.darkGray
            newKasamDescriptionCount.isHidden = false
        } else if textView == benefitsTextView && benefitsTextView.text == benefitsDefault {
            benefitsLine.isSelected = true
            benefitsTextView.text = nil
            benefitsTextView.textColor = UIColor.darkGray
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView == newKasamDescription && newKasamDescription.text.isEmpty {
            newkasamDescriptionLine.isSelected = false
            newKasamDescription.text = "Description"
            newKasamDescription.textColor = UIColor.lightGray
            newKasamDescriptionCount.isHidden = true
        } else if textView == benefitsTextView && benefitsTextView.text.isEmpty {
            benefitsLine.isSelected = false
            benefitsTextView.text = benefitsDefault
            benefitsTextView.textColor = UIColor.lightGray
        }
    }
    
    //NAVIGTION-------------------------------------------------------------------------------------------------------------------
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.backgroundColor = UIColor.clear            //set navigation bar color to clear
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.tintColor = UIColor.white                  //change back arrow color to white
    }
    
    @objc func dismissView(){
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    //Twitter Parallax-------------------------------------------------------------------------------------------------------------------
    
    let headerHeight = UIScreen.main.bounds.width * 0.55        //Twitter Parallax -- CHANGE THIS VALUE TO MODIFY THE HEADER
    
    func setupTwitterParallax(){
        headerBlurImageView = parallaxHeaderSetup(headerBlurImageView: headerBlurImageView, headerImageView: headerImageView, headerView: headerView, headerViewHeight: headerViewHeight, headerHeightToSet: headerHeight, headerLabel: headerLabel, tableView: tableView)
    }
    
    //executes when the user scrolls
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView != metricTypeCollection {
            let offsetHeaderStop:CGFloat = headerHeight - 100     // At this offset the Header stops its transformations
            let offsetLabelHeader:CGFloat = 60.0                  // The distance between the top of the screen and the top of the White Label
            
            //Shrinks the headerClickWindow that opens the imagePicker
            let height = (tableView.convert(tableView.frame.origin, to: nil).y - 10)
            if height >= 0 {headerClickViewHeight.constant = height}
            parallaxScrollDelegate(scrollView: scrollView, headerView: headerView, headerBlurImageView: headerBlurImageView, headerLabel: headerLabel, offsetHeaderStop: offsetHeaderStop, offsetLabelHeader: offsetLabelHeader, shrinkingButtons: nil, mainTitle: newKasamTitle)
        }
    }

    //---------------------------------------------------------------------------------------------------------------------------------
    
    //Retrieves Kasam Data using Kasam ID selected
    func loadKasam(){
        kasamDatabase.child(NewKasam.kasamID).child("Info").observeSingleEvent(of: .value, with: {(snapshot) in
            //STEP 1 - Load Kasam information
            if let value = snapshot.value as? [String: Any] {
                //load kasam information
                self.newKasamTitle.text = value["Title"] as? String ?? ""
                NewKasam.kasamName = self.newKasamTitle.text ?? ""
                self.newKasamTitle.textColor = UIColor.darkGray
                
                self.newKasamDescription.text! = value["Description"] as? String ?? ""
                NewKasam.kasamDescription = self.newKasamDescription.text ?? ""
                self.newKasamDescription.textColor = UIColor.darkGray
                
                self.headerImageView?.sd_setImage(with: URL(string: value["Image"] as? String ?? ""), placeholderImage: PlaceHolders.kasamHeaderPlaceholderImage)
                
                let benefitsArray = (value["Benefits"] as? String ?? "").components(separatedBy: ";")
                var benefitsText = ""
                for benefit in benefitsArray {
                    var formattedString = ""
                    if benefit == benefitsArray.last {formattedString = "\u{2022} \(benefit)"}
                    else {formattedString = "\u{2022} \(benefit)\n"}
                    benefitsText.append(formattedString)
                }
                self.benefitsTextView.text = benefitsText
                NewKasam.benefits = self.benefitsTextView.text
                self.benefitsTextView.textColor = UIColor.darkGray
                
                self.newCategoryChosenLabel.text = value["Genre"] as? String ?? ""
                NewKasam.chosenGenre = self.newCategoryChosenLabel.text ?? ""
                self.newCategoryChosenLabel.textColor = .darkGray
                self.newCategoryIcon = self.newCategoryIcon.setKasamTypeIcon(kasamType: self.newCategoryChosenLabel.text!, button: self.newCategoryIcon, location: "options")
                
                NewKasam.loadedInKasamImageURL = URL(string: value["Image"] as? String ?? "")
                NewKasam.kasamDescription = self.newKasamDescription.text!
                
                //selects the metric type from the collectionview
                NewKasam.chosenMetric = value["Metric"] as? String ?? ""
                if let index = self.chosenMetricOptions.index(of: NewKasam.chosenMetric) {
                    self.metricTypeCollection.selectItem(at: IndexPath(item: index, section: 0), animated: false, scrollPosition: [.centeredHorizontally])
                    self.collectionView(self.metricTypeCollection, didSelectItemAt : IndexPath(item: index, section: 0))
                }
                if self.basicKasam == false {
                    self.loadBlocks(value: value)
                }
            }
        })
    }
    
    //STEP 2 - Load blocks information
    func loadBlocks(value: [String:Any]){
        if let blockArray = value["Blocks"] as? [String:Any] {
            self.numberOfBlocks = blockArray.count
            for blockNo in 1...blockArray.count {
                //Gets the blockdata after the block is decided on
                self.kasamDatabase.child(NewKasam.kasamID).child("Blocks").queryOrdered(byChild: "Order").queryEqual(toValue : String(blockNo)).observeSingleEvent(of: .childAdded, with: { snapshot in

                    let block = snapshot.value as! Dictionary<String,Any>
                    let blockID = block["BlockID"] as? String ?? ""
                    self.transferTitle[blockNo] = block["Title"] as? String
                    self.blockDuration[blockNo] = block["Duration"] as? String
                    self.transferDuration[blockNo] = self.blockDuration[blockNo]?.split(separator: " ").first.map(String.init) ?? "15"
                    self.transferDurationMetric[blockNo] = self.blockDuration[blockNo]?.split(separator: " ").last.map(String.init)
                    
                    //load the blockdata into the viewcontroller so the user can see it
                    NewKasam.kasamTransferArray[blockNo] = NewKasamLoadFormat(blockTitle: self.transferTitle[blockNo] ?? "Block Title", duration: Int(self.transferDuration[blockNo]!)!, durationMetric: self.transferDurationMetric[blockNo] ?? "secs", complete: true)
                    self.loadActivities(blockNo: blockNo, blockID: blockID)
                    
                    //All the Kasam data is downloaded, so display it
                    if NewKasam.kasamTransferArray.count == self.numberOfBlocks {
                        NewKasam.dataLoadCheck = true
                    }
                })
            }
        }
    }
    
    //STEP 3 - Load Activity Information
    func loadActivities(blockNo: Int, blockID: String) {
        self.personalKasamBlocksDatabase = self.kasamDatabase.child(NewKasam.kasamID).child("Blocks").child(blockID).child("Activity")
        self.personalKasamBlocksDatabase.observe(.childAdded) {(snapshot) in
        if let value = snapshot.value as? [String: Any] {
            var reps = 0
            var interval = 1
            var hours = 0
            var mins = 0
            var secs = 0
            //if the chosenMetric is Reps
            if NewKasam.chosenMetric == self.chosenMetricOptions[0] {
                reps = Int(value["Metric"] as! String) ?? 0
                interval = Int(value["Interval"] as! String) ?? 1
            //if the chosenMetric is Timer
            } else if NewKasam.chosenMetric == self.chosenMetricOptions[1] {
                let totalTime = Int(value["Metric"] as! String)
                hours = (totalTime?.convertIntTimeToSplitInt(fullIntTime: totalTime ?? 0).hours)!
                mins = (totalTime?.convertIntTimeToSplitInt(fullIntTime: totalTime ?? 0).mins)!
                secs = (totalTime?.convertIntTimeToSplitInt(fullIntTime: totalTime ?? 0).secs)!
            }
            let activity = [0: newActivityFormat(title: value["Title"] as? String, description: value["Description"] as? String, imageToLoad: URL(string:value["Image"] as! String), imageToSave: nil, reps: reps, interval: interval, hour: hours, min: mins, sec: secs)]
            NewKasam.fullActivityMatrix[blockNo] = activity
            }
        }
    }
}

//Sets the selected image as the kasam image in create view
extension NewKasamController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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
            self.headerImageView?.image = editedImage.withRenderingMode(.alwaysOriginal)
            if self.headerImageView?.image != PlaceHolders.kasamHeaderPlaceholderImage {
                NewKasam.kasamImageToSave = self.headerImageView!.image!
            }
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.headerImageView?.image = originalImage.withRenderingMode(.alwaysOriginal)
            if self.headerImageView?.image != PlaceHolders.kasamHeaderPlaceholderImage {
                NewKasam.kasamImageToSave = self.headerImageView!.image!
            }
        }
        addAnImageLabel.text = "Change Image"
        dismiss(animated: true, completion: nil)
    }
}

extension NewKasamController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewBlockCell") as! NewBlockCell
        return cell
    }
}

extension NewKasamController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return metricsArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MetricTypeCell", for: indexPath) as! MetricTypeCell
        cell.setMetric(title: metricsArray[indexPath.row])
        if basicKasam == true && (indexPath.row == 0 || indexPath.row == 2) {
            cell.metricTypeBG.alpha = 0.5
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = ((view.frame.size.width - (20 * 3)) / 3)
        metricTypeCollectionHeight.constant = cellWidth + 20
        return CGSize(width: cellWidth, height: cellWidth + 20)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? MetricTypeCell {
            switch indexPath.row {
                case 0: NewKasam.chosenMetric = chosenMetricOptions[0]
                case 1: NewKasam.chosenMetric = chosenMetricOptions[1]
                case 2: NewKasam.chosenMetric = chosenMetricOptions[2]
                default: NewKasam.chosenMetric = chosenMetricOptions[0]
            }
            cell.metricTypeBG.backgroundColor = UIColor.init(hex: 0x9DC78D)
            cell.metricBGOutline.isHidden = false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? MetricTypeCell else {return}
        //unselect the other metrics when one is selected
        cell.metricTypeBG.backgroundColor = UIColor.init(hex: 0xEDD28A)
        cell.metricBGOutline.isHidden = true
    }
}
