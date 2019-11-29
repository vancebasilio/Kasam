//
//  AppManager.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-06-06.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Firebase

class AppManager {
    
    static let shared = AppManager()
    
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    var appContainer: AppContainer!
    
    private init() { }
    
    func showApp() {
        var viewController: UIViewController
        if Auth.auth().currentUser == nil {
            viewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
        } else {
            viewController = storyboard.instantiateViewController(withIdentifier: "MainViewController")
        }
        viewController.modalPresentationStyle = .fullScreen //or .overFullScreen for transparency
        appContainer.present(viewController, animated: true, completion: nil)
    }

    func logoout() {
        try! Auth.auth().signOut()
        appContainer.presentedViewController?.dismiss(animated: true, completion: nil)
    }
    
}
