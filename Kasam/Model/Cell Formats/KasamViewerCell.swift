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
    func nextItem()
}

class KasamViewerCell: UICollectionViewCell {

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
    var increment = 10         //for the reps slider
    
    //Timer variables
    var timer = Timer()
    var timerStatus = 0
    var endTime: Date?
    var maxTime: TimeInterval = 0
    var timeLeft: TimeInterval = 0 //set max value
    
    override func awakeFromNib() {
        textField.textAlignment = .center
        NotificationCenter.default.post(name: Notification.Name(rawValue: "RemoveLoadingAnimation"), object: self)
    }
    
    func setKasamViewer(activity: KasamActivityCellFormat) {
        activityTitle.text = activity.activityTitle
        activityDescription.text = activity.activityDescription
        currentOrder = activity.currentOrder
        totalOrder = activity.totalOrder
        timeLeft = (Double(activity.totalMetric) ?? 0.0)
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
    
    func setupTimer(){
        startButton.layer.cornerRadius = 20.0
        timerDoneButton.layer.cornerRadius = 20.0
        circularSlider?.endThumbImage = UIImage(named: "kasam-timer-button")
        circularSlider?.minimumValue = 0.0
        circularSlider?.maximumValue = CGFloat(timeLeft)
        circularSlider?.isUserInteractionEnabled = false
        maxTime = timeLeft
        endTime = Date().addingTimeInterval(timeLeft)
    }
    
    @objc func updateTime() {
        if timeLeft > 0 {
            timeLeft = endTime?.timeIntervalSinceNow ?? 0
            circularSlider?.endPointValue = CGFloat(maxTime - timeLeft)
            setInitialTime()
        } else {
            timeLabel.text = "00"
            timer.invalidate()
        }
    }
    
    func setInitialTime (){
        if timeLeft <= 60.0 {
            timeLabel.text = timeLeft.seconds
            timeMeasure.text = "seconds"
            if timeLeft <= 1.0 {
                timeMeasure.text = "second"
            }
        } else if timeLeft > 60 && timeLeft <= 3600 {
            timeLabel.text = timeLeft.minutes
            timeMeasure.text = "minutes"
            if timeLeft < 120 {
                timeMeasure.text = "minute"
            }
        }
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
            NotificationCenter.default.post(name: Notification.Name(rawValue: "ChalloStatsUpdate"), object: self)
        } else {
            delegate?.nextItem()
        }
    }
    
    @IBAction func timerDoneButton(_ sender: Any) {
        delegate?.dismissViewController()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateKasamStatus"), object: self)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "ChalloStatsUpdate"), object: self)
    }
    
    @IBAction func startButton(_ sender: Any) {
        if timerStatus == 0 {
            timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
            startButton.setTitle("Pause", for: .normal)
            timerStatus = 1
        } else {
            timer.invalidate()
            startButton.setTitle("Start", for: .normal)
            timerStatus = 0
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
