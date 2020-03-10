//
//  BlocksCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-05-05.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import SDWebImage
import SwiftIcons

protocol TodayCellDelegate {
    func clickedButton(kasamID: String, blockID: String, status: String)
}

protocol TableCellDelegate : class {
    func updateKasamButtonPressed(_ sender: UIButton, kasamOrder: Int)
}

class TodayBlockCell: UITableViewCell {
    
    @IBOutlet weak var kasamName: UILabel!
    @IBOutlet weak var dayNumber: UILabel!
    @IBOutlet weak var currentDayStreak: UILabel!
    @IBOutlet weak var blockContents: UIView!
    @IBOutlet weak var statsContent: UIView!
    @IBOutlet weak var statsShadow: UIView!
    @IBOutlet weak var streakShadow: UIView!
    @IBOutlet weak var blockPlaceholderView: UIStackView!
    @IBOutlet weak var blockPlaceholderBG: UIView!
    @IBOutlet weak var blockPlaceholderAdd: UIImageView!
    @IBOutlet weak var yesButton: UIButton!
    @IBOutlet weak var noButton: UIButton!
    @IBOutlet private weak var dayTrackerCollectionView: UICollectionView!
    
    var cellDelegate: TableCellDelegate?
    var delegate: TodayCellDelegate?
    var row = 0
    var kasamID: String?
    var blockID: String?
    var tempBlock: TodayBlockFormat?
    var today: Int?
    var processedStatus: String?
    let progress = Progress(totalUnitCount: 30)
    
    func setPlaceholder() {
        cellFormatting()
        blockPlaceholderView.isHidden = false
        blockContents.isHidden = true
        statsShadow.backgroundColor = UIColor(patternImage: PlaceHolders.kasamHeaderPlaceholderImage!)
        blockPlaceholderView.isHidden = false
        blockPlaceholderAdd.setIcon(icon: .fontAwesomeSolid(.plus), textColor: .white, backgroundColor: .lightGray, size: CGSize(width: 25, height: 25))
        blockPlaceholderBG.layer.cornerRadius = blockPlaceholderBG.frame.width / 2
        blockPlaceholderBG.clipsToBounds = true
    }
    
    func reloadCollectionView(){
        dayTrackerCollectionView.reloadData()
    }
    
    func removePlaceholder(){
        blockContents.isHidden = false
        blockPlaceholderView.isHidden = true
    }
    
    func setCollectionViewDataSourceDelegate(dataSourceDelegate: UICollectionViewDataSource & UICollectionViewDelegate, forRow row: Int) {
        dayTrackerCollectionView.delegate = dataSourceDelegate
        dayTrackerCollectionView.dataSource = dataSourceDelegate
        dayTrackerCollectionView.tag = row
        dayTrackerCollectionView.reloadData()
    }
    
    func setBlock(block: TodayBlockFormat) {
        cellFormatting()
        statusUpdate()
        tempBlock = block
        kasamID = block.kasamID
        kasamName.text = block.kasamName
        blockID = block.title
        today = Int(block.dayOrder)
        dayNumber.text = "Day \(block.dayOrder)"
        if block.currentStreak != nil {currentDayStreak.text = "\(String(describing: block.currentStreak!))"}
        processedStatus = block.displayStatus
        
        let gradient = CAGradientLayer()
        gradient.frame = dayTrackerCollectionView.superview?.bounds ?? CGRect.zero
        gradient.colors = [UIColor.white.withAlphaComponent(0).cgColor, UIColor.white.cgColor, UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor]
        gradient.locations = [0.0, 0.1, 0.9, 1.0]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        dayTrackerCollectionView.superview?.layer.mask = gradient
    }
    
    func cellFormatting(){
        //Cell formatting
        statsContent.layer.cornerRadius = 16.0
        
        statsShadow.layer.cornerRadius = 16.0
        statsShadow.layer.shadowColor = UIColor.black.cgColor
        statsShadow.layer.shadowOpacity = 0.2
        statsShadow.layer.shadowOffset = CGSize.zero
        statsShadow.layer.shadowRadius = 4
        
        streakShadow.layer.cornerRadius = 16.0
        streakShadow.layer.shadowColor = UIColor.black.cgColor
        streakShadow.layer.shadowOpacity = 0.2
        streakShadow.layer.shadowOffset = CGSize.zero
        streakShadow.layer.shadowRadius = 4
        
        let centerCollectionView = NSNotification.Name("CenterCollectionView")
        NotificationCenter.default.addObserver(self, selector: #selector(TodayBlockCell.centerCollectionView), name: centerCollectionView, object: nil)
    }
    
    @IBAction func yesButtonPressed(_ sender: UIButton) {
        cellDelegate?.updateKasamButtonPressed(sender, kasamOrder: row)
        statusUpdate()
        centerCollectionView()
    }
    
    @IBAction func noButtonPressed(_ sender: UIButton) {
        cellDelegate?.updateKasamButtonPressed(sender, kasamOrder: row)
        statusUpdate()
        centerCollectionView()
    }
    
    @objc func centerCollectionView() {
        if today != nil {
            let indexPath = IndexPath(item: self.today! - 1, section: 0)
            self.dayTrackerCollectionView.collectionViewLayout.prepare()        //ensures the contentsize is accurate before centering cells
            self.dayTrackerCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
    func statusUpdate(){
        let dayYesColor = UIColor.init(hex: 0x66A058)
        let dayNoColor = UIColor.init(hex: 0xcd742c)
        
        if tempBlock?.displayStatus == "Checkmark" {
            streakShadow.backgroundColor = UIColor.colorFour
            yesButton?.setIcon(icon: .fontAwesomeRegular(.checkCircle), iconSize: 30, color: dayYesColor, forState: .normal)
            noButton?.setIcon(icon: .fontAwesomeRegular(.timesCircle), iconSize: 30, color: dayNoColor, forState: .normal)
        } else if tempBlock?.displayStatus == "Check" {
            streakShadow.backgroundColor = dayYesColor
            noButton?.setIcon(icon: .fontAwesomeRegular(.timesCircle), iconSize: 30, color: dayNoColor, forState: .normal)
            yesButton?.setIcon(icon: .fontAwesomeSolid(.checkCircle), iconSize: 30, color: dayYesColor, forState: .normal)
        } else if tempBlock?.displayStatus == "Uncheck" {
            streakShadow.backgroundColor = dayNoColor
            yesButton?.setIcon(icon: .fontAwesomeRegular(.checkCircle), iconSize: 30, color: dayYesColor, forState: .normal)
            noButton?.setIcon(icon: .fontAwesomeSolid(.timesCircle), iconSize: 30, color: dayNoColor, forState: .normal)
        } else if tempBlock?.displayStatus == "Progress" {
            yesButton?.setIcon(icon: .fontAwesomeSolid(.cookieBite), iconSize: 30, color: UIColor.colorFour, forState: .normal)
        }
    }
}
