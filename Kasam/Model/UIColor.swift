//
//  UIColor.swift
//  customcolor
//
//  Created by Andrew Seeley on 25/5/17.
//  Copyright © 2017 Seemu. All rights reserved.
//

import UIKit

extension UIColor {
    
    // Setup custom colours we can use throughout the app using hex values
    static let baseColor = UIColor(red: 52, green: 43, blue: 69)
    static let colorTwo = UIColor(red: 227, green: 201, blue: 163)
    static let colorThree = UIColor(red: 234, green: 200, blue: 112)
    static let colorFour = UIColor(hex: 0xE5BB58)     //gold
    static let colorFive = UIColor(hex: 0xC3962D) //dark gold
    static let greyBackground = UIColor(hex: 0xF6F6F8) //light grey background
    static let dayYesColor = UIColor.init(hex: 0x66A058)
    static let dayNoColor = UIColor.init(hex: 0xcd742c)
    static let cancelColor = UIColor.init(hex: 0xDB482D)
    
    static let seemuBlue = UIColor(hex: 0x00adf7)
    static let transparentBlack = UIColor(hex: 0x000000, a: 0.5)
    static let kasamYellow = UIColor(red: 232, green: 196, blue: 105)
    
    // Create a UIColor from RGB
    convenience init(red: Int, green: Int, blue: Int, a: CGFloat = 1.0) {
        self.init(
            red: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: a
        )
    }
    
    // Create a UIColor from a hex value (E.g 0x000000)
    convenience init(hex: Int, a: CGFloat = 1.0) {
        self.init(
            red: (hex >> 16) & 0xFF,
            green: (hex >> 8) & 0xFF,
            blue: hex & 0xFF,
            a: a
        )
    }
}

