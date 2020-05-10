//
//  EmbeddedViewController.swift
//  SwiftEntryKitDemo
//
//  Created by Daniel Huri on 3/15/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import SwiftEntryKit

class UserOptionsController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet weak var slidingHandle: UIView!
    
    init() {super.init(nibName: type(of: self).className, bundle: nil)}
    required init?(coder aDecoder: NSCoder) {fatalError("init(coder:) has not been implemented")}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        slidingHandle.layer.cornerRadius = 3
        slidingHandle.clipsToBounds = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "GenericCell")
    }
}

extension UserOptionsController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GenericCell")!
        cell.selectionStyle = .none
        switch indexPath.row {
            case 0: cell.textLabel?.setIcon(prefixText: "  ", icon: .fontAwesomeSolid(.gift), postfixText: "  Create a Simple Kasam", size: 20)
        case 1: cell.textLabel?.setIcon(prefixText: "  ", icon: .fontAwesomeSolid(.cubes), postfixText: "  Create a Complex Kasam", size: 20)
            case 2: cell.textLabel?.setIcon(prefixText: "  ", icon: .fontAwesomeSolid(.signOutAlt), postfixText: "  Log Out", size: 20)
            default: cell.textLabel?.text = ""
        }
        cell.textLabel?.textAlignment = .left
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "GoToCreateKasam"), object: self, userInfo: ["type": "simple"])
            SwiftEntryKit.dismiss()
        } else if indexPath.row == 1 {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "GoToCreateKasam"), object: self, userInfo: ["type": "complex"])
            SwiftEntryKit.dismiss()
        } else if indexPath.row == 2 {
            let popupImage = UIImage.init(icon: .fontAwesomeSolid(.doorOpen), size: CGSize(width: 30, height: 30), textColor: .white)
            showPopupConfirmation(title: "Are you sure?", description: "", image: popupImage, buttonText: "Logout") {(success) in
                AppManager.shared.logoout()
                LoginManager().logOut()
                SwiftEntryKit.dismiss()
            }
        }
    }
}

extension NSObject {
    var className: String {
        return String(describing: type(of: self))
    }
    
    class var className: String {
        return String(describing: self)
    }
}
