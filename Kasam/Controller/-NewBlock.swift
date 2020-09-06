//
//  NewKasamViewController.swift
//  Kasam 1.0
//
//  Created by Vance Basilio on 2019-04-23.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import FirebaseDatabase
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
    @IBOutlet weak var reviewKasamButton: UIButton!
    
    var imagePicker: UIImagePickerController!
    var kasamIDGlobal = ""
    var kasamImageGlobal = ""
    var headerBlurImageView: UIImageView!
    var headerImageView: UIImageView!
    var storageRef = Storage.storage().reference()
    let animationView = AnimationView()
    let animationOverlay = UIView()
    
    //edit Kasam
    var kasamDatabase = Database.database().reference().child("Coach-Kasams")
    var kasamDatabaseHandle: DatabaseHandle!
    var personalKasamBlocksDatabase = Database.database().reference().child("Coach-Kasams")
    var personalKasamBlocksDatabaseHandle: DatabaseHandle!
    var blockDuration = [Int:String]()
    var tempBlockNoSelected = 1

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLoad()
    }
    
    @IBAction func blockSliderChanged(_ sender: UISlider) {
        let valueSelected = Int(sender.value)
        newBlockPicker.selectRow(valueSelected - 1, inComponent: 0, animated: true)
        NewKasam.numberOfBlocks = valueSelected
        if NewKasam.kasamTransferArray[valueSelected] == nil {
            NewKasam.kasamTransferArray[valueSelected] = NewKasamLoadFormat(blockTitle: "", duration: 15, durationMetric: "secs", complete: false)
        }
        tableView.reloadData()
    }
    
    func setupLoad(){
        //setup radius for kasam info block
        self.hideKeyboardWhenTappedAround()
        reviewKasamButton.layer.cornerRadius = reviewKasamButton.frame.height / 2
        reviewKasamButton.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight:.regular), prefixTextColor: UIColor.white, icon: .fontAwesomeSolid(.arrowRight), iconColor: UIColor.white, postfixText: "", postfixTextFont: UIFont.systemFont(ofSize: 15, weight:.medium), postfixTextColor: UIColor.white, backgroundColor: UIColor.black, forState: .normal, iconSize: 25)
        
        //load in the existing kasam data to be visible on the VC
        blockPickerBG.layer.cornerRadius = 15
        if NewKasam.kasamTransferArray.count == 0 {
            NewKasam.numberOfBlocks = 1
        } else {
            NewKasam.numberOfBlocks = NewKasam.kasamTransferArray.count
        }
        newBlockPicker.selectRow(NewKasam.numberOfBlocks - 1, inComponent: 0, animated: false)
        blockSlider.setValue(Float(NewKasam.numberOfBlocks), animated: false)
        //setup the first block
        if NewKasam.kasamTransferArray[1] == nil {
            NewKasam.kasamTransferArray[1] = NewKasamLoadFormat(blockTitle: "", duration: 15, durationMetric: "secs", complete: false)
        }
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.barStyle = .blackOpaque
        let navigationFont = UIFont.systemFont(ofSize: 20, weight: .semibold)
        self.navigationController?.navigationBar.backgroundColor = UIColor.white
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.init(hex: 0x4b3b00), NSAttributedString.Key.font: navigationFont]
        self.navigationController?.navigationBar.barTintColor = UIColor.white               //set navigation bar color BG to white
        self.navigationController?.navigationBar.tintColor = UIColor.colorFour              //set back button to gold color
        setStatusBarColor(color: UIColor.white)
    }
    
    @IBAction func reviewKasamButtonPressed(_ sender: Any) {
        self.view.endEditing(true)                  //for adding last text field value with dismiss keyboard
        NotificationCenter.default.post(name: Notification.Name(rawValue: "GoToNext"), object: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.tintColor = UIColor.colorFour              //set back button to gold color
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

extension NewBlockController: UITableViewDataSource, UITableViewDelegate, NewBlockDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return NewKasam.numberOfBlocks
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewBlockCell") as! NewBlockCell
        cell.setupFormatting()
        if NewKasam.editKasamCheck == true && NewKasam.dataLoadCheck == true && NewKasam.kasamTransferArray[indexPath.row + 1] != nil {
            cell.loadKasamInfo(block: NewKasam.kasamTransferArray[indexPath.row + 1]!)
        } else {
            cell.completionCheck()
        }
        cell.delegate = self
        cell.blockNo = indexPath.row + 1
        cell.repeatsLabel.text = getRepeatLabel(daynumber: (indexPath.row + 1))
        cell.dayNumber.text = String(indexPath.row + 1)
        cell.titleTextField.delegate = self as? UITextFieldDelegate
        cell.titleTextField.tag = 1
        cell.titleTextField.addTarget(self, action: #selector(onTextChanged(sender:)), for: UIControl.Event.editingChanged)
        return cell
    }
    
    func getRepeatLabel(daynumber: Int) -> String {
        var dayArray = [String]()
        for day in stride(from: daynumber, through: 30, by: NewKasam.numberOfBlocks) {
            dayArray.append(String(day))
        }
        var finalArray = [String]()
        if dayArray.count > 3 {
            finalArray = dayArray.prefix(3) + [dayArray.last!]
        } else {
            finalArray = dayArray
        }
        let label = "Repeats on Day \(finalArray.dayArraySentence)"
        return label
    }
        
    //Block Title added
    @objc func onTextChanged(sender: UITextField) {
        let cell: UITableViewCell = sender.superview?.superview?.superview?.superview?.superview as! UITableViewCell
        let table: UITableView = cell.superview as! UITableView
        let indexPath = table.indexPath(for: cell)
        let row = (indexPath?.row ?? 1)
        if sender.tag == 1 {
            NewKasam.kasamTransferArray[row + 1]?.blockTitle = sender.text!
        }
    }
    
    //Block Duration added
    func sendDurationTime(blockNo: Int, duration: String) {
        NewKasam.kasamTransferArray[blockNo]?.duration = Int(duration) ?? 15             //only runs when the picker is slided
    }
    
    //Block Duration Metric added
    func sendDurationMetric(blockNo: Int, metric: String) {
        NewKasam.kasamTransferArray[blockNo]?.durationMetric = metric                    //only runs when the picker is slided
    }
    
    func addActivityButtonPressed(blockNo: Int) {
        tempBlockNoSelected = blockNo                                           //starting from 1
        self.performSegue(withIdentifier: "goToCreateActivity", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToCreateActivity" {
            let kasamTransferHolder = segue.destination as! NewActivity
            kasamTransferHolder.blockNoSelected = tempBlockNoSelected
            //when save button is pressed on the newActivityCell, it saves the data into a 'result' matrix and passes it to the fullActivityMatrix
            kasamTransferHolder.callback = { result in
                NewKasam.fullActivityMatrix[self.tempBlockNoSelected] = result
            }
        }
    }
}
