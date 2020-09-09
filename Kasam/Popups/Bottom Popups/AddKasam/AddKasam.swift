//
//  AddKasam.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-12-10.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import SwiftEntryKit

class AddKasamController: UIViewController {
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var slidingHandle: UIView!
    
    @IBOutlet weak var dayGoalButton: UIView!
    @IBOutlet weak var dayGoalOutline: UIView!
    @IBOutlet weak var dayGoalBG: UIView!
    @IBOutlet weak var dayGoaldayLabel: UILabel!
    @IBOutlet weak var dayGoalImage: UIImageView!
    
    @IBOutlet weak var groupButton: UIView!
    @IBOutlet weak var groupOutline: UIView!
    @IBOutlet weak var groupBG: UIView!
    @IBOutlet weak var groupLabel: UILabel!
    @IBOutlet weak var groupImage: UIImageView!
    
    @IBOutlet weak var startDateTimeLabel: UILabel!
    @IBOutlet weak var startDayView: UIStackView!
    @IBOutlet weak var startDayPicker: UIPickerView!
    @IBOutlet weak var startTimePicker: UIPickerView!
    @IBOutlet weak var durationView: UIStackView!
    @IBOutlet weak var durationPicker: UIPickerView!
    @IBOutlet weak var reminderTimeSwitch: UISwitch!
    
    @IBOutlet weak var goalStackView: UIStackView!
    @IBOutlet weak var startDayStackView: UIStackView!
    @IBOutlet weak var reminderTimeStackView: UIStackView!
    @IBOutlet weak var fillerStackView: UIStackView!
    @IBOutlet weak var fillerStackViewTop: UIStackView!
    
    var kasamID = ""                        //loaded in value
    var repeatDuration = 30                 //loaded in value
    var state = ""                          //loaded in value

    var formattedDate = ""                  //loaded out value
    var formattedTime = ""                  //loaded out value
    var currentDay: Int?                    //loaded out value
    var joinType = "personal"               //loaded out value
    
    var fullView = true
    var notificationCheck = true
    
    //Converter variables
    var timeMinArray = ["00", "30"]
    var timeUnitArray = ["AM", "PM"]
    var timeUnit = "AM"
    var hourAMPM = 20           //converted hour to AM/PM format
    var hour =  5
    var min = 30
    var baseDate: Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardDismissRecognizer()
        saveButton.layer.cornerRadius = 20
        cancelButton.layer.cornerRadius = 20
        slidingHandle.layer.cornerRadius = 3
        
        dayGoalBG.layer.cornerRadius = 20
        dayGoalOutline.layer.cornerRadius = 25
        dayGoalOutline.layer.borderColor = UIColor.init(hex: 0x66A058).cgColor
        dayGoalOutline.layer.borderWidth = 3.0
        dayGoalImage.setIcon(icon: .fontAwesomeSolid(.user), textColor: .white, backgroundColor: .clear, size: CGSize(width: dayGoalImage.frame.size.width * 0.7, height: dayGoalImage.frame.size.height * 0.7))
        
        groupBG.layer.cornerRadius = 20
        groupOutline.layer.cornerRadius = 25
        groupOutline.layer.borderColor = UIColor.init(hex: 0x66A058).cgColor
        groupOutline.layer.borderWidth = 3.0
        groupImage.setIcon(icon: .fontAwesomeSolid(.userFriends), textColor: .white, backgroundColor: .clear, size: CGSize(width: dayGoalImage.frame.size.width * 0.7, height: dayGoalImage.frame.size.height * 0.7))
        
        if state == "new" {
            dayGoalButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(personalChallengeSelected)))
            groupButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(groupChallengeSelected)))
        } else if state == "restart" {
            startDateTimeLabel.text = "Restart Kasam"
            saveButton.setTitle("Restart", for: .normal)
        } else if state == "edit" {
            cancelButton.setTitle("End Kasam", for: .normal)
        }
        
        reminderTimeSwitch.onTintColor = .colorFour
        reminderTimeSwitch.tintColor = .gray
        reminderTimeSwitch.layer.cornerRadius = reminderTimeSwitch.frame.height / 2
        reminderTimeSwitch.backgroundColor = .gray
        
        groupLabel.text = "Group\nKasam"
        
        setupTimePicker()
        if state == "edit" {
            startDateTimeLabel.text = "Edit Reminder Time"
            goalStackView.isHidden = true
            startDayView.isHidden = true
            durationView.isHidden = true
            fillerStackView.isHidden = false
            fillerStackViewTop.isHidden = false
        }
    }
    
    @objc func personalChallengeSelected(){
        joinType = "personal"
        groupOutline.isHidden = true
        groupLabel.textColor = .darkGray
        groupBG.backgroundColor = UIColor.init(hex:0xCCCCCC)
        
        dayGoalOutline.isHidden = false
        dayGoaldayLabel.textColor = .white
        dayGoalBG.backgroundColor = UIColor.init(hex: 0x6EA960)
    }
    
    @objc func groupChallengeSelected(){
        joinType = "group"
        dayGoalOutline.isHidden = true
        dayGoaldayLabel.textColor = .darkGray
        dayGoalBG.backgroundColor = UIColor.init(hex:0xCCCCCC)
        
        groupOutline.isHidden = false
        groupLabel.textColor = .white
        groupBG.backgroundColor = UIColor.init(hex: 0x6EA960)
    }
    
    @objc func justForFunSelected(){
        joinType = "personal"
        dayGoalOutline.isHidden = true
        groupOutline.isHidden = true
        dayGoaldayLabel.textColor = .darkGray
        groupLabel.textColor = .darkGray
        dayGoalBG.backgroundColor = UIColor.init(hex:0xCCCCCC)
        groupBG.backgroundColor = UIColor.init(hex:0xCCCCCC)
        repeatDuration = 0
    }
    
    @IBAction func switchSelected(_ sender: Any) {
         if reminderTimeSwitch.isOn {
            startTimePicker.alpha = 1
            startTimePicker.isUserInteractionEnabled = true
            notificationCheck = true
         } else {
            startTimePicker.alpha = 0.5
            startTimePicker.isUserInteractionEnabled = false
            notificationCheck = false
         }
    }
    
    func setupTimePicker(){
        //OPTION 1 - EDITING EXISTING KASAM
        if state == "edit" {
            formattedDate = (SavedData.kasamDict[kasamID]?.joinedDate ?? Date()).dateToString()
            formattedTime = SavedData.kasamDict[kasamID]!.startTime
            currentDay = SavedData.kasamDict[kasamID]?.currentDay
            repeatDuration = SavedData.kasamDict[kasamID]!.repeatDuration
            startDayPicker.isUserInteractionEnabled = false
            durationPicker.isUserInteractionEnabled = false
            
            //Load in chosen Kasam preferences
            startDateTimeLabel.text = "Edit Preferences"
            if repeatDuration > 0 {
                personalChallengeSelected()
            } else {
                justForFunSelected()
            }
            timeUnit = formattedTime.components(separatedBy: " ").last ?? "AM"
            let setAMPM = timeUnitArray.index(of: timeUnit) ?? 0
            startTimePicker.selectRow(setAMPM, inComponent: 3, animated: false)
            
            let setHourMin = formattedTime.components(separatedBy: " ").first
            hour = Int(setHourMin?.components(separatedBy: ":").first ?? "10") ?? 10
            min = Int(setHourMin?.components(separatedBy: ":").last ?? "30") ?? 0
            if hour == 0 {startTimePicker.selectRow(11, inComponent: 0, animated: false)}
            else {startTimePicker.selectRow(hour - 1, inComponent: 0, animated: false)}
            
            startTimePicker.selectRow(timeMinArray.index(of:String(format:"%02d", min)) ?? 0, inComponent: 2, animated: false)
            baseDate = formattedDate.stringToDate()
             
            UNUserNotificationCenter.current().getPendingNotificationRequests {(notifications) in
                var notificationCheckExisting = false
                for item in notifications {
                    if item.identifier == SavedData.kasamDict[self.kasamID]?.kasamID {
                        notificationCheckExisting = true
                    }
                }
                DispatchQueue.main.async {
                    if notificationCheckExisting == true {
                        self.reminderTimeSwitch.setOn(true, animated: true)
                    } else {
                        self.reminderTimeSwitch.setOn(false, animated: false)
                    }
                }
            }
       
        //OPTION 2 - ADDING NEW KASAM, SET DEFAULT DATE AND TIME
        } else if state == "new" {
            DBRef.coachKasams.child(kasamID).child("Duration").observeSingleEvent(of: .value) {(snap) in
                self.repeatDuration = snap.value as? Int ?? 30
            }
            
            //If restarting a kasam
            if SavedData.kasamDict[kasamID]?.repeatDuration != nil {
                repeatDuration = SavedData.kasamDict[kasamID]!.repeatDuration
                if repeatDuration > 1 && (currentDay ?? 1 < repeatDuration) {
                    personalChallengeSelected()
                }
            }
            
            formattedDate = Date().dateToString()
            var tempMin = (Double(Calendar.current.component(.minute, from: Date())) / 60.0).rounded(toPlaces: 0)
            var tempHour = Calendar.current.component(.hour, from: Date())
            
            //Set the minute
            if tempMin == 0 {
                tempMin = 1
            } else {
                tempMin = 0
                tempHour += 1
            }
            min = Int(tempMin) * 30
            startTimePicker.selectRow(Int(tempMin), inComponent: 2, animated: true)

            //Set the hour
            if tempHour > 12 {
                timeUnit = timeUnitArray[1]
                hour = tempHour - 12
                startTimePicker.selectRow(hour - 1, inComponent: 0, animated: true)
                startTimePicker.selectRow(1, inComponent: 3, animated: true)
            } else {
                timeUnit = timeUnitArray[0]
                hour = tempHour
                startTimePicker.selectRow(hour - 1, inComponent: 0, animated: true)
                startTimePicker.selectRow(0, inComponent: 3, animated: true)
            }
        }
        formattedTime = String(format:"%d:%02d \(timeUnit)", hour, min)
    }
    
    func setupKeyboardDismissRecognizer(){
        let tapRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
        self.view.addGestureRecognizer(tapRecognizer)
    }
    
    override func dismissKeyboard() {
        dismiss(animated: true)
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        if timeUnit == timeUnitArray[1] {hourAMPM = hour + 12}
        else {hourAMPM = hour}
        if state == "new" {
            if reminderTimeSwitch.isOn {notificationCheck = true}
            else {notificationCheck = false}
            NotificationCenter.default.post(name: Notification.Name(rawValue: "SaveTime\(kasamID)"), object: self)
            SwiftEntryKit.dismiss()
        } else if state == "restart" {
            showCenterOptionsPopup(kasamID: nil, title: "Are you sure?", subtitle: nil, text: "You'll be ending this kasam and starting over from day 1", type: "restart", button: "Restart") {(button) in
                if button == true {
                    if self.reminderTimeSwitch.isOn {self.kasamID.restartExistingNotification()}
                    else {UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [self.kasamID])}
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "SaveTime\(self.kasamID)"), object: self)
                }
                SwiftEntryKit.dismiss()
            }
        } else if state == "edit" {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "SaveTime\(kasamID)"), object: self)
            SwiftEntryKit.dismiss()
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        if state == "edit" {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "UnfollowKasam\(kasamID)"), object: self)
        } else {
            SwiftEntryKit.dismiss()
        }
    }
}

extension AddKasamController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        if pickerView == startTimePicker {
            return 4
        } else {
            return 1
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        pickerView.subviews.forEach({$0.isHidden = $0.frame.height < 1.0})
        if pickerView == startDayPicker{
            if currentDay != nil && currentDay != 0 {
                return currentDay!
            } else {
                return 30
            }
        } else if pickerView == durationPicker {
            return 1
        } else {
            if component == 0 {
                return 12
            } else if component == 1 {
                return 1
            } else if component == 2 {
                return 2
            } else {
                return 2
            }
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label = UILabel()
        if let v = view as? UILabel { label = v }
        label.font = UIFont.systemFont(ofSize: 23, weight: .regular)
        label.textAlignment = .center
        if pickerView == startDayPicker {
            if baseDate == nil {
                if row == 0 {label.text = "Today"}
                else if row == 1 {label.text = "Tomorrow"}
                else {let day = dateShortFormat(date: Calendar.current.date(byAdding: .day, value: row, to: baseDate ?? Date())!)
                label.text = day
                }
            } else {
                let day = dateShortFormat(date: Calendar.current.date(byAdding: .day, value: row, to: baseDate ?? Date())!)
                label.text = day
            }
        } else if pickerView == startTimePicker {
            if component == 0 {
                label.text = "\(row + 1)"
            } else if component == 1 {
                label.text = ":"
            } else if component == 2 {
                label.text = timeMinArray[row]
            } else {
                label.text = timeUnitArray[row]
            }
        } else if pickerView == durationPicker {
            label.text = "\(repeatDuration) days"
        }
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 40
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == startDayPicker {
            formattedDate = (Calendar.current.date(byAdding: .day, value: row, to: baseDate ?? Date())!).dateToString()
        } else if pickerView == startTimePicker {
            if component == 0 {
                hour = row + 1
            } else if component == 2 {
                min = row * 30
            } else if component == 3 {
                timeUnit = timeUnitArray[row]
            }
            formattedTime = String(format:"%d:%02d \(timeUnit)", hour, min)
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        if pickerView == startTimePicker {
            if component == 1 {
                return 4
            } else {
                return 40
            }
        } else {
            return startTimePicker.frame.width
        }
    }
}
