//
//  MainUserController.swift
//  Kasam 1.0
//
//  Created by Vance Basilio on 2019-04-21.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Firebase

class MainUserController: UIViewController {
    
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var emailAddress: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userName.text = Auth.auth().currentUser?.displayName
        emailAddress.text = Auth.auth().currentUser?.email

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
