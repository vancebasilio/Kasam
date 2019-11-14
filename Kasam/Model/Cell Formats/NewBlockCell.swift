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
    func sendBlockType(blockNo: Int, blockType: String)
    func sendDurationTime(blockNo: Int, duration: String)
    func sendDurationMetric(blockNo: Int, metric: String)
}

class NewBlockCell: UITableViewCell {
    
    @IBOutlet weak var titleTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var blockTypePicker: UIPickerView!
    @IBOutlet weak var durationTimePicker: UIPickerView!
    @IBOutlet weak var durationMetricPicker: UIPickerView!
    @IBOutlet weak var dayNumber: UILabel!
    @IBOutlet weak var shadow: UIView!
    @IBOutlet weak var contents: UIView!
    
    var blockNo = 1
    var delegate: NewBlockDelegate?
    var blockTypes = ["Timer", "Countdown", "Reps Counter"]
    var timeMetrics = ["secs", "mins", "hours"]
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        blockTypePicker.delegate = self
        blockTypePicker.dataSource = self
        durationTimePicker.delegate = self
        durationTimePicker.dataSource = self
        durationMetricPicker.delegate = self
        durationMetricPicker.dataSource = self
    }
    
    func setupFormatting(){
        contents.layer.cornerRadius = 8.0
        contents.clipsToBounds = true
        shadow.layer.cornerRadius = 8.0
        shadow.layer.shadowColor = UIColor.colorFive.cgColor
        shadow.layer.shadowOpacity = 0.5
        shadow.layer.shadowOffset = CGSize.zero
        shadow.layer.shadowRadius = 4
    }
}

extension NewBlockCell: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == blockTypePicker {
            return blockTypes.count
        } else if pickerView == durationMetricPicker {
            return timeMetrics.count
        } else {
            return 11
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 30.0
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == blockTypePicker {
            delegate?.sendBlockType(blockNo: blockNo, blockType: blockTypes[row])
        } else if pickerView == durationMetricPicker {
            delegate?.sendDurationMetric(blockNo: blockNo, metric: timeMetrics[row])
        } else {
            delegate?.sendDurationTime(blockNo: blockNo, duration: String((row + 1) * 5))
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label = UILabel()
        if let v = view as? UILabel { label = v }
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        if pickerView == blockTypePicker {
            label.textAlignment = .left
            label.text = blockTypes[row]
        } else if pickerView == durationMetricPicker {
            label.textAlignment = .left
            label.text = timeMetrics[row]
        } else {
            label.textAlignment = .left
            label.text = String((row + 1) * 5)
        }
        return label
    }
}
