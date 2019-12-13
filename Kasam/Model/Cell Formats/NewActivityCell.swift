//
//  NewActivityCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-11-14.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import SDWebImage
import SwiftEntryKit
import SkyFloatingLabelTextField
import HGCircularSlider
import SwiftIcons

protocol NewActivityCellDelegate {
    func showChooseSourceTypeAlert()
    func saveActivityData(activityNo: Int, title: String?, description: String?, image: UIImage?, reps: Int?, hour: Int?, min: Int?, sec: Int?)
}

class NewActivityCell:UICollectionViewCell, UITextViewDelegate {
    
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var bottomView: UIStackView!
    @IBOutlet weak var circularSlider: CircularSlider!
    @IBOutlet weak var animatedImageView: SDAnimatedImageView!
    @IBOutlet weak var animatedImageMask: UIButton!
    @IBOutlet weak var activityNumber: UILabel!
    @IBOutlet weak var activityTitle: SkyFloatingLabelTextField!
    @IBOutlet weak var activityDescription: UITextView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var restImageView: UIImageView!
    @IBOutlet weak var restTitle: UILabel!
    @IBOutlet weak var restDescription: UILabel!
    @IBOutlet weak var repsPicker: UIPickerView!
    @IBOutlet weak var repsLabel: UIStackView!
    @IBOutlet weak var timePickerStackView: UIStackView!
    @IBOutlet weak var timeLabels: UIStackView!
    @IBOutlet weak var hourPicker: UIPickerView!
    @IBOutlet weak var minsPicker: UIPickerView!
    @IBOutlet weak var secsPicker: UIPickerView!
    @IBOutlet weak var instruction: UILabel!
    @IBOutlet weak var restView: UIStackView!
    @IBOutlet weak var backButton: UIButton!
    
    var delegate: NewActivityCellDelegate?
    var activityNo = 0
    var currentOrder = 0
    var totalOrder = 0
    var repsChosen = 0
    var hourChosen = 0
    var minsChosen = 0
    var secsChosen = 0
    var increment = 10              //for the reps slider
    
    //Timer variables
    var maxTime: TimeInterval = 0   //set max timer value
    var currentTime = 0.0
    var countdownTimerDidStart = false
    var timerOrCountdown = ""
    lazy var countdownTimer: CountdownTimer = {let countdownTimer = CountdownTimer(); return countdownTimer}()
    
    //Placeholders
    let descriptionPlaceholder = "Activity Description"
    let imagePlaceholder = UIImage(named: "placeholder-add-activity")
    var addedImage: UIImage?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        activityNumber.text = "1/1"
        activityTitle.textAlignment = .center
        activityDescription.textColor = UIColor.lightGray
        activityDescription.delegate = self
        animatedImageView.layer.cornerRadius = 20.0
        backButton?.setIcon(icon: .fontAwesomeSolid(.arrowLeft), iconSize: 20, color: UIColor.init(hex: 0x79787e), forState: .normal)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.darkGray
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = descriptionPlaceholder
            textView.textColor = UIColor.lightGray
        }
    }
    
    //BUTTONS-------------------------------------------------
    
    @IBAction func imageClicked(_ sender: Any) {
        delegate?.showChooseSourceTypeAlert()
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        saveProgress()
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        saveProgress()
    }
    
    func saveProgress(){
        if activityDescription.text == descriptionPlaceholder {activityDescription.text = ""}
        if animatedImageView.image != imagePlaceholder {addedImage = animatedImageView.image}
        delegate?.saveActivityData(activityNo: activityNo, title: activityTitle.text, description: activityDescription.text, image: addedImage, reps: repsChosen, hour: hourChosen, min: minsChosen, sec: secsChosen)
    }
    
    //Setup Functions---------------------------------------
    
    func setKasamViewer(title: String?, description: String?, image: UIImage?) {
        restView.isHidden = true
        doneButton.layer.cornerRadius = 20.0
        currentOrder = 1
        totalOrder = 1
        activityTitle.text = title
        activityDescription.textContainer.maximumNumberOfLines = 3
        activityDescription.textContainer.lineBreakMode = .byClipping
        //set placeholders
        if description != "" && description != nil {
            activityDescription.text = description
            activityDescription.textColor = UIColor.darkGray
        } else {
            activityDescription.text = descriptionPlaceholder
        }
        if image != nil {animatedImageView.image = image}
        doneButton.setTitle("Save", for: .normal)
    }
    
    //TIMER----------------------------------------------------------
    
    func setupTimer(hour: Int?, min: Int?, sec: Int?){
        //hide picker views
        animatedImageView.isHidden = true
        repsPicker.isHidden = true
        repsLabel.isHidden = true
        instruction.isHidden = true
        animatedImageMask.isHidden = true
        
        //setup timer
        maxTime = 0.0
        countdownTimer.setTimer(time: 60)
        circularSlider?.endPointValue = CGFloat(0.0)
        circularSlider?.endThumbImage = UIImage(named: "kasam-timer-button")
        circularSlider?.minimumValue = 0.0
        circularSlider?.maximumValue = CGFloat(60.0)
        circularSlider?.endPointValue = CGFloat(60.0)
        circularSlider?.isUserInteractionEnabled = false
        
        hourPicker.delegate = self
        hourPicker.dataSource = self
        minsPicker.delegate = self
        minsPicker.dataSource = self
        secsPicker.delegate = self
        secsPicker.dataSource = self
        
        //get the past entries loaded in
        hourPicker.selectRow(hour ?? 0, inComponent: 0, animated: false)
        minsPicker.selectRow(min ?? 0, inComponent: 0, animated: false)
        secsPicker.selectRow(sec ?? 0, inComponent: 0, animated: false)
    }
    
    //REPS PICKER-----------------------------------------------------------------------------------
    
    func setupPicker(reps: Int?){
        timeLabels.isHidden = true
        timePickerStackView.isHidden = true
        repsPicker.delegate = self
        repsPicker.dataSource = self
        doneButton.layer.cornerRadius = 20.0
        circularSlider.isHidden = true
        instruction.isHidden = true
        
        //get the past entries loaded in
        repsPicker.selectRow(reps ?? 0, inComponent: 0, animated: false)
    }
    
    //CHECKMARK---------------------------------------------------
    
    func setupCheckmark(){
        //hide picker views
        repsPicker.isHidden = true
        instruction.isHidden = true
        circularSlider.isHidden = true
        repsLabel.isHidden = true
        timeLabels.isHidden = true
    }
    
    //REST-------------------------------------------------------
    
    func setupRest() {
        topView.isHidden = true
        bottomView.isHidden = true
        restTitle.text = ""
        restDescription.text = ""
        restImageView.sd_setImage(with: URL(string: "https://firebasestorage.googleapis.com/v0/b/kasam-coach.appspot.com/o/kasam%2FRest_animation.gif?alt=media&token=347b9eca-6d37-40fc-82f3-12483d71e440"))
    }
}

extension NewActivityCell: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        pickerView.subviews.forEach({$0.isHidden = $0.frame.height < 1.0})
        switch pickerView {
            case repsPicker: return 300
            case hourPicker: return 24
            case minsPicker: return 60
            case secsPicker: return 60
            default: return 60
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label = UILabel()
        if let v = view as? UILabel { label = v }
        label.font = UIFont.systemFont(ofSize: 35, weight: .bold)
        label.textAlignment = .center
        switch pickerView {
            case repsPicker: label.text =  String(row * increment)
            default: label.text =  String(row)
        }
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 40.0
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
            case repsPicker: repsChosen = row
            case hourPicker: hourChosen = row
            case minsPicker: minsChosen = row
            case secsPicker: secsChosen = row
            default: repsChosen = 0
        }
    }
}
