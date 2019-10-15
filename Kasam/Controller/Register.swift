//
//  RegisterController.swift
//  Kasam 1.0
//
//  Created by Vance Basilio on 2019-04-20.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Firebase

class RegisterController: UIViewController {
    
    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Back Button
    @IBAction func backButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func registerPressed(_ sender: AnyObject) {
        
        Auth.auth().createUser(withEmail: emailTextField.text!, password: passwordTextField.text!) { (user, error) in
            
            if error != nil {
                print(error!)
            } else {
                let newUser = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!)
                
                let userDictionary = ["Name": self.firstName.text!, "Bio": "", "ProfileImage": "", "Score": "0", "History" : "", "UserID": Auth.auth().currentUser?.uid, "Following": "", "Type": "User"]
                
                newUser.setValue(userDictionary) {
                    (error, reference) in
                    if error != nil {
                        print(error!)
                    } else {
                        print ("Registration Successful!")
                    }
                }
                
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changeRequest?.displayName = self.firstName.text!
                changeRequest?.commitChanges { (error) in
                    if error != nil{
                        print(error!)
                    } else {
                        print ("username update successful!")
                        self.performSegue(withIdentifier: "goToMainUser", sender: self)
                    }
                }
            }
        }
    }
}
