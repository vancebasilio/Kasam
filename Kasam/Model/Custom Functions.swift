//
//  Custom Functions.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-06-10.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Foundation
import Firebase
import AVKit
import Lottie

class ProgessView: UIProgressView {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let maskLayerPath = UIBezierPath(roundedRect: bounds, cornerRadius: 4.0)
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.bounds
        maskLayer.path = maskLayerPath.cgPath
        layer.mask = maskLayer
    }
}

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
    
    func setupGreeting() -> String {
        let truncUserFirst = Auth.auth().currentUser?.displayName?.split(separator: " ").first.map(String.init) ?? "Username"
        return truncUserFirst
    }
    
    func placeholder() -> Any {
        let placeholder = URL(string: "https://firebasestorage.googleapis.com/v0/b/kasam-coach.appspot.com/o/kasam%2Fplaceholder.jpg?alt=media&token=580f119e-b022-4782-9bfd-0464a5b55c7e")!
        return placeholder
    }
    
    func loadingAnimation(animationView: AnimationView, animation: String, height: Int, overlayView: UIView?, loop: Bool, completion: (() -> Void)?){
        animationView.animation = Animation.named(animation)
        animationView.contentMode = .scaleAspectFit
        
        if overlayView != nil  {
            if let window = view.window {
                overlayView?.frame = window.frame
                overlayView?.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
                window.addSubview(overlayView!)
            }
        }
        view.addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.centerXAnchor.constraint(lessThanOrEqualTo: self.view.centerXAnchor).isActive = true
        animationView.centerYAnchor.constraint(lessThanOrEqualTo: self.view.centerYAnchor).isActive = true
        NSLayoutConstraint(item: animationView, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: CGFloat(height)).isActive = true
        NSLayoutConstraint(item: animationView, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: CGFloat(height)).isActive = true
        animationView.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        animationView.play()
        if loop == true {
            animationView.loopMode = .loop
        } else {
            animationView.play{(finished) in
                completion!()
            }
        }
    }
    
    func setupNavBar(){
        let logo = UIImage(named: "Challo-logo")
        let imageView = UIImageView(image:logo)
        imageView.contentMode = .scaleAspectFit
        self.navigationItem.titleView = imageView
        
        self.navigationController?.navigationBar.layer.shadowColor = UIColor.colorFive.cgColor
        self.navigationController?.navigationBar.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        self.navigationController?.navigationBar.layer.shadowRadius = 1.0
        self.navigationController?.navigationBar.layer.shadowOpacity = 0.5
        self.navigationController?.navigationBar.layer.masksToBounds = false
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
    
    func getCurrentDateTime() -> String? {
        let currentDateTime = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .long
        formatter.dateStyle = .short
        let finalDate = formatter.string(from: currentDateTime)
        return finalDate
    }
    
    func getCurrentTime() -> String? {
        let currentDateTime = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .long
        formatter.dateStyle = .none
        let finalDate = formatter.string(from: currentDateTime)
        return finalDate
    }
    
    func getCurrentDate() -> String? {
        let currentDateTime = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateFormat = "yyyy-MM-dd"                                     //***keep this value the same as below
        let finalDate = formatter.string(from: currentDateTime)
        return finalDate
    }
    
    func stringToDate(date: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let kasamDate = dateFormatter.date(from: date)
        return kasamDate!
    }
    
    func dateFormat(date: Date) -> String {
        let date = date
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateFormat = "yyyy-MM-dd"                                     //***keep this value the same as above
        let finalDate = formatter.string(from: date)
        return finalDate
    }
    
    func convertLongDateToShort(date: String) -> String {
        var dateOutput = ""
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd"                              //***keep this value the same as above
        
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "MMM dd"
        
        if let date = dateFormatterGet.date(from: date) {
            dateOutput = dateFormatterPrint.string(from: date)
        } else {
            print("There was an error converting the date")
        }
        return dateOutput
    }
    
    func convertTimeAndMetric(time: Double, metric: String ) -> (Double, String) {
        var convertedTime = time
        var convertedMetric = metric
        if time < 60 {
            convertedMetric = "secs"
        } else if time >= 60 && time < 66 {
            convertedTime = time / 60.0
            convertedMetric = "min"
        } else if time >= 66 && time < 3600 {
            convertedTime = time / 60.0
            convertedMetric = "mins"
        } else if time >= 3600 && time < 3636 {
            convertedTime = time / 3600.0
            convertedMetric = "hour"
        } else if time >= 3636 {
            convertedTime = time / 3600.0
            convertedMetric = "hours"
        }
        return (convertedTime, convertedMetric)
    }
    
    func twitterParallaxScrollDelegate(scrollView: UIScrollView, headerHeight: CGFloat, headerView: UIView, headerBlurImageView: UIView?, headerLabel: UILabel, offsetHeaderStop: CGFloat, offsetLabelHeader: CGFloat, shrinkingButton: UIButton?, shrinkingButton2: UIButton?, mainTitle: UIView){
        let offset = scrollView.contentOffset.y + headerView.bounds.height
        var avatarTransform = CATransform3DIdentity
        var headerTransform = CATransform3DIdentity
        
        //controls the image white overlay, when it shows and when it disappears
        let alignToNameLabel = -offset + mainTitle.frame.origin.y + headerView.frame.height + offsetHeaderStop
        headerBlurImageView?.alpha = min (1.0, (offset + 220 - alignToNameLabel)/(offsetLabelHeader + 50))
        
        // PULL DOWN -----------------
        if offset < 0 {
            let headerScaleFactor:CGFloat = -(offset) / headerView.bounds.height
            let headerSizevariation = ((headerView.bounds.height * (1.0 + headerScaleFactor)) - headerView.bounds.height)/2
            headerTransform = CATransform3DTranslate(headerTransform, 0, headerSizevariation, 0)
            headerTransform = CATransform3DScale(headerTransform, 1.0 + headerScaleFactor, 1.0 + headerScaleFactor, 0)
            
            // Hide views if scrolled super fast
            headerView.layer.zPosition = 0
            headerLabel.isHidden = true
            
            if let navBar = self.navigationController?.navigationBar {
                navBar.tintColor = UIColor.white                //makes the back button white
            }
        }
            
        // SCROLL UP/DOWN ------------
        else {
            //Header -----------
            headerTransform = CATransform3DTranslate(headerTransform, 0, max(-offsetHeaderStop, -offset), 0)
            
            //Label ------------
            headerLabel.isHidden = false
            headerLabel.frame.origin = CGPoint(x: headerLabel.frame.origin.x, y: max(alignToNameLabel, offsetLabelHeader + offsetHeaderStop))
            
            //Blur ------------
            if let navBar = self.navigationController?.navigationBar {
                let scrollPercentage = Double(min (1.0, (offset + 220 - alignToNameLabel)/(offsetLabelHeader + 50)))
                navBar.tintColor = scrollColor(percent: scrollPercentage)
            }
            
            //Avatar -----------
            var avatarScaleFactor = CGFloat(0)
            avatarScaleFactor = (min(offsetHeaderStop, offset)) / (shrinkingButton?.bounds.height ?? 1) / 9.4 // Slow down the animation
            let avatarSizeVariation = (1.0 + avatarScaleFactor) / 2.0
            avatarTransform = CATransform3DTranslate(avatarTransform, 0, avatarSizeVariation, 0)
            avatarTransform = CATransform3DScale(avatarTransform, 1.0 - avatarScaleFactor, 1.0 - avatarScaleFactor, 0)
            
            if offset <= offsetHeaderStop {
                headerView.layer.zPosition = 0
            } else {
                headerView.layer.zPosition = 2
            }
        }
        // Apply Transformations
        headerView.layer.transform = headerTransform
        shrinkingButton?.layer.transform = avatarTransform
        shrinkingButton2?.layer.transform = avatarTransform
    }
    
    func twitterParallaxHeaderSetup(headerBlurImageView: UIImageView?, headerImageView: UIImageView, headerView: UIView, headerLabel: UILabel) -> UIImageView? {
        var headerBlurImageView = headerBlurImageView
        
        if let navBar = self.navigationController?.navigationBar {
            extendedLayoutIncludesOpaqueBars = true
            navBar.isTranslucent = true
            navBar.backgroundColor = UIColor.white.withAlphaComponent(0)
            navBar.setBackgroundImage(UIImage(), for: .default)
            navBar.shadowImage = UIImage()         //remove bottom border on navigation bar
            navBar.tintColor = UIColor.colorFive   //change back arrow to gold
        }
        
        //align header image to top
        headerImageView.translatesAutoresizingMaskIntoConstraints = false
        let topConstraint = NSLayoutConstraint(item: headerImageView, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: headerView, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: headerImageView, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: headerView, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1, constant: 0)
        let trailingConstraint = NSLayoutConstraint(item: headerImageView, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: headerView, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1, constant: 0)
        let leadingConstraint = NSLayoutConstraint(item: headerImageView, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: headerView, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1, constant: 0)
        headerView.addConstraints([topConstraint, bottomConstraint, trailingConstraint, leadingConstraint])
        
        //setup blur image, which creates the white navbar that appears as you scroll up
        headerBlurImageView = UIImageView(frame: view.bounds)
        headerBlurImageView?.backgroundColor = UIColor.white
        headerBlurImageView?.contentMode = UIView.ContentMode.scaleAspectFill
        headerBlurImageView?.alpha = 0.0
        headerView.clipsToBounds = true
        headerView.insertSubview(headerBlurImageView!, belowSubview: headerLabel)
        
        return headerBlurImageView
    }
    
    //programatically switching tabBars
    func animateTabBarChange(tabBarController: UITabBarController, to viewController: UIViewController) {
        let fromView: UIView = tabBarController.selectedViewController!.view
        let toView: UIView = viewController.view
        if fromView != toView {
            UIView.transition(from: fromView, to: toView, duration: 0.3, options: [.transitionCrossDissolve], completion: nil)
        }
    }
}

extension Double {
    func removeZerosFromEnd() -> String {
        let formatter = NumberFormatter()
        let number = NSNumber(value: self)
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 16 //maximum digits in Double after dot (maximum precision)
        return String(formatter.string(from: number) ?? "")
    }
}

extension Date {
    func dayOfWeek() -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"                                       //gets the day, e.g. "Wednesday"
        return dateFormatter.string(from: self).capitalized
    }
    
    func dayNumberOfWeek() -> Int? {
        return Calendar.current.dateComponents([.weekday], from: self).weekday
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

extension UICollectionViewCell {
    func getCurrentDateTime() -> String? {
        let currentDateTime = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .long
        let finalDate = formatter.string(from: currentDateTime)
        return finalDate
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
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.init(hex: 0x4b3b00), NSAttributedString.Key.font: navigationFont]
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

extension TimeInterval{
    func stringFromTimeInterval() -> String {
        let time = NSInteger(self)
        let ms = Int((self.truncatingRemainder(dividingBy: 1)) * 1000)
        let seconds = time % 60
        let minutes = (time / 60) % 60
        let hours = (time / 3600)
        return String(format: "%0.2d:%0.2d:%0.2d.%0.3d",hours,minutes,seconds,ms)
    }
}

extension UIView{
    func roundedLeft(){
        let maskPath1 = UIBezierPath(roundedRect: bounds, byRoundingCorners: [.topLeft , .bottomLeft], cornerRadii: CGSize(width: 8, height: 8))
        let maskLayer1 = CAShapeLayer()
        maskLayer1.frame = bounds
        maskLayer1.path = maskPath1.cgPath
        layer.mask = maskLayer1
    }
    
    func roundedRight(){
        let maskPath1 = UIBezierPath(roundedRect: bounds, byRoundingCorners: [.topRight , .bottomRight], cornerRadii: CGSize(width: 8, height: 8))
        let maskLayer1 = CAShapeLayer()
        maskLayer1.frame = bounds
        maskLayer1.path = maskPath1.cgPath
        layer.mask = maskLayer1
    }
}

extension Double {
    // Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

extension BidirectionalCollection where Element: StringProtocol {
    var sentence: String {
        guard let last = last else { return "" }
        return count <= 2 ? joined(separator: " and ") :
            dropLast().joined(separator: ", ") + ", and " + last
    }
}

extension Int {
    func convertIntTimeToSplitInt(fullIntTime: Int) -> (hours: Int, mins: Int, secs: Int) {
        let hours = fullIntTime / 3600
        let mins = fullIntTime / 60 % 60
        let secs = fullIntTime % 60
        return (hours: hours, mins: mins, secs: secs)
    }
}
