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
    func statusButtonPressed(row: Int, status: Double, userID: String)
    func removeUser(row:Int, userID: String)
    func showPopTipRemove(row: Int, frame: CGRect)
}

class GroupSearchCell: UITableViewCell {
    
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var checkBox: UIButton!
    
    var status: Double!
    var cellDelegate: GroupCellDelegate?
    var cellTable = "selected"
    let popTip = PopTip()
    var popTipStatus = false
    var row = 0
    var userIDInternal = ""

    override func awakeFromNib() {
        userImage.layer.cornerRadius = 15
        popTip.shouldDismissOnTapOutside = true
        popTip.shouldDismissOnTap = true
        popTip.shouldDismissOnSwipeOutside = true
        popTip.bubbleColor = .colorFour
    }
    
    func setCell (cell: (userID: String, name: String, image: URL?, status: Double)){
        userName.font = UIFont.systemFont(ofSize: 17)
        userName.text = cell.name
        userIDInternal = cell.userID
        checkBox.isHidden = false
        userImage.sd_setImage(with: cell.image, completed: nil)
        status = cell.status
        if cell.status == -2 {                          //Uninvited
            checkBox.setIcon(icon: .fontAwesomeRegular(.circle), iconSize: 30, color: .colorFour, forState: .normal)
        } else if cell.status >= 0 {                    //Invited and joined
           checkBox.setIcon(icon: .fontAwesomeSolid(.checkCircle), iconSize: 30, color: .dayYesColor, forState: .normal)
        } else if cell.status == -1 {                   //Invited, but not joined
            checkBox.setIcon(icon: .fontAwesomeRegular(.checkCircle), iconSize: 30, color: .dayYesColor, forState: .normal)
        }
        userName.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showPopTipInfo)))
    }
    
    func setPlaceholder(){
        userName.text = "Enter the full email address"
        userName.font = UIFont.italicSystemFont(ofSize: 14)
        userImage.setIcon(icon: .fontAwesomeSolid(.userCircle), textColor: .colorFour, backgroundColor: .clear, size: CGSize(width: 20, height: 20))
        checkBox.isHidden = true
    }
    
    func firstCell(){
        userName.isHidden = true
        userImage.isHidden = true
        checkBox.isHidden = true
    }
    
    @IBAction func checkBoxPressed(_ sender: Any) {
        if status == -2 {cellDelegate?.statusButtonPressed(row: row, status: status, userID: userIDInternal)}
        else if status == -1 && cellTable == "selected" {
            cellDelegate?.showPopTipRemove(row: row, frame: checkBox.frame)
        }
    }
    
    @objc func showPopTipInfo(){
        var message = ""
        if status == -1.0 {message = "Pending"}
        else if status >= 0.0 {message = "Joined"}
        popTip.appearHandler = {popTip in self.popTipStatus = true}
        popTip.dismissHandler = {popTip in self.popTipStatus = false}
        if popTipStatus == false {popTip.show(text: message, direction: .right, maxWidth: 200, in: self, from: userName.frame, duration: 2)}
        else {popTip.hide()}
    }
}
