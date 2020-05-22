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
    @IBOutlet weak var startDateTimeLabel: UILabel!
    @IBOutlet weak var startDayView: UIStackView!
    @IBOutlet weak var repeatPicker: UIPickerView!
    @IBOutlet weak var startDayPicker: UIPickerView!
    @IBOutlet weak var startTimePicker: UIPickerView!
    
    //transferred to Firebase
    var kasamID = ""
    var timelineDuration: Int?
    var formattedDate = ""      //loaded out value
    var formattedTime = ""      //loaded out value
    var repeatDuration = 1      //loaded out value
    var currentDay: Int?        //loaded out value
    var new: Bool?
    
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
        slidingHandle.clipsToBounds = true
        setupTimePicker()
    }
    
    func setupTimePicker(){
        if new == false {
            //OPTION 1 - EDITING EXISTING KASAM
            formattedDate = dateFormat(date:SavedData.kasamDict[kasamID]?.joinedDate ?? Date())
            formattedTime = SavedData.kasamDict[kasamID]!.startTime
            repeatDuration = SavedData.kasamDict[kasamID]!.repeatDuration
            currentDay = SavedData.kasamDict[kasamID]?.currentDay
            
            //Load in chosen Kasam preferences
            startDateTimeLabel.text = "Edit Preferences"
            if repeatDuration > 1 && (currentDay ?? 1 < repeatDuration) {
                repeatPicker.selectRow(repeatDuration - (currentDay ?? 1), inComponent: 0, animated: false)
            }
            timeUnit = formattedTime.components(separatedBy: " ").last ?? "AM"
            let setAMPM = timeUnitArray.index(of: timeUnit) ?? 0
            startTimePicker.selectRow(setAMPM, inComponent: 3, animated: false)
            
            let setHourMin = formattedTime.components(separatedBy: " ").first
            hour = Int(setHourMin?.components(separatedBy: ":").first ?? "10") ?? 10
            min = Int(setHourMin?.components(separatedBy: ":").last ?? "30") ?? 0
            startTimePicker.selectRow(hour - 1, inComponent: 0, animated: false)
            startTimePicker.selectRow(timeMinArray.index(of:String(format:"%02d", min)) ?? 0, inComponent: 2, animated: false)
            baseDate = stringToDate(date: formattedDate)
        } else {
             //OPTION 2 - ADDING NEW KASAM, SET DEFAULT DATE AND TIME
            cancelButton.isHidden = true
            formattedDate = dateFormat(date: Date())
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
        if timeUnit == timeUnitArray[1] {
            hourAMPM = hour + 12
        } else {
            hourAMPM = hour
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "SaveTime\(kasamID)"), object: self)
        SwiftEntryKit.dismiss()
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "UnfollowKasam\(kasamID)"), object: self)
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
        if pickerView == repeatPicker {
            if timelineDuration != nil {return 2}
            else {
                //Editing preferences on existing Kasam
                if currentDay != nil && currentDay != 0 && repeatDuration > 1 {return 100 - currentDay!}
                //New Kasam
                else {return 100}
            }
        } else if pickerView == startDayPicker{
            if currentDay != nil && currentDay != 0 {
                return currentDay!
            } else {
                return 30
            }
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
        if pickerView == repeatPicker {
            if timelineDuration != nil {
                if row == 0 {label.text = "No goal"}
                else {label.text =  String("\(timelineDuration!) days")}
            }
            else {
                //Editing existing Kasam preferences
                if currentDay != nil && currentDay != 0 && repeatDuration > 1 {label.text =  String("\(row + currentDay!) days")}
                //Loading new Kasam
                else {
                    if row == 0 {label.text = "No goal"}
                    else {label.text =  String("\(row + 1) days")}
                }
            }
        } else if pickerView == startDayPicker {
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
        }
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 40
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == repeatPicker {
            if timelineDuration != nil {
                if row == 0 {repeatDuration = 1}
                else {repeatDuration = timelineDuration!}
            } else {
                //Editing existing Kasam preferences
                if currentDay != nil && repeatDuration > 1 {repeatDuration = row + currentDay!}
                //Loading new Kasam
                else {repeatDuration = row + 1}
            }
        } else if pickerView == startDayPicker {
            formattedDate = dateFormat(date: Calendar.current.date(byAdding: .day, value: row, to: baseDate ?? Date())!)
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
