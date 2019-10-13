//
//  NewBlockViewController.swift
//  Kasam 1.0
//
//  Created by Vance Basilio on 2019-04-23.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import SkyFloatingLabelTextField

class NewBlockViewController: UIViewController {
    
    @IBOutlet weak var newBlockPicker: UIPickerView!
    
    var imagePicker: UIImagePickerController!
    var kasamID = ""
    var numberOfBlocks = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func createBlocksButton(_ sender: Any) {
        let newBlock = Database.database().reference().child("Coach-Kasams").child(kasamID).child("Blocks")
        for i in 1...30 {
            let blockID = newBlock.childByAutoId()
            let activity = ["Description" : "",
                "Image" : "",
                "Metric" : "",
                "Title" : "",
                "Type" : "Countdown"]
            let blockDictionary = ["Activity": activity, "Duration": "", "Image": "", "Order": String(i), "Rating": "", "Title": "", "BlockID": blockID.key!] as [String : Any]
            
            blockID.setValue(blockDictionary) {
                (error, reference) in
                if error != nil {
                    print(error!)
                } else {
                    //kasam successfully created
                }
            }
        }
        dismiss(animated: true, completion: nil)
    }
}

extension NewBlockViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 30
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label = UILabel()
        if let v = view as? UILabel { label = v }
        label.font = UIFont.systemFont(ofSize: 35, weight: .bold)
        label.text =  String(row + 1)
        label.textAlignment = .center
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        numberOfBlocks = row + 1
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 60.0
    }
}

