//
//  NewActivity.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-11-14.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Firebase
import SwiftIcons

class NewActivity: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, NewActivityCellDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var closeButton: UIButton!
    
    var imagePicker: UIImagePickerController!
    var imagePicked = UIImage(named:"placeholder-add-activity2")
    var activityBlocks: [KasamActivityCellFormat] = []
    var registerNewActivity: [Int:newActivityFormat] = [:]
    var activityType = "Reps Counter"
    var blockNoSelected = 1
    var pastEntry: [Int:newActivityFormat]? = [:]
    var callback : (([Int: newActivityFormat])->())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        self.tabBarController?.tabBar.isHidden = false
    }
    
    func setupButtons() {
        UIApplication.shared.endIgnoringInteractionEvents()
        closeButton?.setIcon(icon: .fontAwesomeSolid(.arrowLeft), iconSize: 20, color: UIColor.init(hex: 0x79787e), forState: .normal)
    }
    
    @IBAction func closeButtonPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    func saveActivityData(activityNo: Int, title: String, description: String, image: UIImage, reps: Int?, hour: Int?, min: Int?, sec: Int?) {
        registerNewActivity[activityNo] = newActivityFormat(title: title, description: description, image: image, reps: reps, hour: hour, min: min, sec: sec)
        callback?(registerNewActivity)
        _ = navigationController?.popViewController(animated: true)
    }
    
    func showChooseSourceTypeAlertController() {
        print("hello")
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
            imagePicked = editedImage.withRenderingMode(.alwaysOriginal)
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imagePicked = originalImage.withRenderingMode(.alwaysOriginal)
        }
        collectionView.reloadData()
        dismiss(animated: true, completion: nil)
    }
}


extension NewActivity: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.size.width, height: view.frame.size.height)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewActivityCell", for: indexPath) as! NewActivityCell
        cell.activityNo = indexPath.row
        cell.animatedImageView.image = imagePicked
        cell.delegate = self
        let entryTransfer = pastEntry?[0]
        cell.setKasamViewer(title: entryTransfer?.title, description: entryTransfer?.description, image: entryTransfer?.image)
        if activityType == "Reps Counter" {
            cell.setupPicker(reps: entryTransfer?.reps)
        } else if activityType == "Timer" {
            cell.setupTimer(hour: entryTransfer?.hour, min: entryTransfer?.min, sec: entryTransfer?.sec)
        } else if activityType == "Checkmark" {
            cell.setupCheckmark()
        } else if activityType == "Rest" {
            cell.setupRest()
        }
        return cell
    }
}
