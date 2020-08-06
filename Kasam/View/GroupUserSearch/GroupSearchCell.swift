//
//  GroupSearchCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2020-08-04.
//  Copyright © 2020 Vance Basilio. All rights reserved.
//

import UIKit
import AMPopTip

protocol GroupCellDelegate : class {
    func statusButtonPressed()
}

class GroupSearchCell: UITableViewCell {
    
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var checkBox: UIButton!
    
    var status: Double!
    var popTipStatus = false
    var cellDelegate: GroupCellDelegate?
    let popTip = PopTip()

    override func awakeFromNib() {
        userImage.layer.cornerRadius = 15
        popTip.bubbleColor = .darkGray
        popTip.shouldDismissOnTapOutside = true
        popTip.shouldDismissOnTap = true
        popTip.shouldDismissOnSwipeOutside = true
    }
    
    func setCell (cell: (name: String, image: URL?, status: Double)){
        userName.text = cell.name
        userImage.sd_setImage(with: cell.image, completed: nil)
        status = cell.status
        if cell.status == -2 {                          //Uninvited
            checkBox.setIcon(icon: .fontAwesomeRegular(.circle), iconSize: 30, color: .colorFour, forState: .normal)
        } else if cell.status >= 0 {                    //Invited and joined
           checkBox.setIcon(icon: .fontAwesomeSolid(.checkCircle), iconSize: 30, color: .dayYesColor, forState: .normal)
        } else if cell.status == -1 {                   //Invited, but not joined
            checkBox.setIcon(icon: .fontAwesomeRegular(.checkCircle), iconSize: 30, color: .dayYesColor, forState: .normal)
        }
    }
    
    @IBAction func checkBoxPressed(_ sender: Any) {
        var message = ""
        popTip.appearHandler = {popTip in self.popTipStatus = true}
        popTip.dismissHandler = {popTip in self.popTipStatus = false}
        if status == -2 {
//            checkBox.setIcon(icon: .fontAwesomeRegular(.circle), iconSize: 30, color: .colorFour, forState: .normal)
        } else if status >= 0.0 {
            message = "Joined"
//            checkBox.setIcon(icon: .fontAwesomeRegular(.checkCircle), iconSize: 30, color: .dayYesColor, forState: .normal)
        } else if status == -1 {
            message = "Invite not accepted"
        }
        if popTipStatus == false {popTip.show(text: message, direction: .left, maxWidth: 200, in: self, from: checkBox.frame, duration: 1)}
        else {popTip.hide()}
    }
}
