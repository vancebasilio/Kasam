//
//  KasamViewerCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-09-05.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import SDWebImage
import SwiftEntryKit

protocol KasamViewerCellDelegate {
    func dismissViewController()
    func setCompletedMetric(key: Int, value: Int)
    func sendCompletedMatrix(key: Int, value: Int)
    func nextItem()
}

class KasamViewerCell: UICollectionViewCell {

    @IBOutlet weak var animatedImageView: SDAnimatedImageView!
    @IBOutlet weak var activityTitle: UILabel!
    @IBOutlet weak var activityDescription: UILabel!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var activityNumber: UILabel!
    
    var delegate: KasamViewerCellDelegate?
    var animatedImageLocation: String?
    var buttoncheck = 0
    var pickerMetric = 0
    var currentMetric = 0
    var tempCurrentMetric: Int?
    var metricMatrixValue = 0
    var metricMatrixKey = 0
    var currentOrder = 0
    var totalOrder = 0
    var metricTotalNo = ""
    var count = 0
    var increment = 10
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupButtons()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "RemoveLoadingAnimation"), object: self)
        let stopActivityVideo = NSNotification.Name("StopActivityVideo")
        NotificationCenter.default.addObserver(self, selector: #selector(KasamViewerCell.stopActivityVideo), name: stopActivityVideo, object: nil)
        pickerView.selectRow(16, inComponent: 0, animated: false)
        pickerView.delegate = self
        pickerView.dataSource = self
    }
    
    @objc func stopActivityVideo(){
        animatedImageView.stopAnimating()
    }
    
    func setupButtons(){
        doneButton.layer.cornerRadius = 20.0
    }
    
    func setKasamViewer(activity: KasamActivityCellFormat) {
        metricTotalNo = activity.totalMetric
        
        activityTitle.text = activity.activityTitle
        activityDescription.text = activity.activityDescription
        
        currentOrder = activity.currentOrder
        totalOrder = activity.totalOrder
        
        pickerMetric = (Int(activity.totalMetric) ?? 20) / increment
        pickerView.reloadAllComponents() //important so that the pickerview updates to the max metric
        
        activityNumber.text = "\(activity.currentOrder)/\(activity.totalOrder)"
        animatedImageView.sd_setImage(with: URL(string: activity.image))
        
        if currentOrder == totalOrder {
            doneButton.setTitle("Done", for: .normal)
        } else {
            doneButton.setTitle("Next", for: .normal)
        }
    }
    
    @IBAction func ActivityVideoButton(_ sender: Any) {
        if buttoncheck == 0 {
            animatedImageView.startAnimating()
            buttoncheck = 1
        } else if buttoncheck == 1 {
            animatedImageView.stopAnimating()
            buttoncheck = 0
        }
    }
    
    @IBAction func doneButton(_ sender: UIButton) {
        if currentOrder == totalOrder {
            delegate?.dismissViewController()
            NotificationCenter.default.post(name: Notification.Name(rawValue: "UpdateKasamStatus"), object: self)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "ChalloStatsUpdate"), object: self)
        } else {
            delegate?.nextItem()
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
        delegate?.sendCompletedMatrix(key: currentOrder, value: row * increment)
    }
}
