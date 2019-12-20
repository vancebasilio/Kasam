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
    
    
    var blockNo = 1
    var delegate: NewBlockDelegate?
    var timeMetrics = ["secs", "mins", "hours"]
    
    var blockTypeSelected = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()
        durationTimePicker.delegate = self
        durationTimePicker.dataSource = self
        durationMetricPicker.delegate = self
        durationMetricPicker.dataSource = self
    }
    
    func setupFormatting(){
        createButton.layer.cornerRadius = createButton.frame.height / 2
        contents.layer.cornerRadius = 8.0
        contents.clipsToBounds = true
        shadow.layer.cornerRadius = 8.0
        shadow.layer.shadowColor = UIColor.colorFive.cgColor
        shadow.layer.shadowOpacity = 0.5
        shadow.layer.shadowOffset = CGSize.zero
        shadow.layer.shadowRadius = 4
    }
    
    func loadChalloInfo(block: NewChalloLoadFormat) {
        titleTextField.text = block.challoTitle
        let timeIndex = ((block.time) / 5) - 1
        durationTimePicker.selectRow(timeIndex, inComponent: 0, animated: false)
        if let index = self.timeMetrics.index(of: block.timeMetric) {
            durationMetricPicker.selectRow(index, inComponent: 0, animated: false)
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
            return 11
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
