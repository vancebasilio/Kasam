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

class NewKasamViewController: UIViewController {
    
    @IBOutlet weak var newKasamTitle: UITextField!
    @IBOutlet weak var newKasamType: UITextField!
    @IBOutlet weak var newKasamDescription: UITextView!
    @IBOutlet weak var profileImage: UIImageView!
    
    var imagePicker: UIImagePickerController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //hide keyboard when screen tapped
        self.hideKeyboardWhenTappedAround()

        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(openImagePicker))
        profileImage.isUserInteractionEnabled = true
        profileImage.addGestureRecognizer(imageTap)
        profileImage.layer.cornerRadius = profileImage.bounds.height / 2
        profileImage.clipsToBounds = true
        
    }
    
    @objc func openImagePicker(_ sender:Any) {
        // Open Image Picker
        self.present(imagePicker, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func createKasam(_ sender: Any) {
       
    //Saves Kasam Text Data
        let newKasam = Database.database().reference().child("Coach-Kasams")
        let kasamID = newKasam.childByAutoId()
        
    //Saves Kasam Image in Firebase Storage
        let storageRef = Storage.storage().reference().child("kasam/\(kasamID.key!)")
        guard let image = self.profileImage.image else { return }
        guard let imageData = UIImageJPEGRepresentation(image, 0.2) else { return }
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        
        storageRef.putData(imageData, metadata: metaData) {metaData, error in
            if error == nil, metaData != nil {
                storageRef.downloadURL { url, error in
                    registerKasamData(imageUrl: url!.absoluteString)
                }
            } else {
                //error
            }
        }
        
        //Function which registers Kasam Data in Firebase RT Database
        func registerKasamData (imageUrl: String) {
            
            let kasamDictionary = ["Title": newKasamTitle.text!, "Genre": newKasamType.text!, "Description": newKasamDescription.text!, "Timing":newKasamTitle.text!, "Image": imageUrl, "KasamID": kasamID.key, "CreatorID": Auth.auth().currentUser?.uid, "CreatorName": Auth.auth().currentUser?.displayName, "Followers": "", "Type": "Expert", "Wins": "5", "Blocks": "7"]
            
            kasamID.setValue(kasamDictionary) {
                (error, reference) in
                if error != nil {
                    print(error!)
                } else {
                    //kasam successfully created
                }
            }
        }
    }
}

//Sets the selected image as the kasam image in create view
extension NewKasamViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController){
        picker.dismiss(animated: true, completion: nil)
    }
    
    private func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.profileImage.image = pickedImage
        }
        picker.dismiss(animated: true, completion :nil)
    }
}
