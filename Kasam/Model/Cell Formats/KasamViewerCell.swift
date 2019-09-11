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
    func setCompletedMetric(completedMetric: Int)
}

class KasamViewerCell: UICollectionViewCell {

    @IBOutlet weak var animatedImageView: SDAnimatedImageView!
    @IBOutlet weak var activityTitle: UILabel!
    @IBOutlet weak var activityDescription: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var metricTotal: UILabel!
    
    var delegate: KasamViewerCellDelegate?
    var animatedImageLocation: String?
    var buttoncheck = 0
    var pickerMetric = 0
    var setCompletedMetric = 0
    var currentMetric = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupButtons()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "RemoveLoadingAnimation"), object: self)
        let stopActivityVideo = NSNotification.Name("StopActivityVideo")
        NotificationCenter.default.addObserver(self, selector: #selector(KasamViewerCell.stopActivityVideo), name: stopActivityVideo, object: nil)
        animatedImageView.stopAnimating()
        pickerView.delegate = self
        pickerView.dataSource = self
    }
    
    @objc func stopActivityVideo(){
        animatedImageView.stopAnimating()
    }
    
    override func layoutSubviews() {
        pickerView.selectRow(currentMetric, inComponent: 0, animated: false)
    }
    
    func setupButtons(){
        startButton.layer.cornerRadius = 20.0
        doneButton.layer.cornerRadius = 20.0
    }
    
    func setKasamViewer(activity: KasamActivityCellFormat) {
        activityTitle.text = activity.activityTitle
        currentMetric = activity.currentMetric
        activityDescription.text = activity.activityDescription
        metricTotal.text = activity.totalMetric
        pickerMetric = Int(activity.totalMetric) ?? 20
        animatedImageView.sd_setImage(with: URL(string: activity.image)) { (image, error, cache, url) in
            if image != nil {
//                self.animatedImageView.stopAnimating()
            }
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
    
    
    @IBAction func startButton(_ sender: Any) {
        if buttoncheck == 0 {
            animatedImageView.startAnimating()
            startButton?.setIcon(icon: .fontAwesomeSolid(.pauseCircle), iconSize: 50, color: UIColor.black, forState: .normal)
            buttoncheck = 1
        } else if buttoncheck == 1 {
            animatedImageView.stopAnimating()
            startButton?.setIcon(icon: .fontAwesomeSolid(.playCircle), iconSize: 50, color: UIColor.black, forState: .normal)
            buttoncheck = 0
        }
    }
    
    @IBAction func doneButton(_ sender: UIButton) {
        delegate?.dismissViewController()
        delegate?.setCompletedMetric(completedMetric: setCompletedMetric)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "RetrieveKasams"), object: self)
    }
    
//    override func setSelected(_ selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//        animatedImageView.startAnimating()
//    }
}

extension KasamViewerCell: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerMetric
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(row+1)
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label = UILabel()
        if let v = view as? UILabel { label = v }
        label.font = UIFont.systemFont(ofSize: 35, weight: .bold)
        label.text =  String(row+1)
        label.textAlignment = .right
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 30.0
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.setCompletedMetric = row + 1
    }
}
