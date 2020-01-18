//
//  NewKasamController.swift
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

class NewKasamController: UIViewController, UIScrollViewDelegate {
    
    //Twitter Parallax
    @IBOutlet weak var tableView: UITableView!  {didSet {tableView.estimatedRowHeight = 100}}
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var profileView: UIView!
    @IBOutlet weak var profileViewRadius: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var metricTypeCollection: UICollectionView!
    @IBOutlet weak var metricTypeCollectionHeight: NSLayoutConstraint!
    @IBOutlet weak var constrainHeightHeaderImages: NSLayoutConstraint!
    @IBOutlet weak var headerClickViewHeight: NSLayoutConstraint!
    @IBOutlet weak var newKasamTitle: SkyFloatingLabelTextField!
    @IBOutlet weak var newKasamDescription: SkyFloatingLabelTextField!
    @IBOutlet weak var addAnImageLabel: UILabel!
    @IBOutlet weak var createActivitiesCircle: UIButton!
    @IBOutlet weak var headerClickView: UIView!
    @IBOutlet weak var createActivitiesLabel: UILabel!
    
    var imagePicker: UIImagePickerController!
    var headerBlurImageView: UIImageView!
    var headerImageView: UIImageView!
    
    //edit Kasam
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
    
    //New Kasam Picker Variables
    var chosenGenre = ""            //removed for personal kasams, will include for professional ones
    var chosenLevel = ""            //removed for personal kasams, will include for professional ones
    
    //Metrics
    let metricsArray = ["Count", "Completion", "Timer"]
    let chosenMetricOptions = ["Reps", "Checkmark", "Timer"]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLoad()
        setupTwitterParallax()
        setupImageHolders()
    }
    
    func setupLoad(){
        //setup radius for kasam info block
        self.hideKeyboardWhenTappedAround()
        if NewKasam.editKasamCheck == true {
            loadKasam()
            headerLabel.text = "Edit Kasam"
            addAnImageLabel.text = "Change Image"
            createActivitiesLabel.text = "Edit Activities"
        }
        createActivitiesCircle.layer.cornerRadius = createActivitiesCircle.frame.height / 2
        createActivitiesCircle.clipsToBounds = true
        createActivitiesCircle.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight:.regular), prefixTextColor: UIColor.white, icon: .fontAwesomeSolid(.arrowRight), iconColor: UIColor.white, postfixText: "", postfixTextFont: UIFont.systemFont(ofSize: 15, weight:.medium), postfixTextColor: UIColor.white, backgroundColor: UIColor.black, forState: .normal, iconSize: 25)
        profileViewRadius.layer.cornerRadius = 16.0
        profileViewRadius.clipsToBounds = true
    }
    
    @IBAction func createActivitiesButtonPressed(_ sender: Any) {
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
    
    let headerHeight = UIScreen.main.bounds.width * 0.65        //Twitter Parallax -- CHANGE THIS VALUE TO MODIFY THE HEADER
    
    func setupTwitterParallax(){
        tableView.contentInset = UIEdgeInsets(top: headerView.frame.height, left: 0, bottom: 0, right: 0)       //setup floating header
        constrainHeightHeaderImages.constant = headerHeight                                                     //setup floating header

        //Header - Image
        self.headerImageView = UIImageView(frame: self.headerView.bounds)
        self.headerImageView?.contentMode = UIView.ContentMode.scaleAspectFill
        self.headerImageView?.image = PlaceHolders.kasamHeaderPlaceholderImage
        self.headerView.insertSubview(self.headerImageView, belowSubview: self.headerLabel)
        
        headerBlurImageView = twitterParallaxHeaderSetup(headerBlurImageView: headerBlurImageView, headerImageView: headerImageView, headerView: headerView, headerLabel: headerLabel)
    }
    
    //executes when the user scrolls
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView != metricTypeCollection {
            let offsetHeaderStop:CGFloat = headerHeight - 100         // At this offset the Header stops its transformations
            let offsetLabelHeader:CGFloat = 60.0                  // The distance between the top of the screen and the top of the White Label
            //shrinks the headerClickWindow that opens the imagePicker
            headerClickViewHeight.constant = tableView.convert(tableView.frame.origin, to: nil).y - offsetLabelHeader
            twitterParallaxScrollDelegate(scrollView: scrollView, headerHeight: headerHeight, headerView: headerView, headerBlurImageView: headerBlurImageView, headerLabel: headerLabel, offsetHeaderStop: offsetHeaderStop, offsetLabelHeader: offsetLabelHeader, shrinkingButton: nil, shrinkingButton2: nil, mainTitle: newKasamTitle)
        }
    }
    
    //IMAGE PICKER----------------------------------------------------------------------------------------------------------------------------
    
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
    func loadKasam(){
        newKasamTitle.text = NewKasam.kasamName
        kasamDatabase = Database.database().reference().child("Coach-Kasams").child(NewKasam.kasamID)
        kasamDatabaseHandle = kasamDatabase.observe(.value, with: {(snapshot) in
            //STEP 1 - Load Kasam information
            if let value = snapshot.value as? [String: Any] {
                //load kasam information
                self.newKasamDescription.text! = value["Description"] as? String ?? ""
                self.headerImageView?.sd_setImage(with: URL(string: value["Image"] as? String ?? ""), placeholderImage: PlaceHolders.kasamLoadingImage)
                NewKasam.loadedInKasamImage = self.headerImageView.image!
                NewKasam.loadedInKasamImageURL = URL(string: value["Image"] as? String ?? "")
                NewKasam.kasamDescription = self.newKasamDescription.text!
                
                //selects the metric type from the collectionview
                NewKasam.chosenMetric = value["Metric"] as? String ?? ""
                if let index = self.chosenMetricOptions.index(of: NewKasam.chosenMetric) {
                    self.metricTypeCollection.selectItem(at: IndexPath(item: index, section: 0), animated: false, scrollPosition: [.centeredHorizontally])
                    self.collectionView(self.metricTypeCollection, didSelectItemAt : IndexPath(item: index, section: 0))
                }
                self.loadBlocks(value: value)
            }
        })
    }
    
    //STEP 2 - Load blocks information
    func loadBlocks(value: [String:Any]){
        if let blockArray = value["Blocks"] as? [String:Any] {
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
                    NewKasam.kasamTransferArray[blockNo] = NewKasamLoadFormat(blockTitle: self.transferTitle[blockNo] ?? "Block Title", duration: Int(self.transferDuration[blockNo]!)!, durationMetric: self.transferDurationMetric[blockNo] ?? "secs", complete: true)
                    self.loadActivities(blockNo: blockNo, blockID: blockID)
                    
                    //All the Kasam data is downloaded, so display it
                    if NewKasam.kasamTransferArray.count == self.numberOfBlocks {
                        NewKasam.dataLoadCheck = true
                        self.kasamDatabase.child(NewKasam.kasamID).removeObserver(withHandle: self.kasamDatabaseHandle)
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
            self.kasamBlocksDatabase.removeObserver(withHandle: self.kasamBlocksDatabaseHandle)
        }
    }
}

//Sets the selected image as the kasam image in create view
extension NewKasamController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = ((view.frame.size.width - (20 * 3)) / 3)
        metricTypeCollectionHeight.constant = cellWidth + 40
        return CGSize(width: cellWidth, height: cellWidth + 40)
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
        guard let cell = collectionView.cellForItem(at: indexPath) as? MetricTypeCell else {
            return
        }
        //unselect the other metrics when one is selected
        cell.metricTypeBG.backgroundColor = UIColor.init(hex: 0xEDD28A)
        cell.metricBGOutline.isHidden = true
    }
}
