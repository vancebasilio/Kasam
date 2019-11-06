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
import SkyFloatingLabelTextField

class NewKasamViewController: UIViewController {
    
    @IBOutlet weak var newKasamTitle: SkyFloatingLabelTextField!
    @IBOutlet weak var newKasamLevel: SkyFloatingLabelTextField!
    @IBOutlet weak var newMetric: SkyFloatingLabelTextField!
    @IBOutlet weak var newTiming: SkyFloatingLabelTextField!
    @IBOutlet weak var newGenre: SkyFloatingLabelTextField!
    @IBOutlet weak var newKasamDescription: SkyFloatingLabelTextField!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var imagePlaceholder: UIImageView!
    @IBOutlet weak var addAnImageLabel: UILabel!
    @IBOutlet weak var createKasam: UIButton!
    
    var imagePicker: UIImagePickerController!
    var kasamIDGlobal = ""
    var kasamImageGlobal = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupImageHolders()
        self.navigationController?.navigationBar.tintColor = UIColor.colorFive
        //hide keyboard when screen tapped
        self.hideKeyboardWhenTappedAround()
        createKasam.layer.cornerRadius = 20.0
        createKasam.clipsToBounds = true
    }
    
    //Puts the nav bar in
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func setupImageHolders(){
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(openImagePicker))
        profileImage.isUserInteractionEnabled = true
        profileImage.addGestureRecognizer(imageTap)
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
        let image = self.profileImage.image
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
        let kasamDictionary = ["Title": newKasamTitle.text!, "Genre": newGenre.text!, "Description": newKasamDescription.text!, "Timing":newTiming.text!, "Image": imageUrl, "KasamID": kasamID.key, "CreatorID": Auth.auth().currentUser?.uid, "CreatorName": Auth.auth().currentUser?.displayName, "Followers": "", "Type": "user", "Rating": "5", "Blocks": "blocks", "Level":newKasamLevel.text!, "Metric": newMetric.text!]
            
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
            self.profileImage.image = editedImage.withRenderingMode(.alwaysOriginal)
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.profileImage.image = originalImage.withRenderingMode(.alwaysOriginal)
        }
        addAnImageLabel.text = "Change Image"
        dismiss(animated: true, completion: nil)
    }
}
