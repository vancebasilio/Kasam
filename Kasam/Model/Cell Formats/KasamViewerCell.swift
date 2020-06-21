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
import HCVimeoVideoExtractor

protocol KasamViewerCellDelegate {
    func dismissViewController()
    func updateControllers()
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
    @IBOutlet weak var view: UIView!
    
    @IBOutlet weak var kasamLogoBG: UIImageView!
    @IBOutlet weak var regularView: UIStackView!
    
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var videoPlayer: UIView!
    @IBOutlet weak var videoControlsView: UIView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    @IBOutlet weak var videoTitle: UILabel!
    
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
    var pastProgress = 0.0
    var startCheck = false
    
    //Video variables
    var pauseState = false
    var player: AVPlayer?
    var timeObserver: Any?
    var timer: Timer?
    
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
        textField.isHidden = true
        kasamLogoBG.image = kasamLogoBG.image?.withRenderingMode(.alwaysTemplate)
        kasamLogoBG.tintColor = .lightGray
        activityTitle.text = activity.activityTitle
        activityDescription.text = activity.activityDescription
        currentOrder = activity.currentOrder
        totalOrder = activity.totalOrder
        increment = Int(activity.increment ?? "1") ?? 1
        pickerMetric = (Int(activity.totalMetric) ?? 20) / increment
        pickerView.reloadAllComponents()                                    //important so that the pickerview updates to the max metric
        if activity.image == nil {
            if activity.imageURL == nil && activity.videoURL == nil {
                regularView.isHidden = false
                animatedImageView.sd_setImage(with: URL(string: PlaceHolders.kasamActivityPlaceholderURL))
            } else if activity.imageURL != nil && activity.videoURL == nil {
                regularView.isHidden = false
                animatedImageView.sd_setImage(with: URL(string: activity.imageURL!))
            } else if activity.videoURL != nil {
                setVideoPlayer(url: URL(string: activity.videoURL!)!)
                resetTimer()
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
    
    //VIDEO---------------------------------------------------------------------------------------
    
    func setVideoPlayer(url: URL){
        videoView.isHidden = false
        playPauseButton.setIcon(icon: .fontAwesomeSolid(.pauseCircle), iconSize: 60, color: UIColor.colorFour, forState: .normal)
        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleControls))
        videoPlayer.addGestureRecognizer(tap)
        HCVimeoVideoExtractor.fetchVideoURLFrom(url: url, completion: {(video:HCVimeoVideo?, error:Error?) -> Void in
            if let err = error {
                print("Error = \(err.localizedDescription)")
                return
            }
            guard let vid = video else {
                print("Invalid video object")
                return
            }
            if let videoURL = vid.videoURL[.Quality720p] {
                DispatchQueue.main.async {
                    self.videoTitle.text = vid.title
                    self.player = AVPlayer(url: videoURL)
                    let layer = AVPlayerLayer(player: self.player)
                    layer.frame = self.videoPlayer.bounds
                    layer.videoGravity = .resizeAspectFill
                    self.videoPlayer.layer.addSublayer(layer)
                    self.player?.play()
                    self.videoControlsView.fadeIn()
                    let interval = CMTime(seconds: 0.01, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                    self.timeObserver = self.player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { elapsedTime in
                        self.updateVideoPlayerSlider()
                    })
                }
            }
        })
    }
    
    func updateVideoPlayerSlider() {
        guard let currentTime = player?.currentTime() else { return }
        let currentTimeInSeconds = CMTimeGetSeconds(currentTime)
        progressSlider.value = Float(currentTimeInSeconds)
        if let currentItem = player?.currentItem {
            let duration = currentItem.duration
            if (CMTIME_IS_INVALID(duration)) {
                return;
            }
            let currentTime = currentItem.currentTime()
            progressSlider.value = Float(CMTimeGetSeconds(currentTime) / CMTimeGetSeconds(duration))

            // Update time remaining label
            let totalTimeInSeconds = CMTimeGetSeconds(duration)
            if totalTimeInSeconds > 0 && startCheck == false {
                let secondsToStartAt = (self.pastProgress / 100) * totalTimeInSeconds
                self.player?.seek(to: CMTimeMakeWithSeconds(secondsToStartAt, preferredTimescale: currentItem.duration.timescale))
                startCheck = true
            }
            let remainingTimeInSeconds = totalTimeInSeconds - currentTimeInSeconds
            if currentTimeInSeconds == totalTimeInSeconds {
                playPauseButton.setIcon(icon: .fontAwesomeSolid(.redo), iconSize: 40, color: UIColor.colorFour, forState: .normal)
            }
            let mins = remainingTimeInSeconds / 60
            let secs = remainingTimeInSeconds.truncatingRemainder(dividingBy: 60)
            let timeformatter = NumberFormatter()
            timeformatter.minimumIntegerDigits = 2
            timeformatter.minimumFractionDigits = 0
            timeformatter.roundingMode = .down
            guard let minsStr = timeformatter.string(from: NSNumber(value: mins)), let secsStr = timeformatter.string(from: NSNumber(value: secs)) else {
                return
            }
            timeRemainingLabel.text = "\(minsStr):\(secsStr)"
        }
    }
    
    func resetTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(hideControls), userInfo: nil, repeats: false)
    }
    
    @objc func toggleControls() {
        if videoControlsView.alpha == 0 {videoControlsView.fadeIn()}
        else {videoControlsView.fadeOut()}
        resetTimer()
    }
    
    @objc func hideControls() {
        videoControlsView.fadeOut()
    }
    
    @IBAction func playPauseButtonTapped(_ sender: Any) {
        guard let player = player else { return }
        if !player.isPlaying {
            playPauseButton.setIcon(icon: .fontAwesomeSolid(.pauseCircle), iconSize: 60, color: UIColor.colorFour, forState: .normal)
            player.play()
        } else {
            playPauseButton.setIcon(icon: .fontAwesomeSolid(.playCircle), iconSize: 60, color: UIColor.colorFour, forState: .normal)
            player.pause()
        }
        resetTimer()
    }
    
    @IBAction func playbackSliderValueChanged(_ sender: Any) {
        guard let duration = player?.currentItem?.duration else { return }
        let value = Float64(progressSlider.value) * CMTimeGetSeconds(duration)
        let seekTime = CMTime(value: CMTimeValue(value), timescale: 1)
        player?.seek(to: seekTime)
        resetTimer()
    }
    
    //COUNTDOWN-----------------------------------------------------------------------------------
    
    func setupCountdown(maxtime: String){
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
    
    func setupTimer(maxtime: String){
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
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.selectRow(Int(pastProgress) / 10, inComponent: 0, animated: false)
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
    
    func setupCheckmark(pastText: String){
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
        restView.isHidden = false
        topView.isHidden = true
        bottomView.isHidden = true
        restTitle.text = activity.activityTitle
        restDescription.text = activity.activityDescription
        restDoneButton.layer.cornerRadius = 20.0
        restImageView.sd_setImage(with: URL(string: PlaceHolders.kasamActivityRestImageURL))
    }
    
    @IBAction func doneButton(_ sender: UIButton) {
        if currentOrder == totalOrder {
            if viewOnlyCheck == false {
                //user recording progress, so save it
                delegate?.updateControllers()
            }
            delegate?.dismissViewController()
        } else {
            delegate?.nextItem()
        }
    }
    
    @IBAction func timerDoneButton(_ sender: Any) {
        delegate?.dismissViewController()
        if viewOnlyCheck == false {
            if timerOrCountdown == "Checkmark" {
                delegate?.sendCompletedMatrix(key: currentOrder, value: 100.0, text: textField.text ?? "")
            } else {
                delegate?.sendCompletedMatrix(key: currentOrder, value: (maxTime - currentTime), text: textField.text ?? "")
            }
            delegate?.updateControllers()
        }
    }
    
    @IBAction func resetButtonPress(_ sender: Any) {
        if viewOnlyCheck == false {
            if timerOrCountdown == "Checkmark" {
                delegate?.sendCompletedMatrix(key: currentOrder, value: 0.0, text: textField.text ?? "")
                NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateTodayBlockStatus"), object: self, userInfo: kasamIDTransfer)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "KasamStatsUpdate"), object: self)
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
