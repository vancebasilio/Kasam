//
//  LoginViewCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-11-09.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit

protocol LoginViewCellDelegate {
    func dismissViewController()
    func presentAlert(alert:UIAlertController)
    func CustomFBLogin()
    func CustomGoogleLogin()
}

class LoginViewCell: UICollectionViewCell {
    
    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    @IBOutlet weak var manualLogin: UIButton!
    @IBOutlet weak var facebookLogin: UIButton!
    @IBOutlet weak var googleLogin: UIButton!
    
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
        facebookLogin.clipsToBounds = true
        googleLogin.setIcon(icon: .fontAwesomeBrands(.google), iconSize: 25, color: UIColor.white, backgroundColor: UIColor.darkGray, forState: .normal)
        googleLogin.layer.cornerRadius = facebookLogin.frame.width / 2
        googleLogin.clipsToBounds = true
    }
    
    @IBAction func facebookLoginPressed(_ sender: Any) {
        delegate?.CustomFBLogin()
    }
    
    @IBAction func googleLoginPressed(_ sender: Any) {
        delegate?.CustomGoogleLogin()
    }
    
    
    @IBAction func loginPressed(_ sender: Any) {
        guard let email = emailTextfield.text, let password = passwordTextfield.text else {return}
        
        Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
            if error != nil {
                print(error!._code)
                self.handleError(error!)      // use the handleError method
                return
            }
            //successfully logged in the user
            self.delegate?.dismissViewController()
        })
    }
}

extension AuthErrorCode {
    var errorMessage: String {
        switch self {
        case .emailAlreadyInUse:
            return "The email is already in use with another account"
        case .userNotFound:
            return "Account not found for the specified user. Please check and try again"
        case .userDisabled:
            return "Your account has been disabled. Please contact support."
        case .invalidEmail, .invalidSender, .invalidRecipientEmail:
            return "Please enter a valid email"
        case .networkError:
            return "Network error. Please try again."
        case .weakPassword:
            return "Your password is too weak. The password must be 6 characters long or more."
        case .wrongPassword:
            return "Your password is incorrect. Please try again or use 'Forgot password' to reset your password"
        default:
            return "Unknown error occurred"
        }
    }
}


extension LoginViewCell {
    func handleError(_ error: Error) {
        if let errorCode = AuthErrorCode(rawValue: error._code) {
            print(errorCode.errorMessage)
            let alert = UIAlertController(title: "Error", message: errorCode.errorMessage, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alert.addAction(okAction)
            delegate?.presentAlert(alert: alert)
        }
    }
}
