//
//  AppContainerViewController.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-06-06.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit

class AppContainer: UIViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        AppManager.shared.appContainer = self
        AppManager.shared.showApp()
    }
}
