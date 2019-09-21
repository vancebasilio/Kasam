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
    func sendCompletedMatrix(key: Int, value: Int)
    func sendTime(key: Int, value: String)
    func nextItem()
}

class KasamViewerCell: UICollectionViewCell, CountdownTimerDelegate {

    @IBOutlet weak var animatedImageView: SDAnimatedImageView!
    @IBOutlet weak var activityTitle: UILabel!
    @IBOutlet weak var activityDescription: UILabel!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var activityNumber: UILabel!
    @IBOutlet weak var circularSlider: CircularSlider!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var instruction: UILabel!
    @IBOutlet weak var timeMeasure: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var timerDoneButton: UIButton!
    @IBOutlet weak var timerButtonStackView: UIStackView!
    @IBOutlet weak var textField: SkyFloatingLabelTextField!
    
    //slider variables
    var delegate: KasamViewerCellDelegate?
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
    var increment = 10              //for the reps slider
    
    //Timer variables
    var timer = Timer()
    var timerStatus = 0
    var endTime: Date?
    var maxTime: TimeInterval = 0   //set max timer value

    //Test Timer
    var countdownTimerDidStart = false
    lazy var countdownTimer: CountdownTimer = {let countdownTimer = CountdownTimer(); return countdownTimer}()
    
    override func awakeFromNib() {
        textField.textAlignment = .center
        NotificationCenter.default.post(name: Notification.Name(rawValue: "RemoveLoadingAnimation"), object: self)
    }
    
    func setupTimer(time: String){
        //hide picker views
        animatedImageView.isHidden = true
        doneButton.isHidden = true
        pickerView.isHidden = true
        instruction.isHidden = true
        
        //setup timer
        maxTime = Double(time) ?? 0.0
        countdownTimer.delegate = self
        countdownTimer.setTimer(time: maxTime)
        startButton.layer.cornerRadius = 20.0
        timerDoneButton.layer.cornerRadius = 20.0
        circularSlider?.endThumbImage = UIImage(named: "kasam-timer-button")
        circularSlider?.minimumValue = 0.0
        circularSlider?.maximumValue = CGFloat(maxTime)
        circularSlider?.isUserInteractionEnabled = false
    }
    
    //refreshes everytime the counter changes
    func countdownTime(timeTot: Double, timeBreak: (hours: String, minutes: String, seconds: String)) {
        circularSlider?.endPointValue = CGFloat(maxTime - timeTot)
        if timeTot < 59.0 {
            timeLabel.text = timeBreak.seconds
        } else if timeTot >= 59 && timeTot < 3600 {
            timeLabel.text = "\(timeBreak.minutes):\(timeBreak.seconds)"
        } else if timeTot >= 3600 {
            timeLabel.text = "\(timeBreak.hours):\(timeBreak.minutes):\(timeBreak.seconds)"
        }
    }
    
    func countdownTimerDone() {
        timeLabel.text = "Done!"
        countdownTimerDidStart = false
    }
    
    func setKasamViewer(activity: KasamActivityCellFormat) {
        activityTitle.text = activity.activityTitle
        activityDescription.text = activity.activityDescription
        currentOrder = activity.currentOrder
        totalOrder = activity.totalOrder
        pickerMetric = (Int(activity.totalMetric) ?? 20) / increment
        pickerView.reloadAllComponents() //important so that the pickerview updates to the max metric
        activityNumber.text = "\(activity.currentOrder)/\(activity.totalOrder)"
        animatedImageView.sd_setImage(with: URL(string: activity.image))
        if currentOrder == totalOrder {
            doneButton.setTitle("Done", for: .normal)
        } else {
            doneButton.setTitle("Next", for: .normal)
        }
    }
    
    func setupPicker(){
        pickerView.selectRow(16, inComponent: 0, animated: false)
        pickerView.delegate = self
        pickerView.dataSource = self
        doneButton.layer.cornerRadius = 20.0
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
    }
    
    @IBAction func doneButton(_ sender: UIButton) {
        if currentOrder == totalOrder {
            delegate?.dismissViewController()
            NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateKasamStatus"), object: self)
        } else {
            delegate?.nextItem()
        }
    }
    
    @IBAction func timerDoneButton(_ sender: Any) {
        delegate?.dismissViewController()
        let currentTime = getCurrentDateTime()
        delegate?.sendTime(key: currentOrder, value: currentTime ?? "")
        NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateKasamStatus"), object: self)
    }
    
    @IBAction func startButton(_ sender: Any) {
        if !countdownTimerDidStart{
            countdownTimer.start()
            countdownTimerDidStart = true
            startButton.setTitle("Pause",for: .normal)
            
        } else{
            countdownTimer.pause()
            countdownTimerDidStart = false
            startButton.setTitle("Resume",for: .normal)
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
        delegate?.sendCompletedMatrix(key: currentOrder, value: row * increment)
    }
}

extension TimeInterval {
    var seconds: String {
        return String(format:"%02d", Int(ceil(truncatingRemainder(dividingBy: 60))))
    }
    var minutes: String {
        return String(format:"%02d", Int(self/60))
    }
    var minutesSeconds: String {
        return String(format:"%02d:%02d", Int(self/60), Int(ceil(truncatingRemainder(dividingBy: 60))))
    }
}
