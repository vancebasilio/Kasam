//
//  ViewController.swift
//  Kasam 1.0
//
//  Created by Vance Basilio on 2019-04-19.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit

class ViewController: UIViewController {
    
    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    @IBOutlet weak var manualLogin: UIButton!
    @IBOutlet weak var facebookLogin: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        initializeButtons()
    }
    
    func initializeButtons(){
        manualLogin.backgroundColor = UIColor.colorFive
        manualLogin.layer.cornerRadius = 20.0
        facebookLogin.tintColor = UIColor.colorFive
        facebookLogin.layer.cornerRadius = 20.0
        facebookLogin.backgroundColor = UIColor.white
        facebookLogin.layer.borderColor = UIColor.colorFive.cgColor
        facebookLogin.layer.borderWidth = 1.5
        facebookLogin.addTarget(self, action: #selector(CustomFBLogin), for: .touchUpInside)
    }
    
    @objc func CustomFBLogin(){
        LoginManager().logIn(permissions: ["email", "public_profile"], from: self)
        { (result: LoginManagerLoginResult?, error: Error?) in
            if error == nil {
                if result!.isCancelled {
                    return
                }
                let credential = FacebookAuthProvider.credential(withAccessToken: AccessToken.current!.tokenString)
                Auth.auth().signIn(with: credential) { (authResult, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                    print(authResult?.user.displayName! as Any)
                    self.dismiss(animated: true, completion: nil)
                }
            } else {
                print(error?.localizedDescription as Any)
            }
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        print("user logged out!")
    }

    @IBAction func logInPressed(_ sender: Any) {
        guard let email = emailTextfield.text, let password = passwordTextfield.text else {return}
        
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            if let _ = user {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}

