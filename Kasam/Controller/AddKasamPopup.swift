//
//  AddKasamPopup.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-05-08.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit

class AddKasamPopup: UIViewController {
    
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var saveKasamButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var repeatPicker: UISegmentedControl!
    @IBOutlet var addButton: [UIButton]!
    
    var selectedRepeat = ""
    var pickerData = ["Daily", "Weekly", "Biweekly", "Monthly"]
    var dayArray = ["M", "T", "W", "R", "F", "S", "Su"]
    var selectedDays: [String:Int] = [:]
    var selectcheck = [0:0,1:0,2:0,3:0,4:0,5:0,6:0]
    var startDate = ""
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timePicker.date)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter.string(from: Date())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectedRepeat = pickerData[0]
        setupKeyboardDismissRecognizer()
        popupView.roundCorners([.topLeft, .topRight], radius: 10)
        popupView.clipsToBounds = true
    }
    
    @IBAction func dayButton(_ sender: UIButton) {
        let index = sender.tag
        if selectcheck[sender.tag] == 0 {
            selectedDays[dayArray[index]] = 1
            addButton[index].setImage(UIImage(named: "\(dayArray[index])-calendar-selected.png"), for: .normal)
            selectcheck[sender.tag] = 1
        } else {
            selectedDays[dayArray[index]] = 0
            addButton[index].setImage(UIImage(named: "\(dayArray[index])-calendar-unselected.png"), for: .normal)
            selectcheck[sender.tag] = 0
        }
    }
    
    func setupKeyboardDismissRecognizer(){
        let tapRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(ViewController.dismissKeyboard))
        
        self.view.addGestureRecognizer(tapRecognizer)
    }
    
    override func dismissKeyboard() {
        dismiss(animated: true)
    }
    
    @IBAction func repeatPicker(_ sender: Any) {
        let getIndex = repeatPicker.selectedSegmentIndex
        switch(getIndex) {
        case 0:
            selectedRepeat = "Daily"
        case 1:
            selectedRepeat = "Weekly"
        case 2:
            selectedRepeat = "Biweekly"
        case 3:
            selectedRepeat = "Monthly"
        default:
            selectedRepeat = "Daily"
        }
    }
    
    @IBAction func saveKasamButton(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "saveTime"), object: self)
        dismiss(animated: true)
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        dismiss(animated: true)
    }
}
