//
//  TabBar.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-05-04.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import SwiftIcons
import SwiftEntryKit
import SystemConfiguration

class TabBar: UITabBarController {
    
    let reachability = try! Reachability()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setReachabilityNotifier()
        tabBar.items?[0].setIcon(icon: .fontAwesomeSolid(.seedling), size: nil, textColor: .lightGray, selectedTextColor: .colorFour)
        tabBar.items?[1].setIcon(icon: .fontAwesomeSolid(.user), size: nil, textColor: .lightGray, selectedTextColor: .colorFour)
        tabBar.items?[2].setIcon(icon: .fontAwesomeSolid(.userFriends), size: nil, textColor: .lightGray, selectedTextColor: .colorFour)
        tabBar.items?[3].setIcon(icon: .fontAwesomeSolid(.featherAlt), size: nil, textColor: .lightGray, selectedTextColor: .colorFour)
        self.delegate = self
    }
    
    private func setReachabilityNotifier() {
        reachability.whenReachable = { reachability in
            if reachability.connection == .wifi {print("Reachable via WiFi")}
            else {print("Reachable via Cellular")}
            SwiftEntryKit.dismiss()
        }
        reachability.whenUnreachable = { _ in
            print("Not reachable")
            showProcessingNote()
        }
        do {try reachability.startNotifier()}
        catch {print("Unable to start notifier")}
    }
    
    func isNetworkReachable (with flags: SCNetworkReachabilityFlags) -> Bool {
        let isReachable = flags.contains (.reachable)
        let needsConnection = flags.contains (.connectionRequired)
        let canConnectAutomatically = flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)
        let canConnectWithoutUserInteraction = canConnectAutomatically && !flags.contains (.interventionRequired)
        return isReachable && (!needsConnection || canConnectWithoutUserInteraction)
    }
}

extension TabBar: UITabBarControllerDelegate  {
    //clicking to switch
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        guard let fromView = selectedViewController?.view, let toView = viewController.view else {
            return false // Make sure you want this as false
        }
        if fromView != toView {
            UIView.transition(from: fromView, to: toView, duration: 0.3, options: [.transitionCrossDissolve], completion: nil)
        }
        return true
    }
}

extension UITabBar {
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        var sizeThatFits = super.sizeThatFits(size)
        sizeThatFits.height = 60 // this increases height of tab bar
        if UIDevice().userInterfaceIdiom == .phone {
            switch UIScreen.main.nativeBounds.height {
                case 1136: //iPhone 5 or 5S or 5C
                    sizeThatFits.height = 49            //default for screen size
                    return sizeThatFits
                case 1334: //iPhone 6/6S/7/8
                    return sizeThatFits
                case 1920, 2208: //iPhone 6+/6S+/7+/8+
                    return sizeThatFits
                case 2436: //iPhone X/XS/11 Pro
                    sizeThatFits.height = 83            //default for screen size
                    return sizeThatFits
                case 2688: //iPhone XS Max/11 Pro Max
                    sizeThatFits.height = 83            //default for screen size
                    return sizeThatFits
                case 1792: //iPhone XR/ 11
                    sizeThatFits.height = 83            //default for screen size
                    return sizeThatFits
                default:
                    sizeThatFits.height = 83            //default for screen size
                    return sizeThatFits
            }
        } else {
            return size
        }
    }
}
