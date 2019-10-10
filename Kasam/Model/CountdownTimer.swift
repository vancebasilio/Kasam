//
//  CountdownTimer.swift
//  CountdownTimer
//
//  Created by Jonni Akesson on 2017-04-20.
//  Copyright © 2017 Jonni Akesson. All rights reserved.
//

import UIKit

protocol CountdownTimerDelegate:class {
    func countdownTimerDone()
    func countdownTime(timeTot: Double, timeBreak: (hours: String, minutes:String, seconds:String))
    func timerTime(timeTot: Double, timeBreak: (hours: String, minutes:String, seconds:String))
}

class CountdownTimer {
    
    weak var delegate: CountdownTimerDelegate?
    
    fileprivate var seconds = 0.0
    fileprivate var duration = 0.0
    
    lazy var timer: Timer = {
        let timer = Timer()
        return timer
    }()
    
    public func setCountDown(time:Double) {
        self.seconds = time
        self.duration = time
        delegate?.countdownTime(timeTot: duration, timeBreak: timeString(time: TimeInterval(ceil(duration))))
    }
    
    public func setTimer(time:Double) {
        self.seconds = time
        self.duration = time
        delegate?.timerTime(timeTot: duration, timeBreak: timeString(time: TimeInterval(ceil(duration))))
    }
    
    public func start() {
        timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }
    
    public func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateTimerUp), userInfo: nil, repeats: true)
    }
    
    public func pause() {
        timer.invalidate()
    }
    
    public func stop() {
        timer.invalidate()
        duration = seconds
        delegate?.countdownTime(timeTot: duration, timeBreak: timeString(time: TimeInterval(ceil(duration))))
    }
    
    @objc fileprivate func updateTimer(){
        if duration < 0.0 {
            timer.invalidate()
            timerDone()
        } else {
            duration -= 0.01
            delegate?.countdownTime(timeTot: duration, timeBreak: timeString(time: TimeInterval((duration))))
        }
    }
    
    @objc fileprivate func updateTimerUp(){
        if duration < 0.0 {
            timer.invalidate()
            timerDone()
        } else {
            duration += 0.01
            delegate?.timerTime(timeTot: duration, timeBreak: timeString(time: TimeInterval((duration))))
        }
    }
    
    fileprivate func timeString(time:TimeInterval) -> (hours: String, minutes:String, seconds:String) {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return (hours: String(format:"%02i", hours), minutes: String(format:"%02i", minutes), seconds: String(format:"%02i", seconds))
    }
    
    fileprivate func timerDone() {
        timer.invalidate()
        duration = seconds
        delegate?.countdownTimerDone()
    }
}
