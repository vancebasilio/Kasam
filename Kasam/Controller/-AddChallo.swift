//
//  AddKasam.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-12-10.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import SwiftEntryKit

class AddKasamController: UIViewController {
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var slidingHandle: UIView!
    
    var startDate = ""
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: datePicker.date)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: datePicker.date)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardDismissRecognizer()
        datePicker.minimumDate = Date()
        datePicker.maximumDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
        saveButton.layer.cornerRadius = 20
        cancelButton.layer.cornerRadius = 20
        slidingHandle.layer.cornerRadius = 3
        slidingHandle.clipsToBounds = true
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
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "saveTime"), object: self)
        SwiftEntryKit.dismiss()
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        SwiftEntryKit.dismiss()
    }
}
