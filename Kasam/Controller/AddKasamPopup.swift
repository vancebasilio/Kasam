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
    
    var startDate = ""
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timePicker.date)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: timePicker.date)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardDismissRecognizer()
        timePicker.minimumDate = Date()
        timePicker.maximumDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
        popupView.roundCorners([.topLeft, .topRight], radius: 20)
        saveKasamButton.layer.cornerRadius = 20
        cancelButton.layer.cornerRadius = 20
        popupView.clipsToBounds = true
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
    
    @IBAction func saveKasamButton(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "saveTime"), object: self)
        dismiss(animated: true)
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        dismiss(animated: true)
    }
}
