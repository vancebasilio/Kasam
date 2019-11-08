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
    @IBOutlet weak var newKasamLevel: SkyFloatingLabelTextField!
    @IBOutlet weak var newMetric: SkyFloatingLabelTextField!
    @IBOutlet weak var newGenre: SkyFloatingLabelTextField!
    @IBOutlet weak var newKasamDescription: SkyFloatingLabelTextField!
    @IBOutlet weak var addAnImageLabel: UILabel!
    @IBOutlet weak var createKasam: UIButton!
    @IBOutlet weak var headerClickView: UIView!
    @IBOutlet weak var newBlockPicker: UIPickerView!
    
    var imagePicker: UIImagePickerController!
    var kasamIDGlobal = ""
    var kasamImageGlobal = ""
    var headerBlurImageView:UIImageView!
    var headerImageView:UIImageView!
    
    //PickerView Variables
    var numberOfBlocks = 1
    var transferTitle = [Int:String]()
    var transferDuration = [Int:String]()
    
    //Twitter Parallax -- CHANGE THIS VALUE TO MODIFY THE HEADER
    let headerHeight = UIScreen.main.bounds.width * 0.40

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLoad()
        setupImageHolders()
    }
    
    func updateContentTableHeight(){
//        tableViewHeight.constant = CGFloat(70 * numberOfBlocks)
//        let frame = self.view.safeAreaLayoutGuide.layoutFrame
//        let contentViewHeight = tableViewHeight.constant + 380
//        if contentViewHeight > frame.height {
//            contentView.constant = contentViewHeight
//        } else if contentViewHeight <= frame.height {
//            let diff = UIScreen.main.bounds.height - contentViewHeight
//            contentView.constant = tableViewHeight.constant + diff + 320
//        }
    }
    
    func setupLoad(){
        //setup radius for kasam info block
        profileViewRadius.layer.cornerRadius = 16.0
        profileViewRadius.clipsToBounds = true
        tableView.contentInset = UIEdgeInsets(top: headerView.frame.height, left: 0, bottom: 0, right: 0)       //setup floating header
        constrainHeightHeaderImages.constant = headerHeight                                                     //setup floating header
        
        
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
        createKasam.layer.transform = avatarTransform
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToCreateBlocks" {
            let kasamTransferHolder = segue.destination as! NewBlockViewController
            kasamTransferHolder.kasamID = kasamIDGlobal
            kasamTransferHolder.blockImage = kasamImageGlobal
        }
    }
    
    @IBAction func createKasam(_ sender: Any) {
        //Saves Kasam Text Data
        let newKasam = Database.database().reference().child("Coach-Kasams")
        let kasamID = newKasam.childByAutoId()
        kasamIDGlobal = kasamID.key ?? ""
        
        //Saves Kasam Image in Firebase Storage
        let storageRef = Storage.storage().reference().child("kasam/\(kasamID.key!)")
        let image = self.headerImageView?.image
        let imageData = image?.jpegData(compressionQuality: 0.2)
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        
        if imageData != nil {
            storageRef.putData(imageData!, metadata: metaData) {metaData, error in
            if error == nil, metaData != nil {
                storageRef.downloadURL { url, error in
                    self.registerKasamData(kasamID: kasamID, imageUrl: url!.absoluteString)
                    }
                }
            }
        } else {
            //no image added, so use the default one
            self.registerKasamData(kasamID: kasamID, imageUrl: "https://firebasestorage.googleapis.com/v0/b/kasam-coach.appspot.com/o/kasam%2Fimage-add-placeholder.jpg?alt=media&token=491fdb83-2612-4423-9d2e-cdd44ab8157e")
        }
    }
        
    //Function which registers Kasam Data in Firebase RT Database
    func registerKasamData (kasamID: DatabaseReference, imageUrl: String) {
        kasamImageGlobal = imageUrl
        let kasamDictionary = ["Title": newKasamTitle.text!, "Genre": newGenre.text!, "Description": newKasamDescription.text!, "Timing": "6:00pm - 7:00pm", "Image": imageUrl, "KasamID": kasamID.key, "CreatorID": Auth.auth().currentUser?.uid, "CreatorName": Auth.auth().currentUser?.displayName, "Followers": "", "Type": "user", "Rating": "5", "Blocks": "blocks", "Level":newKasamLevel.text!, "Metric": newMetric.text!]
            
        kasamID.setValue(kasamDictionary) {(error, reference) in
            if error != nil {
                print(error!)
            } else {
            //kasam successfully created
        Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Kasams").child(self.kasamIDGlobal).setValue(self.newKasamTitle.text!)
            }
        }
        self.performSegue(withIdentifier: "goToCreateBlocks", sender: nil)
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
        return 30
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label = UILabel()
        if let v = view as? UILabel { label = v }
        label.font = UIFont.systemFont(ofSize: 25, weight: .bold)
        label.text =  String(row + 1)
        label.textAlignment = .center
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        numberOfBlocks = row + 1
        self.updateContentTableHeight()
        tableView.reloadData()
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 30.0
    }
}

extension NewKasamViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfBlocks
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewBlockCell") as! NewBlockCell
        cell.dayNumber.text = String(indexPath.row + 1)
        cell.titleTextField.delegate = self as? UITextFieldDelegate
        cell.durationTextField.delegate = self as? UITextFieldDelegate
        cell.titleTextField.tag = 1
        cell.durationTextField.tag = 2
        cell.titleTextField.addTarget(self, action: #selector(onTextChanged(sender:)), for: UIControl.Event.editingChanged)
        cell.durationTextField.addTarget(self, action: #selector(onTextChanged(sender:)), for: UIControl.Event.editingChanged)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    @objc func onTextChanged(sender: UITextField) {
        let cell: UITableViewCell = sender.superview?.superview?.superview?.superview as! UITableViewCell
        let table: UITableView = cell.superview as! UITableView
        let indexPath = table.indexPath(for: cell)
        let row = (indexPath?.row ?? 0) + 1
        if sender.tag == 1 {
            transferTitle[row] = sender.text!
        } else if sender.tag == 2 {
            transferDuration[row] = sender.text!
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
}
