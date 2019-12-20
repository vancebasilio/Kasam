//
//  NewKasamViewController.swift
//  Kasam 1.0
//
//  Created by Vance Basilio on 2019-04-23.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import SwiftEntryKit
import SkyFloatingLabelTextField
import Lottie

class NewKasamViewController: UIViewController, UIScrollViewDelegate {
    
    //Twitter Parallax
    @IBOutlet weak var tableView: UITableView!  {didSet {tableView.estimatedRowHeight = 100}}
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var profileView: UIView!
    @IBOutlet weak var profileViewRadius: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var constrainHeightHeaderImages: NSLayoutConstraint!
    @IBOutlet weak var headerClickViewHeight: NSLayoutConstraint!
    @IBOutlet weak var newKasamTitle: SkyFloatingLabelTextField!
    @IBOutlet weak var newKasamLevel: UIPickerView!
    @IBOutlet weak var newMetric: UIPickerView!
    @IBOutlet weak var newGenre: UIPickerView!
    @IBOutlet weak var newKasamDescription: SkyFloatingLabelTextField!
    @IBOutlet weak var addAnImageLabel: UILabel!
    @IBOutlet weak var createKasam: UIButton!
    @IBOutlet weak var deleteChallo: UIButton!
    @IBOutlet weak var headerClickView: UIView!
    @IBOutlet weak var newBlockPicker: UIPickerView!
    @IBOutlet weak var blockPickerBG: UIView!
    
    var imagePicker: UIImagePickerController!
    var kasamIDGlobal = ""
    var kasamImageGlobal = ""
    var headerBlurImageView: UIImageView!
    var headerImageView: UIImageView!
    var storageRef = Storage.storage().reference()
    let animationView = AnimationView()
    let animationOverlay = UIView()
    
    //edit Challo
    var editChalloCheck = false
    var kasamID = ""                                //loaded in from segue
    var kasamName = ""                              //loaded in from segue
    var kasamImage = URL(string: "")                //loaded in from segue
    var loadedInChalloImage = UIImage()
    var challoTransferArray = [Int:NewChalloLoadFormat]()
    var dataLoadCheck = false
    var kasamDatabase = Database.database().reference().child("Coach-Kasams")
    var kasamDatabaseHandle: DatabaseHandle!
    var kasamBlocksDatabase = Database.database().reference().child("Coach-Kasams")
    var kasamBlocksDatabaseHandle: DatabaseHandle!
    var blockDuration = [Int:String]()
    
    //No of Blocks Picker Variables
    var numberOfBlocks = 1
    var transferTitle = [Int:String]()
    var transferBlockType = [Int:String]()
    var transferDuration = [Int:String]()
    var transferDurationMetric = [Int:String]()
    var tempBlockNoSelected = 1
    
    //New Challo Picker Variables
    let metricTypes = ["Metric ↑", "Reps", "Timer", "Checkmark"]
    let kasamGenres = ["Genre ↑", "Fitness", "Personal", "Prayer", "Meditation"]
    let kasamLevels = ["Level ↑", "Beginner", "Intermediate", "Expert"]
    var chosenMetric = "Reps"
    var chosenGenre = ""
    var chosenLevel = ""
    
    //Activity Variables
    var fullActivityMatrix = [Int: [Int: newActivityFormat]]()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLoad()
        setupTwitterParallax()
        setupImageHolders()
    }
    
    func setupLoad(){
        //setup radius for kasam info block
        self.hideKeyboardWhenTappedAround()
        
        createKasam.layer.cornerRadius = 20.0
        var createChalloTitle = "  Create Challo"
        if editChalloCheck == true {
            loadChallo()
            headerLabel.text = "Edit Challo"
            createChalloTitle = "  Save Challo"
            addAnImageLabel.text = "Change Image"
        }
        createKasam.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight:.regular), prefixTextColor: UIColor.white, icon: .fontAwesomeSolid(.magic), iconColor: UIColor.white, postfixText: createChalloTitle, postfixTextFont: UIFont.systemFont(ofSize: 15, weight:.medium), postfixTextColor: UIColor.white, backgroundColor: UIColor.black, forState: .normal, iconSize: 15)
        
        deleteChallo.layer.cornerRadius = 20.0
        deleteChallo.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight:.regular), prefixTextColor: UIColor.white, icon: .fontAwesomeSolid(.trashAlt), iconColor: UIColor.white, postfixText: "  Delete Challo", postfixTextFont: UIFont.systemFont(ofSize: 15, weight:.medium), postfixTextColor: UIColor.white, backgroundColor: UIColor.init(hex: 0xDB482D), forState: .normal, iconSize: 15)
        
        profileViewRadius.layer.cornerRadius = 16.0
        profileViewRadius.clipsToBounds = true
        blockPickerBG.layer.cornerRadius = 15
        chosenLevel = kasamLevels[0]
    }
    
    //Twitter Parallax-------------------------------------------------------------------------------------------------------------------
    
    let headerHeight = UIScreen.main.bounds.width * 0.65        //Twitter Parallax -- CHANGE THIS VALUE TO MODIFY THE HEADER
    
    func setupTwitterParallax(){
        tableView.contentInset = UIEdgeInsets(top: headerView.frame.height, left: 0, bottom: 0, right: 0)       //setup floating header
        constrainHeightHeaderImages.constant = headerHeight                                                     //setup floating header

        //Header - Image
        self.headerImageView = UIImageView(frame: self.headerView.bounds)
        self.headerImageView?.contentMode = UIView.ContentMode.scaleAspectFill
        self.headerImageView?.image = UIImage(named: "image-add-placeholder")
        self.headerView.insertSubview(self.headerImageView, belowSubview: self.headerLabel)
        
        headerBlurImageView = twitterParallaxHeaderSetup(headerBlurImageView: headerBlurImageView, headerImageView: headerImageView, headerView: headerView, headerLabel: headerLabel)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetHeaderStop:CGFloat = headerHeight - 100         // At this offset the Header stops its transformations
        let offsetLabelHeader:CGFloat = 60.0                  // The distance between the top of the screen and the top of the White Label
        //shrinks the headerClickWindow that opens the imagePicker
        headerClickViewHeight.constant = tableView.convert(tableView.frame.origin, to: nil).y - offsetLabelHeader
        twitterParallaxScrollDelegate(scrollView: scrollView, headerHeight: headerHeight, headerView: headerView, headerBlurImageView: headerBlurImageView, headerLabel: headerLabel, offsetHeaderStop: offsetHeaderStop, offsetLabelHeader: offsetLabelHeader, shrinkingButton: nil, shrinkingButton2: nil, mainTitle: newKasamTitle)
    }
    
    //Puts the nav bar in
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    //------------------------------------------------------------------------------------------------------------------------------------------
    
    func setupImageHolders(){
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(openImagePicker))
        headerClickView.addGestureRecognizer(imageTap)
    }
    
    @objc func openImagePicker(_ sender:Any) {
        // Open Image Picker
        showChooseSourceTypeAlertController()
    }

    //------------------------------------------------------------------------------------------------------------------------------------------
    
    //Retrieves Kasam Data using Kasam ID selected
    func loadChallo(){
        newKasamTitle.text = kasamName
        kasamDatabase = Database.database().reference().child("Coach-Kasams").child(kasamID)
        kasamDatabaseHandle = kasamDatabase.observe(.value, with: {(snapshot) in
            //STEP 1 - Load Challo information
            if let value = snapshot.value as? [String: Any] {
                //load challo information
                self.newKasamDescription.text! = value["Description"] as? String ?? ""
                self.chosenGenre = value["Genre"] as? String ?? ""
                if let index = self.kasamGenres.index(of: self.chosenGenre) {
                    self.newGenre.selectRow(index, inComponent: 0, animated: false)
                }
                self.chosenMetric = value["Metric"] as? String ?? ""
                if let index = self.metricTypes.index(of: self.chosenMetric) {
                    self.newMetric.selectRow(index, inComponent: 0, animated: false)
                }
                self.chosenLevel = value["Level"] as? String ?? ""
                if let index = self.kasamLevels.index(of: self.chosenLevel) {
                    self.newKasamLevel.selectRow(index, inComponent: 0, animated: false)
                }
                self.headerImageView?.sd_setImage(with: URL(string: value["Image"] as? String ?? ""), placeholderImage: UIImage(named: "placeholder.png"))
                self.loadBlocks(value: value)
            }
        })
    }
    
    //STEP 2 - Load blocks information
    func loadBlocks(value: [String:Any]){
        if let blockArray = value["Blocks"] as? [String:Any] {
            self.newBlockPicker.selectRow((blockArray.count - 1), inComponent: 0, animated: false)
            self.numberOfBlocks = blockArray.count
            for blockNo in 1...blockArray.count {
                //Gets the blockdata after the block is decided on
                self.kasamDatabase.child("Blocks").queryOrdered(byChild: "Order").queryEqual(toValue : String(blockNo)).observeSingleEvent(of: .childAdded, with: { snapshot in

                    let block = snapshot.value as! Dictionary<String,Any>
                    let blockID = block["BlockID"] as? String ?? ""
                    self.transferTitle[blockNo] = block["Title"] as? String
                    self.blockDuration[blockNo] = block["Duration"] as? String
                    self.transferDuration[blockNo] = self.blockDuration[blockNo]?.split(separator: " ").first.map(String.init) ?? "15"
                    self.transferDurationMetric[blockNo] = self.blockDuration[blockNo]?.split(separator: " ").last.map(String.init)
                    
                    //load the blockdata into the viewcontroller so the user can see it
                    self.challoTransferArray[blockNo - 1] = NewChalloLoadFormat(challoTitle: self.transferTitle[blockNo] ?? "Block Title", time: Int(self.transferDuration[blockNo]!)!, timeMetric: self.transferDurationMetric[blockNo] ?? "secs")
                    
                    self.loadActivities(blockNo: blockNo, blockID: blockID)
                    
                    //All the Challo data is downloaded, so display it
                    if self.challoTransferArray.count == self.numberOfBlocks {
                        self.dataLoadCheck = true
                        self.kasamDatabase.child(self.kasamID).removeObserver(withHandle: self.kasamDatabaseHandle)
                        self.kasamBlocksDatabase.removeObserver(withHandle: self.kasamBlocksDatabaseHandle)
                        self.tableView.reloadData()
                    }
                })
            }
        }
    }
    
    //STEP 3 - Load Activity Information
    func loadActivities(blockNo: Int, blockID: String) {
        self.kasamBlocksDatabase = self.kasamDatabase.child("Blocks").child(blockID).child("Activity")
        self.kasamBlocksDatabaseHandle = self.kasamBlocksDatabase.observe(.childAdded) {(snapshot) in
        if let value = snapshot.value as? [String: Any] {
            var reps = 0
            var hours = 0
            var mins = 0
            var secs = 0
            if self.chosenMetric == "Reps" {
                reps = value["Metric"] as! Int
            } else if self.chosenMetric == "Timer" {
                let totalTime = Int(value["Metric"] as! String)
                hours = (totalTime?.convertIntTimeToSplitInt(fullIntTime: totalTime ?? 0).hours)!
                mins = (totalTime?.convertIntTimeToSplitInt(fullIntTime: totalTime ?? 0).mins)!
                secs = (totalTime?.convertIntTimeToSplitInt(fullIntTime: totalTime ?? 0).secs)!
            }
            let imageView = UIImageView()
            imageView.sd_setImage(with: URL(string:value["Image"] as! String))
            let image = imageView.image
            let activity = [0: newActivityFormat(title: value["Title"] as? String, description: value["Description"] as? String, image: image, reps: reps, hour: hours, min: mins, sec: secs)]
            self.fullActivityMatrix[blockNo] = activity
            }
        }
    }
    
    @IBAction func deleteChalloPressed(_ sender: Any) {
        if editChalloCheck == false {
            //do not save Challo
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
    
    
    @IBAction func createKasam(_ sender: Any) {
        if editChalloCheck == false {
            createChallo(existingKasamID: nil)
        } else {
            createChallo(existingKasamID: kasamID)
        }
    }
    
    //STEP 1 - Saves Challo Text Data
    func createChallo(existingKasamID: String?) {
        if newKasamTitle.text == "" || newKasamDescription.text == "" || newMetric.selectedRow(inComponent: 0) == 0 || newGenre.selectedRow(inComponent: 0) == 0 {
            //there are missing fields that need to be filled
            var missingFields: [String] = []
            if newKasamTitle.text == "" {missingFields.append("Title")}
            if newKasamDescription.text == "" {missingFields.append("Description")}
            if newMetric.selectedRow(inComponent: 0) == 0 {missingFields.append("Metric")}
            if newGenre.selectedRow(inComponent: 0) == 0 {missingFields.append("Genre")}
            if newKasamLevel.selectedRow(inComponent: 0) == 0 {missingFields.append("Level")}
            let missingFieldString = missingFields.sentence
            let description = "Please fill out the Challo \(missingFieldString)"
            floatCellSelected(title: "Missing Fields", description: description)
        } else {
            //all fields filled, so can create the Challo now
            loadingAnimation(animationView: animationView, animation: "rocket-fast", height: 200, overlayView: animationOverlay, loop: true, completion: nil)
            self.view.isUserInteractionEnabled = false
            var kasamID = Database.database().reference().child("Coach-Kasams").childByAutoId()
            if existingKasamID != nil {
                kasamID = Database.database().reference().child("Coach-Kasams").child(existingKasamID!)
                kasamIDGlobal = kasamID.key ?? ""
            }
            if headerImageView.image != loadedInChalloImage {
                //user has uploaded a new image, so save it
                saveImage(image: self.headerImageView!.image!, location: "kasam/\(kasamID.key!)", completion: { uploadedImageURL in
                    if uploadedImageURL != nil {
                        self.registerKasamData(kasamID: kasamID, imageUrl: uploadedImageURL!)
                    } else {
                        //no image added, so use the default one
                        self.registerKasamData(kasamID: kasamID, imageUrl: "https://firebasestorage.googleapis.com/v0/b/kasam-coach.appspot.com/o/kasam%2Fimage-add-placeholder.jpg?alt=media&token=491fdb83-2612-4423-9d2e-cdd44ab8157e")
                    }
                })
            } else {
                //user using same image, so no need to save image
                let uploadedImageURL = kasamImage?.absoluteString
                self.registerKasamData(kasamID: kasamID, imageUrl: uploadedImageURL!)
            }
        }
    }
    
    //STEP 2 - Save Challo Image
    func saveImage(image: UIImage?, location: String, completion: @escaping (String?)->()) {
        //Saves Kasam Image in Firebase Storage
        storageRef = Storage.storage().reference().child(location)
        let imageData = image?.jpegData(compressionQuality: 0.6)
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        
        if imageData != nil {
            storageRef.putData(imageData!, metadata: metaData) { metaData, error in
                if error == nil, metaData != nil {
                    self.storageRef.downloadURL { url, error in
                        completion(url!.absoluteString)
                    }
                }
            }
        } else {completion(nil)}
    }
        
    //STEP 3 - Register Challo Data in Firebase Database
    func registerKasamData (kasamID: DatabaseReference, imageUrl: String) {
        kasamImageGlobal = imageUrl
        let kasamDictionary = ["Title": newKasamTitle.text!, "Genre": chosenGenre, "Description": newKasamDescription.text!, "Timing": "6:00pm - 7:00pm", "Image": imageUrl, "KasamID": kasamID.key, "CreatorID": Auth.auth().currentUser?.uid, "CreatorName": Auth.auth().currentUser?.displayName, "Followers": "", "Type": "User", "Rating": "5", "Blocks": "blocks", "Level":chosenLevel, "Metric": chosenMetric]
            
        kasamID.setValue(kasamDictionary) {(error, reference) in
            if error != nil {
                print(error!)
            } else {
            //kasam successfully created
        Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Kasams").child(self.kasamIDGlobal).setValue(self.newKasamTitle.text!)
            self.saveBlocks()
            }
        }
    }
    
    //STEP 4 - Save block info under Challo
    func saveBlocks(){
        self.view.endEditing(true)                  //for adding last text field value with dismiss keyboard
        let newBlock = Database.database().reference().child("Coach-Kasams").child(kasamIDGlobal).child("Blocks")
        var successBlockCount = 0
        for j in 1...numberOfBlocks {
            let blockID = newBlock.childByAutoId()
            let transferBlockDuration = "\(transferDuration[j] ?? "15") \(transferDurationMetric[j] ?? "secs")"
            let blockActivity = fullActivityMatrix[j]
            var metric = 0
            switch chosenMetric {
                case "Reps": metric = blockActivity?[0]?.reps ?? 0          //using 0 as only one activity loaded per block
                case "Timer": do {
                    let hour = (blockActivity?[0]?.hour ?? 0) * 3600
                    let min = (blockActivity?[0]?.min ?? 0) * 60
                    let sec = (blockActivity?[0]?.sec ?? 0)
                    metric = hour + min + sec
                }
                default: metric = 0
            }
            let defaultActivityImage = "https://firebasestorage.googleapis.com/v0/b/kasam-coach.appspot.com/o/kasam%2Fgiphy%20(1).gif?alt=media&token=e91fd36a-1e2a-43db-b211-396b4b8d65e1"
            saveImage(image: (blockActivity?[0]?.image), location: "kasam/\(kasamIDGlobal)/activity") {(savedImageURL) in
                let activity = ["Description" : blockActivity?[0]?.description ?? "",
                                "Image" : savedImageURL ?? defaultActivityImage,
                                "Metric" : String(metric),
                                "Title" : blockActivity?[0]?.title ?? "",
                                "Type" : self.chosenMetric] as [String : Any]
                let activityMatrix = ["1":activity]
                let blockDictionary = ["Activity": activityMatrix, "Duration": transferBlockDuration, "Image": self.kasamImageGlobal, "Order": String(j), "Rating": "5", "Title": self.transferTitle[j] ?? "Block Title", "BlockID": blockID.key!] as [String : Any]
                blockID.setValue(blockDictionary) {
                    (error, reference) in
                    if error != nil {
                        print(error!)
                    } else {
                        //Challo successfully created
                        successBlockCount += 1
                        //All the blocks and their images are saved, so go back to the profile view
                        if successBlockCount == self.numberOfBlocks {
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
}

//Sets the selected image as the kasam image in create view
extension NewKasamViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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
            self.headerImageView?.image = editedImage.withRenderingMode(.alwaysOriginal)
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.headerImageView?.image = originalImage.withRenderingMode(.alwaysOriginal)
        }
        addAnImageLabel.text = "Change Image"
        dismiss(animated: true, completion: nil)
    }
}

extension NewKasamViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        pickerView.subviews.forEach({$0.isHidden = $0.frame.height < 1.0})                      //removes the line above and below
        if pickerView == newBlockPicker {
            return 30
        } else if pickerView == newMetric {
            return metricTypes.count
        } else if pickerView == newGenre {
            return kasamGenres.count
        } else {
            return kasamLevels.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label = UILabel()
        if let v = view as? UILabel { label = v }
        if pickerView == newBlockPicker {
            label.font = UIFont.systemFont(ofSize: 25, weight: .bold)
            label.textAlignment = .center
            label.text =  String(row + 1)
        } else {
            label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            if row == 0 {
                label.textColor = UIColor.lightGray
            } else {
                label.textColor = UIColor.black
            }
            if pickerView == newMetric {
                label.textAlignment = .left
                label.text = metricTypes[row]
            } else if pickerView == newGenre {
                label.text = kasamGenres[row]
                label.textAlignment = .center
            } else {
                label.text = kasamLevels[row]
                label.textAlignment = .right
            }
        }
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == newBlockPicker {
            numberOfBlocks = row + 1
            tableView.reloadData()
        } else if pickerView == newMetric {
            chosenMetric = metricTypes[row]
        } else if pickerView == newGenre {
            chosenGenre = kasamGenres[row]
        } else if pickerView == newKasamLevel {
            chosenLevel = kasamLevels[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        if pickerView == newBlockPicker {
            return 50.0
        } else {
            return 40.0
        }
    }
}

extension NewKasamViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfBlocks
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewBlockCell") as! NewBlockCell
        cell.setupFormatting()
        if editChalloCheck == true && dataLoadCheck == true {
            cell.loadChalloInfo(block: challoTransferArray[indexPath.row]!)
        }
        cell.delegate = self
        cell.blockNo = indexPath.row
        cell.dayNumber.text = String(indexPath.row + 1)
        cell.titleTextField.delegate = self as? UITextFieldDelegate
        cell.titleTextField.tag = 1
        cell.titleTextField.addTarget(self, action: #selector(onTextChanged(sender:)), for: UIControl.Event.editingChanged)
        return cell
    }
        
    @objc func onTextChanged(sender: UITextField) {
        let cell: UITableViewCell = sender.superview?.superview?.superview?.superview?.superview?.superview as! UITableViewCell
        let table: UITableView = cell.superview as! UITableView
        let indexPath = table.indexPath(for: cell)
        let row = (indexPath?.row ?? 0) + 1
        if sender.tag == 1 {
            transferTitle[row] = sender.text!
        }
    }
}

extension NewKasamViewController: NewBlockDelegate {
    
    func addActivityButtonPressed(blockNo: Int) {
        transferBlockType[blockNo + 1] = chosenMetric
        tempBlockNoSelected = blockNo + 1
        self.performSegue(withIdentifier: "goToCreateActivity", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToCreateActivity" {
            let kasamTransferHolder = segue.destination as! NewActivity
            kasamTransferHolder.activityType = chosenMetric
            kasamTransferHolder.blockNoSelected = tempBlockNoSelected
            kasamTransferHolder.pastEntry = fullActivityMatrix[tempBlockNoSelected]             //if there's a past entry, it'll load it in
            //when the save button is pressed on the newActivityCell, it saves the data into a 'result' matrix and passes it to the fullActivityMatrix
            kasamTransferHolder.callback = { result in
                self.fullActivityMatrix[self.tempBlockNoSelected] = result
            }
        }
    }
    
    func sendDurationTime(blockNo: Int, duration: String) {
        transferDuration[blockNo + 1] = duration                    //only runs when the picker is slided
    }
    
    func sendDurationMetric(blockNo: Int, metric: String) {
        transferDurationMetric[blockNo + 1] = metric                //only runs when the picker is slided
    }
}
