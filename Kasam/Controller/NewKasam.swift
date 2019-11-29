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
    @IBOutlet weak var headerClickView: UIView!
    @IBOutlet weak var newBlockPicker: UIPickerView!
    @IBOutlet weak var blockPickerBG: UIView!
    
    var imagePicker: UIImagePickerController!
    var kasamIDGlobal = ""
    var kasamImageGlobal = ""
    var headerBlurImageView:UIImageView!
    var headerImageView:UIImageView!
    var storageRef = Storage.storage().reference()
    
    //No of Blocks Picker Variables
    var numberOfBlocks = 1
    var transferTitle = [Int:String]()
    var transferBlockType = [Int:String]()
    var transferDuration = [Int:String]()
    var transferDurationMetric = [Int:String]()
    var tempBlockNoSelected = 1
    
    //New Kasam Picker Variables
    let metricTypes = ["Metric ↑", "Reps", "Time", "Checkmark"]
    let kasamGenres = ["Genre ↑", "Fitness", "Personal", "Prayer", "Meditation"]
    let kasamLevels = ["Level ↑", "Beginner", "Intermediate", "Expert"]
    var chosenMetric = "Reps Counter"
    var chosenGenre = ""
    var chosenLevel = ""
    
    //Twitter Parallax -- CHANGE THIS VALUE TO MODIFY THE HEADER
    let headerHeight = UIScreen.main.bounds.width * 0.40
    
    //Activity Variables
    var fullActivityMatrix = [Int: [Int: newActivityFormat]]()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLoad()
        setupImageHolders()
    }
    
    func setupLoad(){
        //setup radius for kasam info block
        createKasam.layer.cornerRadius = 20.0
        createKasam.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight:.regular), prefixTextColor: UIColor.white, icon: .fontAwesomeSolid(.magic), iconColor: UIColor.white, postfixText: "  Create Kasam", postfixTextFont: UIFont.systemFont(ofSize: 15, weight:.medium), postfixTextColor: UIColor.white, backgroundColor: UIColor.black, forState: .normal, iconSize: 15)
        profileViewRadius.layer.cornerRadius = 16.0
        profileViewRadius.clipsToBounds = true
        blockPickerBG.layer.cornerRadius = 15
        tableView.contentInset = UIEdgeInsets(top: headerView.frame.height, left: 0, bottom: 0, right: 0)       //setup floating header
        constrainHeightHeaderImages.constant = headerHeight                                                     //setup floating header
        chosenLevel = kasamLevels[0]
        if let navBar = self.navigationController?.navigationBar {
            extendedLayoutIncludesOpaqueBars = true
            navBar.isTranslucent = true
            navBar.backgroundColor = UIColor.white.withAlphaComponent(0)
            navBar.setBackgroundImage(UIImage(), for: .default)
            navBar.shadowImage = UIImage()         //remove bottom border on navigation bar
            navBar.tintColor = UIColor.colorFive   //change back arrow to gold
        }
        
        //Header - Image
        self.headerImageView = UIImageView(frame: self.headerView.bounds)
        self.headerImageView?.contentMode = UIView.ContentMode.scaleAspectFill
        self.headerImageView?.image = UIImage(named: "image-add-placeholder")
        self.headerView.insertSubview(self.headerImageView, belowSubview: self.headerLabel)
        
        //align header image to top
        self.headerImageView.translatesAutoresizingMaskIntoConstraints = false
        let topConstraint = NSLayoutConstraint(item: self.headerImageView, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.headerView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: self.headerImageView, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.headerView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0)
        let trailingConstraint = NSLayoutConstraint(item: self.headerImageView, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.headerView, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1, constant: 0)
        let leadingConstraint = NSLayoutConstraint(item: self.headerImageView, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.headerView, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1, constant: 0)
        self.headerView.addConstraints([topConstraint, bottomConstraint, trailingConstraint, leadingConstraint])
        self.setupBlurImage()
    }
    
    func setupBlurImage() {
        headerBlurImageView = UIImageView(frame: headerView.bounds)
        headerBlurImageView?.backgroundColor = UIColor.white
        headerBlurImageView?.contentMode = UIView.ContentMode.scaleAspectFill
        headerBlurImageView?.alpha = 0.0
        headerView.clipsToBounds = true
        headerView.insertSubview(headerBlurImageView, belowSubview: headerLabel)
    }
    
    // MARK: Scroll view delegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset_HeaderStop:CGFloat = headerHeight - 70         // At this offset the Header stops its transformations
        let distance_W_LabelHeader:CGFloat = 35.0       // The distance between the top of the screen and the top of the White Label
        
        //shrinks the headerClickWindow that opens the imagePicker
        headerClickViewHeight.constant = tableView.convert(tableView.frame.origin, to: nil).y - distance_W_LabelHeader
        
        let offset = scrollView.contentOffset.y + headerView.bounds.height
        var avatarTransform = CATransform3DIdentity
        var headerTransform = CATransform3DIdentity
        
        // PULL DOWN -----------------
        if offset < 0 {
            let headerScaleFactor:CGFloat = -(offset) / headerView.bounds.height
            let headerSizevariation = ((headerView.bounds.height * (1.0 + headerScaleFactor)) - headerView.bounds.height)/2
            headerTransform = CATransform3DTranslate(headerTransform, 0, headerSizevariation, 0)
            headerTransform = CATransform3DScale(headerTransform, 1.0 + headerScaleFactor, 1.0 + headerScaleFactor, 0)
            
            // Hide views if scrolled super fast
            headerView.layer.zPosition = 0
            headerLabel.isHidden = true
            
            if let navBar = self.navigationController?.navigationBar {
                navBar.tintColor = UIColor.white
            }
        }
            
            // SCROLL UP/DOWN ------------
        else {
            // Header -----------
            headerTransform = CATransform3DTranslate(headerTransform, 0, max(-offset_HeaderStop, -offset), 0)
            
            //  ------------ Label
            headerLabel.isHidden = false
            let alignToNameLabel = -offset + newKasamTitle.frame.origin.y + headerView.frame.height + offset_HeaderStop
            headerLabel.frame.origin = CGPoint(x: headerLabel.frame.origin.x, y: max(alignToNameLabel, distance_W_LabelHeader + offset_HeaderStop))
            
            //  ------------ Blur
            headerBlurImageView?.alpha = min (1.0, (offset + 150 - alignToNameLabel)/(distance_W_LabelHeader + 50))
            if let navBar = self.navigationController?.navigationBar {
                let scrollPercentage = Double(min (1.0, (offset + 150 - alignToNameLabel)/(distance_W_LabelHeader + 50)))
                navBar.tintColor = scrollColor(percent: scrollPercentage)
            }
            
            // Avatar -----------
            let avatarScaleFactor = (min(offset_HeaderStop, offset)) / createKasam.bounds.height / 9.4 // Slow down the animation
            let avatarSizeVariation = ((createKasam.bounds.height * (1.0 + avatarScaleFactor)) - createKasam.bounds.height) / 2.0
            
            avatarTransform = CATransform3DTranslate(avatarTransform, 0, avatarSizeVariation, 0)
            avatarTransform = CATransform3DScale(avatarTransform, 1.0 - avatarScaleFactor, 1.0 - avatarScaleFactor, 0)
            
            if offset <= offset_HeaderStop {
                if createKasam.layer.zPosition < headerView.layer.zPosition{
                    headerView.layer.zPosition = 0
                }
            } else {
                if createKasam.layer.zPosition >= headerView.layer.zPosition{
                    headerView.layer.zPosition = 2
                }
            }
        }
        // Apply Transformations
        headerView.layer.transform = headerTransform
//        createKasam.layer.transform = avatarTransform
    }
    
    //Puts the nav bar in
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func setupImageHolders(){
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(openImagePicker))
        headerClickView.addGestureRecognizer(imageTap)
    }
    
    @objc func openImagePicker(_ sender:Any) {
        // Open Image Picker
        showChooseSourceTypeAlertController()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func createKasam(_ sender: Any) {
        //Saves Kasam Text Data
        if newKasamTitle.text == "" || newKasamDescription.text == "" || newMetric.selectedRow(inComponent: 0) == 0 || newGenre.selectedRow(inComponent: 0) == 0 {
            var missingFields: [String] = []
            if newKasamTitle.text == "" {missingFields.append("Title")}
            if newKasamDescription.text == "" {missingFields.append("Description")}
            if newMetric.selectedRow(inComponent: 0) == 0 {missingFields.append("Metric")}
            if newGenre.selectedRow(inComponent: 0) == 0 {missingFields.append("Genre")}
            if newKasamLevel.selectedRow(inComponent: 0) == 0 {missingFields.append("Level")}
            let missingFieldString = missingFields.joined(separator: ", ")
            let description = "Please fill out the Kasam \(missingFieldString)"
            floatCellSelected(title: "Missing Fields", description: description)
        } else {
            self.view.isUserInteractionEnabled = false
            let kasamID = Database.database().reference().child("Coach-Kasams").childByAutoId()
            kasamIDGlobal = kasamID.key ?? ""
            
            saveImage(image: self.headerImageView!.image!, location: "kasam/\(kasamID.key!)", completion: { uploadedImageURL in
                if uploadedImageURL != nil {
                    self.registerKasamData(kasamID: kasamID, imageUrl: uploadedImageURL!)
                } else {
                    //no image added, so use the default one
                    self.registerKasamData(kasamID: kasamID, imageUrl: "https://firebasestorage.googleapis.com/v0/b/kasam-coach.appspot.com/o/kasam%2Fimage-add-placeholder.jpg?alt=media&token=491fdb83-2612-4423-9d2e-cdd44ab8157e")
                }
            })
        }
    }
    
    func saveImage(image: UIImage?, location: String, completion: @escaping (String?)->()) {
        //Saves Kasam Image in Firebase Storage
        storageRef = Storage.storage().reference().child(location)
        let imageData = image?.jpegData(compressionQuality: 0.2)
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
        
    //Function which registers Kasam Data in Firebase RT Database
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
    
    func saveBlocks(){
        self.view.endEditing(true)                  //for adding last text field value with dismiss keyboard
        let newBlock = Database.database().reference().child("Coach-Kasams").child(kasamIDGlobal).child("Blocks")
        for j in 1...numberOfBlocks {
            let blockID = newBlock.childByAutoId()
            let transferBlockDuration = "\(transferDuration[j] ?? "5") \(transferDurationMetric[j] ?? "secs")"
            let blockActivity = fullActivityMatrix[j]
            var metric = 0
            switch chosenMetric {
                case "Reps Counter": metric = blockActivity?[0]?.reps ?? 0          //using 0 as only one activity loaded per block
                case "Timer": do {
                    let hour = (blockActivity?[0]?.hour ?? 0) * 3600
                    let min = (blockActivity?[0]?.min ?? 0) * 60
                    let sec = (blockActivity?[0]?.sec) ?? 0
                    metric = hour + min + sec
                }
                default: metric = 0
            }
            let defaulyActivityImage = "https://firebasestorage.googleapis.com/v0/b/kasam-coach.appspot.com/o/kasam%2Fgiphy%20(1).gif?alt=media&token=e91fd36a-1e2a-43db-b211-396b4b8d65e1"
            saveImage(image: (blockActivity?[0]?.image), location: "kasam/\(kasamIDGlobal)/activity") { (savedImageURL) in
                let activity = ["Description" : blockActivity?[0]?.description ?? "",
                                "Image" : savedImageURL ?? defaulyActivityImage,
                                "Metric" : metric,
                                "Title" : blockActivity?[0]?.title ?? "",
                                "Type" : self.transferBlockType[j] ?? ""] as [String : Any]
                let blockDictionary = ["Activity": activity, "Duration": transferBlockDuration, "Image": self.kasamImageGlobal, "Order": String(j), "Rating": "5", "Title": self.transferTitle[j] ?? "Title", "BlockID": blockID.key!] as [String : Any]
                
                blockID.setValue(blockDictionary) {
                    (error, reference) in
                    if error != nil {
                        print(error!)
                    } else {
                        //kasam successfully created
                        self.view.isUserInteractionEnabled = true
                        self.dismiss(animated: true, completion: nil)
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
            switch metricTypes[row] {
                case "Reps" : chosenMetric = "Reps Counter"
                case "Time" : chosenMetric = "Timer"
                case "Checkmark" : chosenMetric = "Checkmark"
                default: chosenMetric = "Reps Counter"
            }
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
    
    func createButtonPressed(blockNo: Int) {
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
            kasamTransferHolder.callback = { result in
                self.fullActivityMatrix[self.tempBlockNoSelected] = result
            }
        }
    }
    
    func sendDurationTime(blockNo: Int, duration: String) {
        transferDuration[blockNo + 1] = duration
    }
    
    func sendDurationMetric(blockNo: Int, metric: String) {
        transferDurationMetric[blockNo + 1] = metric
    }
    
    func sendBlockType(blockNo: Int, blockType: String) {
        transferBlockType[blockNo + 1] = blockType
    }
}
