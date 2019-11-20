//
//  NewActivityCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-11-14.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import SDWebImage
import SwiftEntryKit
import SkyFloatingLabelTextField
import HGCircularSlider
import SwiftIcons

protocol NewActivityCellDelegate {
    func showChooseSourceTypeAlertController()
    func saveActivityData(activityNo: Int, title: String, description: String, image: UIImage, metric: Int)
}

class NewActivityCell:UICollectionViewCell, UITextViewDelegate {
    
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var bottomView: UIStackView!
    @IBOutlet weak var circularSlider: CircularSlider!
    @IBOutlet weak var animatedImageView: SDAnimatedImageView!
    @IBOutlet weak var activityNumber: UILabel!
    @IBOutlet weak var activityTitle: SkyFloatingLabelTextField!
    @IBOutlet weak var activityDescription: UITextView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var timerDoneButton: UIButton!
    @IBOutlet weak var restImageView: UIImageView!
    @IBOutlet weak var restTitle: UILabel!
    @IBOutlet weak var restDescription: UILabel!
    @IBOutlet weak var restDoneButton: UIButton!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var instruction: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var timerStartStop: UILabel!
    @IBOutlet weak var timerButtonStackView: UIStackView!
    @IBOutlet weak var restView: UIStackView!
    @IBOutlet weak var textField: SkyFloatingLabelTextField!
    
    var delegate: NewActivityCellDelegate?
    var activityNo = 0
    var currentOrder = 0
    var totalOrder = 0
    var pickerMetric = 0
    var increment = 10              //for the reps slider
    
    override func awakeFromNib() {
        super.awakeFromNib()
        activityNumber.text = "1/1"
        activityTitle.textAlignment = .center
        activityDescription.text = "Activity Description"
        activityDescription.textColor = UIColor.lightGray
        activityDescription.delegate = self
        animatedImageView.layer.cornerRadius = 20.0
    }
    
    @IBAction func imageClicked(_ sender: Any) {
        delegate?.showChooseSourceTypeAlertController()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.darkGray
        }
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        delegate?.saveActivityData(activityNo: activityNo, title: activityTitle.text ?? "Activity Title", description: activityDescription.text ?? "Activity Description", image: animatedImageView.image!, metric: 200)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Activity Description"
            textView.textColor = UIColor.lightGray
        }
    }
    
    //PICKER-----------------------------------------------------------------------------------
    
    func setKasamViewer() {
        restView.isHidden = true
        textField.isHidden = true
        currentOrder = 1
        totalOrder = 1
//        pickerMetric = (Int(activity.totalMetric) ?? 20) / increment
        pickerView.reloadAllComponents()                                    //important so that the pickerview updates to the max metric
//        activityNumber.text = "\(activity.currentOrder)/\(activity.totalOrder)"
//        animatedImageView.sd_setImage(with: URL(string: ""))
        if currentOrder == totalOrder {
            doneButton.setTitle("Save", for: .normal)
        } else {
            doneButton.setTitle("Next", for: .normal)
        }
    }
    
    func setupPicker(){
        pickerView.selectRow(16, inComponent: 0, animated: false)
        pickerView.delegate = self
        pickerView.dataSource = self
        doneButton.layer.cornerRadius = 20.0
        circularSlider.isHidden = true
        timerButtonStackView.isHidden = true
        instruction.isHidden = true
        textField.isHidden = true
    }
    
    //REST-----------------------------------------------------------------------------------
    
    func setupRest(activity: KasamActivityCellFormat) {
        topView.isHidden = true
        bottomView.isHidden = true
        restTitle.text = activity.activityTitle
        restDescription.text = activity.activityDescription
        restDoneButton.layer.cornerRadius = 20.0
        restImageView.sd_setImage(with: URL(string: "https://firebasestorage.googleapis.com/v0/b/kasam-coach.appspot.com/o/kasam%2FRest_animation.gif?alt=media&token=347b9eca-6d37-40fc-82f3-12483d71e440"))
    }
}

extension NewActivityCell: UIPickerViewDelegate, UIPickerViewDataSource {
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
    
//    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//        delegate?.sendCompletedMatrix(key: currentOrder, value: Double(row * increment), text: "")
//    }
}

//Sets the selected image as the kasam image in create view
