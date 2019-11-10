//
//  RegisterViewCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-11-09.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit

class RegisterViewCell: UICollectionViewCell {
    
    @IBOutlet weak var usernameTextfield: UITextField!
    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        initializeButtons()
    }
    
    func initializeButtons(){
        registerButton.backgroundColor = UIColor.colorFive
        registerButton.layer.cornerRadius = registerButton.frame.height / 2
    }
    
    
    
    
}
