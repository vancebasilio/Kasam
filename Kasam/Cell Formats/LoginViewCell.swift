//
//  LoginViewCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-11-09.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit

protocol LoginViewCellDelegate {
    func dismissViewController()
    func showError(_ error: Error)
    func CustomFBLogin()
    func CustomGoogleLogin()
    func CustomAppleLogin()
}

class LoginViewCell: UICollectionViewCell {
    
    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    @IBOutlet weak var manualLogin: UIButton!
    @IBOutlet weak var facebookLogin: UIButton!
    @IBOutlet weak var googleLogin: UIButton!
    @IBOutlet weak var appleLogin: UIButton!
    
    var delegate: LoginViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        initializeButtons()
    }

    func initializeButtons(){
        manualLogin.backgroundColor = UIColor.colorFive
        manualLogin.layer.cornerRadius = manualLogin.frame.height / 2
        
        facebookLogin.setIcon(icon: .fontAwesomeBrands(.facebookF), iconSize: 25, color: UIColor.white, backgroundColor: UIColor.darkGray, forState: .normal)
        facebookLogin.layer.cornerRadius = facebookLogin.frame.width / 2
        googleLogin.setIcon(icon: .fontAwesomeBrands(.google), iconSize: 25, color: UIColor.white, backgroundColor: UIColor.darkGray, forState: .normal)
        googleLogin.layer.cornerRadius = facebookLogin.frame.width / 2
        appleLogin.setIcon(icon: .fontAwesomeBrands(.apple), iconSize: 25, color: UIColor.white, backgroundColor: UIColor.darkGray, forState: .normal)
        appleLogin.layer.cornerRadius = facebookLogin.frame.width / 2
    }
    
    @IBAction func facebookLoginPressed(_ sender: Any) {
        delegate?.CustomFBLogin()
    }
    
    @IBAction func googleLoginPressed(_ sender: Any) {
        delegate?.CustomGoogleLogin()
    }
    
    @IBAction func appleLoginPressed(_ sender: Any) {
        delegate?.CustomAppleLogin()
    }
    
    @IBAction func loginPressed(_ sender: Any) {
        guard let email = emailTextfield.text, let password = passwordTextfield.text else {return}
        Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
            if error != nil {
                print(error!._code)
                self.delegate?.showError(error!)      // use the handleError method
                return
            }
            //successfully logged in the user
            self.delegate?.dismissViewController()
        })
    }
}
