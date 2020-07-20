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
import SkeletonView
import Lottie

class GroupViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var groupFollowingLabel: UILabel!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    
    let groupAnimationIcon = AnimationView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar(clean: false)                   //global function
        setupLoad()
     }
    
    func setupLoad(){
        if SavedData.groupKasamBlocks.count == 0 {
            groupFollowingLabel.text = "You're not in any group kasams"
            groupAnimationIcon.loadingAnimation(view: contentView, animation: "crownSeptors", height: 200, overlayView: nil, loop: false, completion: nil)
            groupAnimationIcon.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(iconTapped)))
        } else {
            groupFollowingLabel.text = "You're in \(SavedData.groupKasamBlocks.count.pluralUnit(unit: "group kasam"))"
        }
    }
    
    //Table Resizing----------------------------------------------------------------------------------------
    
    override func viewDidLayoutSubviews(){
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
    
    @objc func iconTapped(){
        groupAnimationIcon.play()
    }
}
