//
//  AddKasam.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-12-10.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import SwiftEntryKit
import Lottie

class OptionsPopupController: UIViewController {
    @IBOutlet weak var mainButton: UIButton!
    @IBOutlet weak var hiddenButton: UIButton!
    @IBOutlet weak var optionsImage: AnimationView!
    @IBOutlet weak var optionsTitle: UILabel!
    @IBOutlet weak var optionsSubtitle: UILabel!
    @IBOutlet weak var optionsText: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    
    var transfer: (kasamID: String?, title: String?, subtitle: String?, text: String?, type: String, buttonText: String)?
    
    override func viewDidLoad() {
        mainButton.layer.cornerRadius = 20
        hiddenButton.layer.cornerRadius = 20
        optionsTitle.text = transfer?.title
        optionsText.text = transfer?.text
        closeButton?.setIcon(icon: .fontAwesomeSolid(.times), iconSize: 20, color: UIColor.init(hex: 0x79787e), forState: .normal)
        mainButton.setTitle(transfer?.buttonText, for: .normal)
        setupImage()
        
        if transfer?.title == nil {optionsTitle.isHidden = true}
        if transfer?.text == nil {optionsText.isHidden = true}
        optionsText.numberOfLines = optionsText.calculateMaxLines() + 1
        if transfer?.type == "complete" || transfer?.type == "completeTrophy" {
            hiddenButton.isHidden = false
            optionsSubtitle.text = transfer?.subtitle
            optionsSubtitle.isHidden = false
        } else if transfer?.type == "changeKasamBlock" {
            hiddenButton.isHidden = false
            hiddenButton.setTitle("Remove", for: .normal)
            mainButton.setTitle("Skip", for: .normal)
        }
        else {hiddenButton.isHidden = true}
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupImage(){
        switch transfer?.type {
            case "logout": optionsImage.animation = Animation.named("flagmountainBG")
            case "goPro": optionsImage.animation = Animation.named("crown")
            case "benefit": optionsImage.animation = Animation.named("diamond")
            case "completeTrophy": optionsImage.animation = Animation.named("goldCup")
            case "startGroupKasam": optionsImage.animation = Animation.named("rocket-group")
            case "group-remove": optionsImage.animation = Animation.named("hand-waving")
            case "changeKasamBlock": optionsImage.animation = Animation.named("updateCircle")
            default: optionsImage.animation = Animation.named("flagmountainBG")
        }
        optionsImage.backgroundBehavior = .pauseAndRestore
        optionsImage.loopMode = .repeat(3)
        optionsImage.play()
    }
    
//BUTTONS-----------------------------------------------------------------------------------------------------------
    
    @IBAction func mainButtonPressed(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "MainButtonPressed"), object: self)
        SwiftEntryKit.dismiss()
    }
    
    @IBAction func hiddenButtonPressed(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "HiddenButtonPressed"), object: self)
        if transfer?.type == "complete" || transfer?.type == "completeTrophy" {
            finishKasamPress(kasamID: (transfer?.kasamID)!) {(true) in
                SwiftEntryKit.dismiss()
            }
        } else if transfer?.type == "changeKasamBlock" {
            SwiftEntryKit.dismiss()
        }
    }
    
    @IBAction func closeButtonPressed(_ sender: Any) {
        SwiftEntryKit.dismiss()
    }
}
