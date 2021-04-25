//
//  ButtonPopup.swift
//  Kasam
//
//  Created by Vance Basilio on 2020-09-08.
//  Copyright © 2020 Vance Basilio. All rights reserved.
//

import Foundation
import SwiftEntryKit

class ButtonPopupController: UIViewController {

    @IBOutlet weak var popupTitle: UILabel!
    @IBOutlet weak var slidingHandle: UIView!
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    var buttonTextArray = [String]()
    var titleText = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        popupTitle.text = title
        button1.layer.cornerRadius = 20
        button2.layer.cornerRadius = 20
        cancelButton.layer.cornerRadius = 20
        slidingHandle.layer.cornerRadius = 3
        
        button1.setTitle(buttonTextArray[0], for: .normal)
        button2.setTitle(buttonTextArray[1], for: .normal)
        cancelButton.setTitle("Cancel", for: .normal)
    }
    
    @IBAction func button1Pressed(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "FirstButtonPressed"), object: self)
    }
    
    @IBAction func button2Pressed(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "SecondButtonPressed"), object: self)
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        SwiftEntryKit.dismiss()
    }
}
