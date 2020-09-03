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
    func removeAnimations()
    func sendCompletedMatrix(activityNo: Int, value: Double, max: Double)
    func setRestDay()
    func nextItem()
}

class KasamViewerCell: UICollectionViewCell, CountdownTimerDelegate, YTPlayerViewDelegate {

    @IBOutlet weak var animatedImageView: SDAnimatedImageView!
    @IBOutlet weak var activityTitle: UILabel!
    @IBOutlet weak var downArrow: UIButton!
    @IBOutlet weak var activityDescription: UILabel!
    
    @IBOutlet weak var pickerViewHolder: UIView!
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
    
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var bottomView: UIStackView!
    @IBOutlet weak var bottomViewHeight: NSLayoutConstraint!
    
    //Slider variables
    var delegate: KasamViewerCellDelegate?
    var kasamIDTransfer:[String: String] = ["kasamID": ""]
    var kasamID = ""
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
    
    //Program variables
    var today: Bool?
    
    override func awakeFromNib() {
        doneButton.layer.cornerRadius = 20.0
        resetButton.layer.cornerRadius = 20.0
        timerDoneButton.layer.cornerRadius = 20.0
        doneCancelButton.layer.cornerRadius = doneCancelButton.frame.height / 2
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
        kasamID = activity.kasamID
        increment = Int(activity.increment ?? "1") ?? 1
        pickerMetric = (Int(activity.totalMetric)) / increment
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
        
        if currentOrder == totalOrder {doneButton.setTitle("Done", for: .normal)}
        else {doneButton.setTitle("Next", for: .normal)}
        if viewOnlyCheck == true {self.resetButton.isHidden = true}
    }
    
    //PROGRAM POPUP-----------------------------------------------------------------------------------
    
    func programGestures(){
        downArrow.setIcon(icon: .fontAwesomeSolid(.sortDown), iconSize: 20, color: .darkGray, forState: .normal)
        if pastProgress <= 0.0 {
            downArrow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(programPopup)))
            activityTitle.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(programPopup)))
        } else if pastProgress > 0.0 {
            downArrow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pastProgressPopup)))
            activityTitle.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pastProgressPopup)))
        }
    }
    
    @objc func programPopup() {
        var blockArray = [(no: Int, blockID: String, blockName: String)]()
        DBRef.coachKasams.child(kasamID).child("Timeline").observeSingleEvent(of: .value) {(snap) in
            if let value = snap.value as? [String:String] {
                for blockIDRef in 1...value.count {
                    if let blockID = value["D\(blockIDRef)"] {
                        if blockID == "Rest" {
                            blockArray.append((blockIDRef, "rest", "Rest"))
                        } else {
                            DBRef.coachKasams.child(self.kasamID).child("Blocks").child(blockID).child("Title").observeSingleEvent(of: .value) {(blockName) in
                                blockArray.append((blockIDRef, blockID, blockName.value as! String))
                                if blockArray.count == snap.childrenCount {
                                    blockArray = blockArray.sorted(by: {$0.no < $1.no})
                                    showBottomPopup(type: "changeKasamBlock", array: blockArray)
                                }
                            }
                        }
                    }
                    
                }
            }
        }
    }
    
    @objc func pastProgressPopup(){
        showOptionsPopup(kasamID: nil, title: "Change Kasam Activity", subtitle: nil, text: "You already completed \(String(describing: activityTitle.text!)). Remove your progress to change the kasam activity.", type: "changeKasamBlock", button: "Okay") {(mainButtonPressed) in
            if mainButtonPressed == false {
                self.removeActivityProgress()
            }
        }
    }
    
    //COUNTDOWN-----------------------------------------------------------------------------------
    
    func setupCountdown(maxtime: Int){
        //hide picker views
        animatedImageView.isHidden = true
        doneButton.isHidden = true
        pickerViewHolder.isHidden = true
        instruction.isHidden = true
        kasamLogoBG.isHidden = true
        
        //setup timer
        maxTime = Double(maxtime) 
        countdownTimer.delegate = self
        
        if viewOnlyCheck == true {
            countdownTimer.setCountDown(time: maxTime)
        } else {
            if pastProgress >= maxTime {countdownTimerDone()}
            else {countdownTimer.setCountDown(time: maxTime - pastProgress.rounded(.up))}
        }
        
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
        pickerViewHolder.isHidden = true
        instruction.isHidden = true
        kasamLogoBG.isHidden = true
        
        //setup timer
        maxTime = 0.0
        countdownTimer.delegate = self
        countdownTimer.setTimer(time: pastProgress.rounded(.down))
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
        pickerViewHolder.isHidden = false
        pickerView.selectRow(Int(pastProgress) / 10, inComponent: 0, animated: false)
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
        pickerViewHolder.isHidden = true
        instruction.isHidden = true
        resetButton.isHidden = true
        circularSlider.isHidden = true
        if type != "rest" {bottomViewHeight = bottomViewHeight.constraintWithMultiplier(0.45, view: view)}
        
        if pastProgress > 0.0 {
            doneButton.setIcon(prefixText: "  ", prefixTextColor: .white, icon: .fontAwesomeRegular(.checkCircle), iconColor: .white, postfixText: "  Completed!", postfixTextColor: .white, backgroundColor: .dayYesColor, forState: .normal, textSize: 17, iconSize: 20)
            doneCancelButton.setIcon(icon: .fontAwesomeSolid(.undo), iconSize: 18, color: .white, backgroundColor: UIColor.init(hex: 0xf15e4a), forState: .normal)
            doneCancelButton.isHidden = false
        } else if pastProgress == 0.0 {
            doneButton.setIcon(prefixText: "  ", prefixTextColor: .white, icon: .fontAwesomeRegular(.clock), iconColor: .white, postfixText: "  Mark Complete", postfixTextColor: .white, backgroundColor: .black, forState: .normal, textSize: 16, iconSize: 18)
            doneCancelButton.isHidden = true
        } else {
            doneButton.setIcon(prefixText: "  ", prefixTextColor: .white, icon: .fontAwesomeRegular(.clock), iconColor: .white, postfixText: "Done", postfixTextColor: .white, backgroundColor: .black, forState: .normal, textSize: 16, iconSize: 0)
        }
        if SavedData.kasamDict[kasamID]?.programDuration != nil {
            programGestures()
        }
    }
    
    //VIDEO---------------------------------------------------------------------------------------
    
    func setVideoPlayer(){
        setupCheckmark()
        videoPlayerHolder.isHidden = false
        videoPlayer.delegate = self
        videoPlayer.load(withVideoId: videoURL ?? "")
    }
    
    func playerViewPreferredWebViewBackgroundColor(_ playerView: YTPlayerView) -> UIColor {
        return .clear
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
        setupCheckmark()
        videoPlayerHolder.isHidden = true
        bottomViewHeight = bottomViewHeight.constraintWithMultiplier(0.25, view: view)
        activityTitle.text = "Rest Day"
        activityDescription.text = "Take the day off. You've earned it!"
        animatedImageView.sd_setImage(with: URL(string: PlaceHolders.kasamActivityRestImageURL))
    }
    
    //DONE BUTTON----------------------------------------------------------------------------
    
    @IBAction func doneButton(_ sender: UIButton) {             //for regular kasam done + rest done
        if currentOrder == totalOrder {
            if viewOnlyCheck == false {
                if type == "checkmark" {
                    if pastProgress == 0.0 {
                        delegate?.sendCompletedMatrix(activityNo: currentOrder, value: 100.0, max: 100.0)
                        delegate?.removeAnimations()
                    }
                    delegate?.dismissViewController()
                } else if type == "video" {
                    if pastProgress == 0.0 {
                        delegate?.sendCompletedMatrix(activityNo: currentOrder, value: videoDuration, max: videoDuration)
                        delegate?.removeAnimations()
                        pastProgress = videoDuration
                        setupCheckmark()
                        programGestures()
                    } else {
                        delegate?.dismissViewController()
                    }
                } else if type == "rest" {
                    delegate?.setRestDay()
                    delegate?.dismissViewController()
                } else {
                    savePickerValue()
                }
            } else {
                delegate?.dismissViewController()
            }
        } else {
            delegate?.nextItem()
        }
    }
    
    @IBAction func doneCancelButtonPressed(_ sender: Any) {
        removeActivityProgress()
    }
    
    func removeActivityProgress(){
        delegate?.sendCompletedMatrix(activityNo: currentOrder, value: 0.0, max: 100)   //set Firebase progress to zero
        delegate?.removeAnimations()
        pastProgress = 0.0      //manually set progress to zero
        setupCheckmark()
        programGestures()
    }
    
    //Have to keep this function for the pickerValue check on top
    func savePickerValue(){
        //User recording progress, so save it
        if (pickerViewIsScrolling){
            shouldSave = true
            animationView.loadingAnimation(view: view, animation: "loading", width: 100, overlayView: nil, loop: true, buttonText: nil, completion: nil)
            return
        }
        delegate?.removeAnimations()
        delegate?.dismissViewController()
    }
    
    @IBAction func timerDoneButton(_ sender: Any) {
        delegate?.dismissViewController()
        if viewOnlyCheck == false {
            delegate?.sendCompletedMatrix(activityNo: currentOrder, value: (maxTime - currentTime), max: maxTime)
            delegate?.removeAnimations()
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
