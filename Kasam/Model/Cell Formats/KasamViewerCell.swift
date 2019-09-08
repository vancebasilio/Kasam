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

class KasamViewerCell: UITableViewCell {

    @IBOutlet weak var animatedImageView: SDAnimatedImageView!
    @IBOutlet weak var activityTitle: UILabel!
    @IBOutlet weak var activityDescription: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var metricTotal: UILabel!
    
    var animatedImageLocation: String?
    var buttoncheck = 0
    var pickerMetric = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "RemoveLoadingAnimation"), object: self)
        pickerView.delegate = self
        pickerView.dataSource = self
        startButton.layer.cornerRadius = 20.0
        doneButton.layer.cornerRadius = 20.0
    }
    
    func setKasamViewer(activity: KasamActivityCellFormat) {
        activityTitle.text = activity.activityTitle
        activityDescription.text = activity.activityDescription
        metricTotal.text = activity.totalNo
        pickerMetric = Int(activity.totalNo) ?? 20
        animatedImageView.sd_setImage(with: URL(string: activity.image)) { (image, error, cache, url) in
            if image != nil {
                self.animatedImageView.stopAnimating()
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        animatedImageView.stopAnimating()
    }
    
    @IBAction func startButton(_ sender: Any) {
        if buttoncheck == 0 {
            animatedImageView.startAnimating()
            startButton.setTitle("Stop", for: .normal)
            buttoncheck = 1
        } else if buttoncheck == 1 {
            animatedImageView.stopAnimating()
            startButton.setTitle("Start", for: .normal)
            buttoncheck = 0
        }
    }
    
    @IBAction func doneButton(_ sender: Any) {
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        animatedImageView.startAnimating()
    }
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
        label.font = UIFont.systemFont(ofSize: 25, weight: .bold)
        label.text =  String(row+1)
        label.textAlignment = .right
        return label
    }
}
