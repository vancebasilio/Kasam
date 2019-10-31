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

class NewBlockViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var newBlockPicker: UIPickerView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var contentView: NSLayoutConstraint!
    
    var imagePicker: UIImagePickerController!
    var kasamID = ""
    var blockImage = ""
    var numberOfBlocks = 1
    var transferTitle = [Int:String]()
    var transferDuration = [Int:String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func updateContentTableHeight(){
        tableViewHeight.constant = CGFloat(70 * numberOfBlocks)
        let frame = self.view.safeAreaLayoutGuide.layoutFrame
        let contentViewHeight = tableViewHeight.constant + 380
        if contentViewHeight > frame.height {
            contentView.constant = contentViewHeight
        } else if contentViewHeight <= frame.height {
            let diff = UIScreen.main.bounds.height - contentViewHeight
            contentView.constant = tableViewHeight.constant + diff + 320
        }
    }
    
    @IBAction func createBlocksButton(_ sender: Any) {
        self.view.endEditing(true)                  //for adding last text field value with dismiss keyboard
        let newBlock = Database.database().reference().child("Coach-Kasams").child(kasamID).child("Blocks")
            for j in 1...numberOfBlocks {
                let blockID = newBlock.childByAutoId()
                let activity = ["Description" : "",
                    "Image" : "",
                    "Metric" : "",
                    "Title" : "",
                    "Type" : "Picker"]
                let blockDictionary = ["Activity": activity, "Duration": transferDuration[j] ?? "Duration", "Image": blockImage, "Order": String(j), "Rating": "5", "Title": transferTitle[j] ?? "Title", "BlockID": blockID.key!] as [String : Any]
            
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
        self.updateContentTableHeight()
        tableView.reloadData()
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 60.0
    }
}

extension NewBlockViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfBlocks
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewBlockCell") as! NewBlockCell
        cell.dayNumber.text = "Day \(indexPath.row + 1)"
        cell.titleTextField.delegate = self
        cell.durationTextField.delegate = self
        cell.titleTextField.tag = 1
        cell.durationTextField.tag = 2
        cell.titleTextField.addTarget(self, action: #selector(onTextChanged(sender:)), for: UIControl.Event.editingChanged)
        cell.durationTextField.addTarget(self, action: #selector(onTextChanged(sender:)), for: UIControl.Event.editingChanged)
        return cell
    }
    
    @objc func onTextChanged(sender: UITextField) {
        let cell: UITableViewCell = sender.superview?.superview?.superview as! UITableViewCell
        let table: UITableView = cell.superview as! UITableView
        let indexPath = table.indexPath(for: cell)
        let row = (indexPath?.row ?? 0) + 1
        if sender.tag == 1 {
            transferTitle[row] = sender.text!
        } else if sender.tag == 2 {
            transferDuration[row] = sender.text!
        }
    }
}
