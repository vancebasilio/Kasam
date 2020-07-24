//
//  KasamCalendar.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-05-15.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Foundation
import Firebase
import SDWebImage
import SwiftEntryKit
import Lottie

class GroupViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var groupFollowingLabel: UILabel!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    
    let groupAnimationIcon = AnimationView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar(clean: false)                   //global function
        getGroupFollowing()
        setupLoad()
     }
    
    func setupLoad(){
        if SavedData.groupKasamBlocks.count == 0 {
            
        } else {
            
        }
    }
    
    //Table Resizing----------------------------------------------------------------------------------------
    
    func updateContentViewHeight(){
        //elongates the entire scrollview, based on the tableview height
        let frame = self.view.safeAreaLayoutGuide.layoutFrame
        let contentHeightToSet = CGFloat(0)
        if contentHeightToSet > frame.height {
            contentViewHeight.constant = contentHeightToSet
        } else if contentHeightToSet <= frame.height {
            let diff = frame.height - contentHeightToSet
            contentViewHeight.constant = contentHeightToSet + diff + 1
        }
    }
    
    func getGroupFollowing(){
        SavedData.groupKasamBlocks.removeAll()
        DBRef.userGroupFollowing.observeSingleEvent(of: .value) {(snap) in
            if snap.exists() {} else {
                self.groupFollowingLabel.text = "You're not in any group kasams"
                self.groupAnimationIcon.loadingAnimation(view: self.contentView, animation: "crownSeptors", width: 200, overlayView: nil, loop: false, buttonText: "Add a Kasam", completion: nil)
                self.groupAnimationIcon.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.iconTapped)))
                self.updateContentViewHeight()
            }
        }
        
        DBRef.userGroupFollowing.observe(.childAdded) {(snapshot) in
            self.groupAnimationIcon.isHidden = true
            self.groupFollowingLabel.text = "You're in \(SavedData.groupKasamBlocks.count.pluralUnit(unit: "group kasam"))"
        }
    }

    @objc func iconTapped(){
        groupAnimationIcon.play()
    }
}
