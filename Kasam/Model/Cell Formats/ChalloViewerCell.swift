//
//  KasamViewerCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-09-05.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import SDWebImage
import SwiftEntryKit
import SkyFloatingLabelTextField
import HGCircularSlider

protocol KasamViewerCellDelegate {
    func dismissViewController()
    func sendCompletedMatrix(key: Int, value: Double, text: String)
    func nextItem()
}

class KasamViewerCell: UICollectionViewCell, CountdownTimerDelegate {

    @IBOutlet weak var animatedImageView: SDAnimatedImageView!
    @IBOutlet weak var activityTitle: UILabel!
    @IBOutlet weak var activityDescription: UILabel!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var circularSlider: CircularSlider!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var instruction: UILabel!
    @IBOutlet weak var timerStartStop: UILabel!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var timerDoneButton: UIButton!
    @IBOutlet weak var timerButtonStackView: UIStackView!
    @IBOutlet weak var textField: SkyFloatingLabelTextField!
    @IBOutlet weak var maskButton: UIButton!
    @IBOutlet weak var restImageView: UIImageView!
    
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var bottomView: UIStackView!
    
    @IBOutlet weak var restTitle: UILabel!
    @IBOutlet weak var restDescription: UILabel!
    @IBOutlet weak var restDoneButton: UIButton!
    @IBOutlet weak var restView: UIStackView!
    
    //slider variables
    var delegate: KasamViewerCellDelegate?
    var kasamIDTransfer:[String: String] = ["kasamID": ""]
    var buttoncheck = 0       //to stop and start the gif
    var pickerMetric = 0
    var currentMetric = 0
    var tempCurrentMetric: Int?
    var metricMatrixValue = 0
    var metricMatrixKey = 0
    var currentOrder = 0
    var totalOrder = 0
    var metricTotalNo = 0.0
    var count = 0
    var increment = 1              //for the reps slider
    var viewOnlyCheck = false
    
    //Timer variables
    var maxTime: TimeInterval = 0   //set max timer value
    var currentTime = 0.0
    var countdownTimerDidStart = false
    var timerOrCountdown = ""
    lazy var countdownTimer: CountdownTimer = {let countdownTimer = CountdownTimer(); return countdownTimer}()
    
    override func awakeFromNib() {
        textField.textAlignment = .center
        NotificationCenter.default.post(name: Notification.Name(rawValue: "RemoveLoadingAnimation"), object: self)
    }
    
    //BASIC SETUP-----------------------------------------------------------------------------------
    
    func setKasamViewer(activity: KasamActivityCellFormat) {
        restView.isHidden = true
        textField.isHidden = true
        activityTitle.text = activity.activityTitle
        activityDescription.text = activity.activityDescription
        currentOrder = activity.currentOrder
        totalOrder = activity.totalOrder
        increment = Int(activity.increment ?? "1") ?? 1
        pickerMetric = (Int(activity.totalMetric) ?? 20) / increment
        pickerView.reloadAllComponents()                                    //important so that the pickerview updates to the max metric
        if activity.image == nil {
            if activity.imageURL == "" {
                animatedImageView.sd_setImage(with: URL(string: PlaceHolders.challoActivityPlaceholderURL))
            } else {
                animatedImageView.sd_setImage(with: URL(string: activity.imageURL))
            }
        } else {
            animatedImageView.image = activity.image
        }
        if currentOrder == totalOrder {
            doneButton.setTitle("Done", for: .normal)
        } else {
            doneButton.setTitle("Next", for: .normal)
        }
    }
    
    //COUNTDOWN-----------------------------------------------------------------------------------
    
    func setupCountdown(maxtime: String, pastProgress: Double){
        //hide picker views
        animatedImageView.isHidden = true
        doneButton.isHidden = true
        pickerView.isHidden = true
        instruction.isHidden = true
        timerOrCountdown = "countdown"
        
        //setup timer
        maxTime = Double(maxtime) ?? 0.0
        countdownTimer.delegate = self
        if pastProgress >= maxTime {
            countdownTimerDone()
        } else {
            countdownTimer.setCountDown(time: maxTime - pastProgress.rounded(.up))
        }
        resetButton.layer.cornerRadius = 20.0
        timerDoneButton.layer.cornerRadius = 20.0
        circularSlider?.endThumbImage = UIImage(named: "kasam-timer-button")
        circularSlider?.minimumValue = 0.0
        circularSlider?.maximumValue = CGFloat(maxTime)
        circularSlider?.endPointValue = CGFloat(pastProgress.rounded(.up))
        circularSlider?.isUserInteractionEnabled = false
    }
    
    //refreshes everytime the counter changes
    func countdownTime(timeTot: Double, timeBreak: (hours: String, minutes: String, seconds: String)) {
        circularSlider?.endPointValue = CGFloat(maxTime - timeTot)
        currentTime = timeTot                                         //sends this value to Firebase
        if timeTot < 60.0 {
            timeLabel.text = timeBreak.seconds
        } else if timeTot >= 60 && timeTot < 3600 {
            timeLabel.text = "\(timeBreak.minutes):\(timeBreak.seconds)"
        } else if timeTot >= 3600 {
            timeLabel.text = "\(timeBreak.hours):\(timeBreak.minutes)"
        }
    }
    
    func countdownTimerDone() {
        timeLabel.font = timeLabel.font.withSize(30)
        maskButton.isEnabled = false
        timeLabel.text = "Done!"
        timerStartStop.text = "Great Job"
        countdownTimerDidStart = false
    }
    
    //TIMER-----------------------------------------------------------------------------------
    
    func setupTimer(maxtime: String, pastProgress: Double){
        //hide picker views
        animatedImageView.isHidden = true
        doneButton.isHidden = true
        pickerView.isHidden = true
        instruction.isHidden = true
        textField.isHidden = true
        timerOrCountdown = "timer"
        
        //setup timer
        maxTime = 0.0
        countdownTimer.delegate = self
        countdownTimer.setTimer(time: pastProgress.rounded(.down))
        resetButton.layer.cornerRadius = 20.0
        timerDoneButton.layer.cornerRadius = 20.0
        circularSlider?.endThumbImage = UIImage(named: "kasam-timer-button")
        circularSlider?.minimumValue = 0.0
        circularSlider?.maximumValue = CGFloat(20.0)
        circularSlider?.endPointValue = CGFloat(Double(pastProgress.rounded(.down)))
        circularSlider?.isUserInteractionEnabled = false
    }
    
    //refreshes everytime the counter changes
    func timerTime(timeTot: Double, timeBreak: (hours: String, minutes: String, seconds: String)) {
        circularSlider?.endPointValue = CGFloat(timeTot)
        currentTime = -timeTot                               //sends this value to Firebase
        if timeTot < 60.0 {
            timeLabel.text = timeBreak.seconds
        } else if timeTot >= 60 && timeTot < 3600 {
            timeLabel.text = "\(timeBreak.minutes):\(timeBreak.seconds)"
        } else if timeTot >= 3600 {
            timeLabel.text = "\(timeBreak.hours):\(timeBreak.minutes)"
        }
    }
    
    //PICKER-----------------------------------------------------------------------------------
    
    func setupPicker(){
        pickerView.selectRow(16, inComponent: 0, animated: false)
        pickerView.delegate = self
        pickerView.dataSource = self
        doneButton.layer.cornerRadius = 20.0
        circularSlider.isHidden = true
        timerButtonStackView.isHidden = true
        instruction.isHidden = true
        textField.isHidden = true
    }
        
    @objc func stopActivityVideo(){
        animatedImageView.stopAnimating()
    }
    
    @IBAction func ActivityVideoButton(_ sender: Any) {
        if buttoncheck == 0 {
            animatedImageView.startAnimating()
            buttoncheck = 1
        } else if buttoncheck == 1 {
            animatedImageView.stopAnimating()
            buttoncheck = 0
        }
        if timerOrCountdown == "countdown" {
            if !countdownTimerDidStart {
                countdownTimer.start()
                countdownTimerDidStart = true
                timerStartStop.text = "tap to pause"
            } else{
                countdownTimer.pause()
                countdownTimerDidStart = false
                timerStartStop.text = "tap to start"
            }
        } else if timerOrCountdown == "timer" {
            if !countdownTimerDidStart {
                countdownTimer.startTimer()
                countdownTimerDidStart = true
                timerStartStop.text = "tap to pause"
            } else{
                countdownTimer.pause()
                countdownTimerDidStart = false
                timerStartStop.text = "tap to start"
            }
        }
    }
    
    //CHECKMARK------------------------------------------------------------------ -----------------
    
    func setupCheckmark(pastProgress: Double, pastText: String){
        //hide picker views
        doneButton.isHidden = true
        pickerView.isHidden = true
        instruction.isHidden = true
        circularSlider.isHidden = true
        textField.placeholder = "How was it?"
        if pastText != "" {textField.text = pastText}
        textField.title = "How was it?"
        textField.titleLabel.textAlignment = .center
        resetButton.layer.cornerRadius = 20.0
        resetButton.setTitle("I broke it...", for: .normal)
        timerDoneButton.setTitle("I kept it!", for: .normal)
        timerDoneButton.layer.cornerRadius = 20.0
        timerOrCountdown = "Checkmark"
    }
    
    //REST-----------------------------------------------------------------------------------
    
    func setupRest(activity: KasamActivityCellFormat) {
        topView.isHidden = true
        bottomView.isHidden = true
        restTitle.text = activity.activityTitle
        restDescription.text = activity.activityDescription
        restDoneButton.layer.cornerRadius = 20.0
        restImageView.sd_setImage(with: URL(string: PlaceHolders.challoActivityRestImageURL))
    }
    
    @IBAction func doneButton(_ sender: UIButton) {
        if currentOrder == totalOrder {
            if viewOnlyCheck == false {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateTodayBlockStatus"), object: self, userInfo: kasamIDTransfer)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "ChalloStatsUpdate"), object: self)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "MainStatsUpdate"), object: self)
            }
            delegate?.dismissViewController()
        } else {
            delegate?.nextItem()
        }
    }
    
    @IBAction func timerDoneButton(_ sender: Any) {
        delegate?.dismissViewController()
        if timerOrCountdown == "Checkmark" {
            delegate?.sendCompletedMatrix(key: currentOrder, value: 100.0, text: textField.text ?? "")
        } else {
            delegate?.sendCompletedMatrix(key: currentOrder, value: (maxTime - currentTime), text: textField.text ?? "")
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateTodayBlockStatus"), object: self, userInfo: kasamIDTransfer)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "ChalloStatsUpdate"), object: self)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "MainStatsUpdate"), object: self)
    }
    
    @IBAction func resetButtonPress(_ sender: Any) {
        if timerOrCountdown == "Checkmark" {
            delegate?.sendCompletedMatrix(key: currentOrder, value: 0.0, text: textField.text ?? "")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateTodayBlockStatus"), object: self, userInfo: kasamIDTransfer)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "ChalloStatsUpdate"), object: self)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "MainStatsUpdate"), object: self)
            delegate?.dismissViewController()
            
        } else {
            maskButton.isEnabled = true
            timeLabel.font = timeLabel.font.withSize(50)
            timerStartStop.text = "tap to start "
            countdownTimer.setCountDown(time: maxTime)
            countdownTimer.stop()
            countdownTimerDidStart = false
        }
    }
}

extension KasamViewerCell: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        pickerView.subviews.forEach({$0.isHidden = $0.frame.height < 1.0})
        return (pickerMetric + 1)
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label = UILabel()
        if let v = view as? UILabel { label = v }
        label.font = UIFont.systemFont(ofSize: 35, weight: .bold)
        label.text =  String(row * increment)
        label.textAlignment = .center
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 60.0
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if viewOnlyCheck == false {
            delegate?.sendCompletedMatrix(key: currentOrder, value: Double(row * increment), text: "")
        }
    }
}
