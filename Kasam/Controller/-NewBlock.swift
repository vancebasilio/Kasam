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

class NewBlockController: UIViewController, UIScrollViewDelegate {
    
    //Twitter Parallax
    @IBOutlet weak var tableView: UITableView!  {didSet {tableView.estimatedRowHeight = 100}}
    @IBOutlet weak var profileView: UIView!
    @IBOutlet weak var newBlockPicker: UIPickerView!
    @IBOutlet weak var blockPickerBG: UIView!
    @IBOutlet weak var blockSlider: UISlider!
    @IBOutlet weak var newActivityLabel: UILabel!
    
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
    var challoTransferArray = [Int:NewChalloLoadFormat]()           //the INT in the dictinary is the blockNo
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
    var chosenMetric = "Reps"
    
    //Activity Variables
    var fullActivityMatrix = [Int: [Int: newActivityFormat]]()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLoad()
    }
    
    @IBAction func blockSliderChanged(_ sender: UISlider) {
        let valueSelected = Int(sender.value)
        newBlockPicker.selectRow(valueSelected - 1, inComponent: 0, animated: true)
        numberOfBlocks = valueSelected
        tableView.reloadData()
    }
    
    func setupLoad(){
        //setup radius for kasam info block
        self.hideKeyboardWhenTappedAround()
        blockPickerBG.layer.cornerRadius = 15
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.navigationBar.barStyle = .blackOpaque
        let navigationFont = UIFont.systemFont(ofSize: 20, weight: .semibold)
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.init(hex: 0x4b3b00), NSAttributedString.Key.font: navigationFont]
        self.navigationController?.navigationBar.barTintColor = UIColor.white
    }
    
}

extension NewBlockController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        pickerView.subviews.forEach({$0.isHidden = $0.frame.height < 1.0})   //removes the line above and below
        return 30
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
        }
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 50.0
    }
}

extension NewBlockController: UITableViewDataSource, UITableViewDelegate {
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

extension NewBlockController: NewBlockDelegate {
    
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
            
            //when save button is pressed on the newActivityCell, it saves the data into a 'result' matrix and passes it to the fullActivityMatrix
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
