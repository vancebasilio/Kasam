//
//  NewBlockCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-10-14.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import SkyFloatingLabelTextField

protocol NewBlockDelegate {
    func sendDurationTime(blockNo: Int, duration: String)
    func sendDurationMetric(blockNo: Int, metric: String)
    func addActivityButtonPressed(blockNo: Int)
}

class NewBlockCell: UITableViewCell {
    
    @IBOutlet weak var titleTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var durationTimePicker: UIPickerView!
    @IBOutlet weak var durationMetricPicker: UIPickerView!
    @IBOutlet weak var dayNumber: UILabel!
    @IBOutlet weak var shadow: UIView!
    @IBOutlet weak var contents: UIView!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var repeatsLabel: UILabel!
    
    var blockNo = 1                                 //loaded in, starting from 1
    var delegate: NewBlockDelegate?
    var timeMetrics = ["secs", "mins", "hours"]
    
    var blockTypeSelected = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()
        durationTimePicker.delegate = self
        durationTimePicker.dataSource = self
        durationMetricPicker.delegate = self
        durationMetricPicker.dataSource = self
        titleTextField.addTarget(self, action: #selector(NewBlockCell.onTextChanged(sender:)), for: UIControl.Event.editingChanged)
        let completionCheck = NSNotification.Name("CompletionCheck")
        NotificationCenter.default.addObserver(self, selector: #selector(NewBlockCell.completionCheck), name: completionCheck, object: nil)
    }
    
    func setupFormatting(){
        createButton.layer.cornerRadius = createButton.frame.height / 2
        contents.layer.cornerRadius = 20
        contents.clipsToBounds = true
        shadow.layer.cornerRadius = 20
        shadow.layer.shadowColor = UIColor.colorFive.cgColor
        shadow.layer.shadowOpacity = 0.7
        shadow.layer.shadowOffset = CGSize.zero
        shadow.layer.shadowRadius = 4
    }
    
    func loadKasamInfo(block: NewKasamLoadFormat) {
        titleTextField.text = block.blockTitle
        let timeIndex = ((block.duration) / 5) - 1
        durationTimePicker.selectRow(timeIndex, inComponent: 0, animated: false)
        if let index = self.timeMetrics.index(of: block.durationMetric) {
            durationMetricPicker.selectRow(index, inComponent: 0, animated: false)
        }
        completionCheck()
    }
    
    func greenCheck(){
        NewKasam.kasamTransferArray[blockNo]?.complete = true
        createButton.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight:.regular), prefixTextColor: UIColor.white, icon: .fontAwesomeSolid(.pencilAlt), iconColor: UIColor.white, postfixText: "", postfixTextFont: UIFont.systemFont(ofSize: 15, weight:.medium), postfixTextColor: UIColor.white, backgroundColor: UIColor.init(hex: 0x007f00), forState: .normal, iconSize: 25)
    }
    
    func brownIncomplete(){
        //missing field
        NewKasam.kasamTransferArray[blockNo]?.complete = false
        createButton.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight:.regular), prefixTextColor: UIColor.white, icon: .fontAwesomeSolid(.pencilAlt), iconColor: UIColor.white, postfixText: "", postfixTextFont: UIFont.systemFont(ofSize: 15, weight:.medium), postfixTextColor: UIColor.white, backgroundColor: UIColor.colorFour, forState: .normal, iconSize: 25)
    }
    
    @objc func completionCheck(){
        let activity = NewKasam.fullActivityMatrix[blockNo]
        if NewKasam.chosenMetric == "Reps" {
            if titleTextField.text != "" && activity?[0]?.title != "" && activity?[0]?.description != "" && activity?[0]?.title != nil && activity?[0]?.description != nil && activity?[0]?.reps != 0 {
                greenCheck()
            } else {
                brownIncomplete()
            }
        } else if NewKasam.chosenMetric == "Checkmark" {
            if titleTextField.text != "" && activity?[0]?.title != "" && activity?[0]?.description != "" && activity?[0]?.title != nil && activity?[0]?.description != nil {
                greenCheck()
            } else {
                brownIncomplete()
            }
        } else if NewKasam.chosenMetric == "Timer" {
            let sec = activity?[0]?.sec ?? 0
            let min = activity?[0]?.min ?? 0
            let hour = activity?[0]?.hour ?? 0
            let totalTime =  hour + min + sec
            if titleTextField.text != "" && activity?[0]?.title != "" && activity?[0]?.description != "" && activity?[0]?.title != nil && activity?[0]?.description != nil && totalTime > 0 {
               greenCheck()
            } else {
                brownIncomplete()
            }
        }
        else {
            brownIncomplete()
        }
    }
    
    @objc func onTextChanged(sender: UITextField) {
        if sender.tag == 1 {
            completionCheck()
        }
    }
    
    @IBAction func createActivityButtonPressed(_ sender: Any) {
        delegate?.addActivityButtonPressed(blockNo: blockNo)
    }
}

extension NewBlockCell: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        pickerView.subviews.forEach({$0.isHidden = $0.frame.height < 1.0})
        if pickerView == durationMetricPicker {
            return timeMetrics.count
        } else {
            return 11           //number of time duration options
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 30.0
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == durationMetricPicker {
            delegate?.sendDurationMetric(blockNo: blockNo, metric: timeMetrics[row])
        } else {
            delegate?.sendDurationTime(blockNo: blockNo, duration: String((row + 1) * 5))
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label = UILabel()
        if let v = view as? UILabel { label = v }
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        if pickerView == durationMetricPicker {
            label.textAlignment = .left
            label.text = timeMetrics[row]
        } else {
            label.textAlignment = .left
            label.text = String((row + 1) * 5)
        }
        return label
    }
}
