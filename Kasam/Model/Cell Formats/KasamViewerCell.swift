//
//  KasamViewerCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-09-05.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import SDWebImage

class KasamViewerCell: UITableViewCell {

    @IBOutlet weak var animatedImageView: SDAnimatedImageView!
    @IBOutlet weak var activityTitle: UILabel!
    @IBOutlet weak var activityDescription: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var pickerView: UIPickerView!
    
    var animatedImageLocation: String?
    let dataSource = ["1", "2", "3","4","5"]
    
    override func awakeFromNib() {
        super.awakeFromNib()
        print("hello")
        NotificationCenter.default.post(name: Notification.Name(rawValue: "RemoveLoadingAnimation"), object: self)
        pickerView.delegate = self
        pickerView.dataSource = self
        startButton.backgroundColor = UIColor.black
        startButton.layer.cornerRadius = 20.0
    }
    
    func setKasamViewer(activity: KasamActivityCellFormat) {
        activityTitle.text = activity.activityTitle
        activityDescription.text = activity.activityDescription
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
    
    @IBAction func startButton(_ sender: UIButton) {
        animatedImageView.startAnimating()
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
        return 5
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return dataSource[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label = UILabel()
        if let v = view as? UILabel { label = v }
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.text =  dataSource[row]
        label.textAlignment = .right
        return label
    }
    
    
}
