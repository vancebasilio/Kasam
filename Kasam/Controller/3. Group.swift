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
import SystemConfiguration

class GroupViewController: UIViewController, UIGestureRecognizerDelegate {

    override func viewDidLoad() {
         super.viewDidLoad()
         setupNavBar(clean: false)                   //global function
     }
}
