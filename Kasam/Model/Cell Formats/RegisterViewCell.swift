//
//  RegisterViewCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-11-09.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Firebase

protocol RegisterViewCellDelegate {
    func performSegue()
    func showError(_ error: Error)
    func dismissViewController()
}

class RegisterViewCell: UICollectionViewCell {
    
    @IBOutlet weak var usernameTextfield: UITextField!
    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    
    var delegate: RegisterViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        initializeButtons()
    }
    
    func initializeButtons(){
        registerButton.backgroundColor = UIColor.colorFive
        registerButton.layer.cornerRadius = registerButton.frame.height / 2
    }
    
    @IBAction func registerButtonPressed(_ sender: Any) {
        Auth.auth().createUser(withEmail: emailTextfield.text!, password: passwordTextfield.text!) { (user, error) in
            if error != nil {
                self.delegate?.showError(error!)
            } else {
                let newUser = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!)
                let userDictionary = ["Name": self.usernameTextfield.text!, "Bio": "", "ProfileImage": "", "Score": "0", "History" : "", "UserID": Auth.auth().currentUser?.uid, "Following": "", "Type": "User"]
                
                newUser.setValue(userDictionary) {(error, reference) in
                    if error != nil {
                        print(error!)
                    } else {
                        print ("Registration Successful!")
                        self.delegate?.dismissViewController()
                    }
                }
                
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changeRequest?.displayName = self.usernameTextfield.text!
                changeRequest?.commitChanges {(error) in
                    if error != nil{
                        print(error!)
                    } else {
                        //username update successful
                    }
                }
            }
        }
    }
}
