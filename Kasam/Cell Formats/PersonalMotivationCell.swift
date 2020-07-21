//
//  KasamSquareCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-05-06.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import SDWebImage

class TodayMotivationCell: UICollectionViewCell {

    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var motivationText: UILabel!
    @IBOutlet weak var blockShadow: UIView!
    @IBOutlet weak var editButton: UIButton!
    
    var motivationID:[String: String] = ["motivationID": "hello"] //MotivationID gets set from Today CollectionView
    
    override func awakeFromNib() {
        blockShadow.layer.cornerRadius = 15.0
        blockShadow.layer.shadowColor = UIColor.black.cgColor
        blockShadow.layer.shadowOpacity = 0.2
        blockShadow.layer.shadowOffset = CGSize.zero
        blockShadow.layer.shadowRadius = 4
        
        editButton?.setIcon(icon: .fontAwesomeSolid(.pencilAlt), iconSize: 15, color: UIColor.colorFour, backgroundColor: UIColor.white, forState: .normal)
        editButton.layer.cornerRadius = editButton.frame.width / 2
        editButton.clipsToBounds = true
        
        backgroundImage.layer.cornerRadius = 15.0
        backgroundImage.clipsToBounds = true
    }
    
    func setBlock(block: String) {
        motivationText.text = block
    }
    
    @IBAction func editbuttonPressed(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "EditMotivation"), object: self, userInfo: motivationID)
    }
}
