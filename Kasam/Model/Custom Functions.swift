//
//  Custom Functions.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-06-10.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Foundation
import AVKit

extension UIViewController {
    //func to hide keyboard when screen tapped
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func getBlockVideo (url: String){
        guard let videoURL = URL(string: url) else {
            return
        }
        let player = AVPlayer(url: videoURL)
        let controller = AVPlayerViewController()
        controller.player = player
        
        present(controller, animated: true) {
            controller.player!.play()
        }
    }
    
    // A percent of 0.0 gives the "from" color
    // A percent of 1.0 gives the "to" color
    // Any other percent gives an appropriate color in between the two
    func blend(from: UIColor, to: UIColor, percent: Double) -> UIColor {
        var fR : CGFloat = 0.0
        var fG : CGFloat = 0.0
        var fB : CGFloat = 0.0
        var tR : CGFloat = 0.0
        var tG : CGFloat = 0.0
        var tB : CGFloat = 0.0
        
        from.getRed(&fR, green: &fG, blue: &fB, alpha: nil)
        to.getRed(&tR, green: &tG, blue: &tB, alpha: nil)
        
        let dR = tR - fR
        let dG = tG - fG
        let dB = tB - fB
        
        let rR = fR + dR * CGFloat(percent)
        let rG = fG + dG * CGFloat(percent)
        let rB = fB + dB * CGFloat(percent)
        
        return UIColor(red: rR, green: rG, blue: rB, alpha: 1.0)
    }
    
    // Pass in the scroll percentage to get the appropriate color
    func scrollColor(percent: Double) -> UIColor {
        var start : UIColor
        var end : UIColor
        var perc = percent
        if percent < 0.5 {
            // If the scroll percentage is 0.0..<0.5 blend between yellow and green
            start = UIColor.white
            end = UIColor.black
        } else {
            // If the scroll percentage is 0.5..1.0 blend between green and blue
            start = UIColor.black
            end = UIColor.colorFive
            perc -= 0.5
        }
        return blend(from: start, to: end, percent: perc * 2.0)
    }
}

extension Date {
    func dayOfWeek() -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: self).capitalized
    }
}

extension UIView {
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(red: (rgb >> 16) & 0xFF, green: (rgb >> 8) & 0xFF, blue: rgb & 0xFF)
    }
}

extension String {
    func slice(from: String, to: String) -> String? {
        
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
}

extension UINavigationItem {
    override open func awakeFromNib() {
        super.awakeFromNib()
        //customize the back button
        let backImage = UIImage(named: "back-button")
        UIGraphicsBeginImageContextWithOptions(CGSize(width: (backImage?.size.width ?? 0.0) + 20, height: backImage?.size.height ?? 0.0), _: false, _: 0) // move the pic by 10, change it to the num you want
        backImage?.draw(at: CGPoint(x: 20, y: 0))
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        //Remove the standard tints
        UINavigationBar.appearance().backIndicatorImage = finalImage
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = finalImage
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.clear], for: .normal)
        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.clear], for: UIControl.State.highlighted)
        
        //Set the navigation bar title to gold and text color to white        
        let navigationFont = UIFont.systemFont(ofSize: 20, weight: .semibold)
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.init(hex: 0x4b3b00), NSAttributedStringKey.font: navigationFont]
//        UINavigationBar.appearance().barTintColor = UIColor.init(hex: 0xffc900)
        UINavigationBar.appearance().barTintColor = UIColor.white
    }
}

extension UIImage {
    func resizeTopAlignedToFill(newWidth: CGFloat) -> UIImage? {
        let newHeight = size.height
        let newSize = CGSize(width: newWidth, height: newHeight)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, UIScreen.main.scale)
        draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
