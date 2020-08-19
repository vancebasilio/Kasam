//
//  KasamViewerCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-09-05.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import SDWebImage
import SwiftEntryKit
import SkyFloatingLabelTextField
import HGCircularSlider
import Lottie
import youtube_ios_player_helper

protocol KasamViewerCellDelegate {
    func dismissViewController()
    func updateControllers()
    func sendCompletedMatrix(activityNo: Int, value: Double, max: Double)
    func nextItem()
}

class KasamViewerCell: UICollectionViewCell, CountdownTimerDelegate, YTPlayerViewDelegate {

    @IBOutlet weak var animatedImageView: SDAnimatedImageView!
    @IBOutlet weak var activityTitle: UILabel!
    @IBOutlet weak var activityDescription: UILabel!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var doneCancelButton: UIButton!
    @IBOutlet weak var circularSlider: CircularSlider!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var instruction: UILabel!
    @IBOutlet weak var timerStartStop: UILabel!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var timerDoneButton: UIButton!
    @IBOutlet weak var timerButtonStackView: UIStackView!
    @IBOutlet weak var maskButton: UIButton!
    @IBOutlet weak var view: UIView!
    
    @IBOutlet weak var kasamLogoBG: UIImageView!
    @IBOutlet weak var regularView: UIStackView!
    
    @IBOutlet weak var videoPlayerHolder: UIView!
    @IBOutlet weak var videoPlayer: YTPlayerView!
    
    @IBOutlet weak var restImageView: UIImageView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var bottomView: UIStackView!
    
    @IBOutlet weak var restTitle: UILabel!
    @IBOutlet weak var restDescription: UILabel!
    @IBOutlet weak var restDoneButton: UIButton!
    @IBOutlet weak var restView: UIStackView!
    
    //Slider variables
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
    var pastProgress = 0.0
    var startCheck = false
    var shouldSave = false
    let animationView = AnimationView()
    var pickerViewIsScrolling = false {didSet {if !pickerViewIsScrolling && shouldSave {savePickerValue()}}}
    
    //Timer variables
    var maxTime: TimeInterval = 0   //set max timer value
    var currentTime = 0.0
    var countdownTimerDidStart = false
    var type = ""
    lazy var countdownTimer: CountdownTimer = {let countdownTimer = CountdownTimer(); return countdownTimer}()
    
    //Video variables
    var videoDuration = 0.0
    var videoURL: String?
    
    override func awakeFromNib() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "RemovePersonalLoadingAnimation"), object: self)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "RemoveGroupLoadingAnimation"), object: self)
    }
    
    //BASIC SETUP-----------------------------------------------------------------------------------
    
    func setKasamViewer(activity: KasamActivityCellFormat) {
        kasamLogoBG.image = kasamLogoBG.image?.withRenderingMode(.alwaysTemplate)
        kasamLogoBG.tintColor = .lightGray
        activityTitle.text = activity.activityTitle
        activityDescription.text = activity.activityDescription
        currentOrder = activity.currentOrder
        totalOrder = activity.totalOrder
        increment = Int(activity.increment ?? "1") ?? 1
        pickerMetric = (Int(activity.totalMetric) ?? 20) / increment
        pickerView.reloadAllComponents()
        //Important so that the pickerview updates to the max metric
        if activity.videoURL != nil {
            videoURL = activity.videoURL
        } else if activity.image == nil {
            if activity.imageURL == nil && activity.videoURL == nil {
                animatedImageView.sd_setImage(with: URL(string: PlaceHolders.kasamActivityPlaceholderURL))
            } else if activity.imageURL != nil && activity.videoURL == nil {
                animatedImageView.sd_setImage(with: URL(string: activity.imageURL!))
            }
        } else {
            //Only activated when creating a Kasam and a full image is loaded in directly
            animatedImageView.image = activity.image
        }
        
        if currentOrder == totalOrder {
            doneButton.setTitle("Done", for: .normal)
        } else {
            doneButton.setTitle("Next", for: .normal)
        }
        if viewOnlyCheck == true {
            self.resetButton.isHidden = true
        }
    }
    
    //COUNTDOWN-----------------------------------------------------------------------------------
    
    func setupCountdown(maxtime: Int){
        //hide picker views
        animatedImageView.isHidden = true
        doneButton.isHidden = true
        pickerView.isHidden = true
        instruction.isHidden = true
        type = "countdown"
        
        //setup timer
        maxTime = Double(maxtime) 
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
    
    func setupTimer(maxtime: Int){
        //hide picker views
        animatedImageView.isHidden = true
        doneButton.isHidden = true
        pickerView.isHidden = true
        instruction.isHidden = true
        type = "timer"
        
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
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.selectRow(Int(pastProgress) / 10, inComponent: 0, animated: false)
        doneButton.layer.cornerRadius = 20.0
        circularSlider.isHidden = true
        timerButtonStackView.isHidden = true
        instruction.isHidden = true
        DispatchQueue.main.async {
            self.pickerViewIsScrolling = false
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
        if type == "countdown" {
            if !countdownTimerDidStart {
                countdownTimer.start()
                countdownTimerDidStart = true
                timerStartStop.text = "tap to pause"
            } else{
                countdownTimer.pause()
                countdownTimerDidStart = false
                timerStartStop.text = "tap to start"
            }
        } else if type == "timer" {
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
    
    func setupCheckmark(){
        //hide picker views
        timerButtonStackView.isHidden = true
        pickerView.isHidden = true
        instruction.isHidden = true
        resetButton.isHidden = true
        circularSlider.isHidden = true
        doneButton.layer.cornerRadius = 20.0
        type = "checkmark"
        if pastProgress > 0.0 {
            doneButton.setIcon(prefixText: "  ", prefixTextColor: .white, icon: .fontAwesomeRegular(.checkCircle), iconColor: .white, postfixText: "  Completed!", postfixTextColor: .white, backgroundColor: .dayYesColor, forState: .normal, textSize: 17, iconSize: 20)
            doneCancelButton.layer.cornerRadius = doneCancelButton.frame.height / 2
            doneCancelButton.setIcon(icon: .fontAwesomeSolid(.undo), iconSize: 18, color: .white, backgroundColor: UIColor.init(hex: 0xf15e4a), forState: .normal)
            doneCancelButton.isHidden = false
        } else {
            doneButton.setIcon(prefixText: "  ", prefixTextColor: .white, icon: .fontAwesomeRegular(.clock), iconColor: .white, postfixText: "  Mark Complete", postfixTextColor: .white, backgroundColor: .black, forState: .normal, textSize: 16, iconSize: 18)
            doneCancelButton.isHidden = true
        }
    }
    
    //VIDEO---------------------------------------------------------------------------------------
    
    func setVideoPlayer(){
        setupCheckmark()
        type = "video"
        videoPlayerHolder.isHidden = false
        videoPlayer.delegate = self
        videoPlayer.load(withVideoId: videoURL ?? "")
    }
    
    func playerViewPreferredWebViewBackgroundColor(_ playerView: YTPlayerView) -> UIColor {
        return .black
    }
    
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        videoDuration = playerView.duration()
    }
    
    func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
        if state.rawValue == 3 {
            print("hell0 \(Double(playerView.currentTime()) / playerView.duration())")
        }
    }
    
    //REST-----------------------------------------------------------------------------------
    
    func setupRest(activity: KasamActivityCellFormat) {
        restView.isHidden = false
        topView.isHidden = true
        bottomView.isHidden = true
        restTitle.text = activity.activityTitle
        restDescription.text = activity.activityDescription
        restDoneButton.layer.cornerRadius = 20.0
        restImageView.sd_setImage(with: URL(string: PlaceHolders.kasamActivityRestImageURL))
    }
    
    //DONE BUTTON----------------------------------------------------------------------------
    
    @IBAction func doneButton(_ sender: UIButton) {
        if currentOrder == totalOrder {
            if viewOnlyCheck == false {
                if type == "checkmark" {
                    if pastProgress == 0.0 {
                        delegate?.sendCompletedMatrix(activityNo: currentOrder, value: 100.0, max: 100.0)
                        delegate?.updateControllers()
                    }
                    delegate?.dismissViewController()
                } else if type == "video" {
                    if pastProgress == 0.0 {
                        delegate?.sendCompletedMatrix(activityNo: currentOrder, value: videoDuration, max: videoDuration)
                        delegate?.updateControllers()
                    }
                    delegate?.dismissViewController()
                } else {
                    savePickerValue()
                }
            }
        } else {
            delegate?.nextItem()
        }
    }
    
    @IBAction func doneCancelButtonPressed(_ sender: Any) {
        if pastProgress > 0.0 {
            delegate?.sendCompletedMatrix(activityNo: currentOrder, value: 0.0, max: 100)
            delegate?.updateControllers()
            delegate?.dismissViewController()
        }
    }
    
    
    func savePickerValue(){
        //User recording progress, so save it
        if (pickerViewIsScrolling){
            shouldSave = true
            animationView.loadingAnimation(view: view, animation: "loading", width: 100, overlayView: nil, loop: true, buttonText: nil, completion: nil)
            return
        }
        delegate?.updateControllers()
        delegate?.dismissViewController()
    }
    
    @IBAction func timerDoneButton(_ sender: Any) {
        delegate?.dismissViewController()
        if viewOnlyCheck == false {
            delegate?.sendCompletedMatrix(activityNo: currentOrder, value: (maxTime - currentTime), max: maxTime)
            delegate?.updateControllers()
        }
    }
    
    @IBAction func resetButtonPress(_ sender: Any) {
        if viewOnlyCheck == false {
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
        pickerViewIsScrolling = true
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
            pickerViewIsScrolling = false
            delegate?.sendCompletedMatrix(activityNo: currentOrder, value: Double(row * increment), max: Double(((pickerMetric) * increment)))
        }
    }
}
