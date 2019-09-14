//
//  ChalloStatsCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-09-12.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit

class ChalloStatsCell: UICollectionViewCell {
    @IBOutlet weak var MTopMargin: NSLayoutConstraint!
    @IBOutlet weak var TTopMargin: NSLayoutConstraint!
    @IBOutlet weak var WTopMargin: NSLayoutConstraint!
    @IBOutlet weak var RTopMargin: NSLayoutConstraint!
    @IBOutlet weak var FTopMargin: NSLayoutConstraint!
    @IBOutlet weak var STopMargin: NSLayoutConstraint!
    @IBOutlet weak var SuTopMargin: NSLayoutConstraint!
    @IBOutlet weak var MBar: UIView!
    @IBOutlet weak var TBar: UIView!
    @IBOutlet weak var WBar: UIView!
    @IBOutlet weak var RBar: UIView!
    @IBOutlet weak var FBar: UIView!
    @IBOutlet weak var SBar: UIView!
    @IBOutlet weak var SuBar: UIView!
    @IBOutlet weak var containerView: UIStackView!
    @IBOutlet weak var collectionView: UIView!
    
    override func awakeFromNib() {
        collectionView.layer.cornerRadius = 15.0
        collectionView.clipsToBounds = true
        MBar.layer.cornerRadius = 4
        MBar.clipsToBounds = true
        TBar.layer.cornerRadius = 4
        TBar.clipsToBounds = true
        WBar.layer.cornerRadius = 4
        WBar.clipsToBounds = true
        RBar.layer.cornerRadius = 4
        RBar.clipsToBounds = true
        FBar.layer.cornerRadius = 4
        FBar.clipsToBounds = true
        SBar.layer.cornerRadius = 4
        SBar.clipsToBounds = true
        SuBar.layer.cornerRadius = 4
        SuBar.clipsToBounds = true
    }
    
    func setBlock(cell: challoStatFormat) {
        MTopMargin.constant = 15 + (((containerView.frame.size.height) - 47)  * (1 - CGFloat(cell.metricDictionary[1] ?? 0.0)))
        TTopMargin.constant = 15 + (((containerView.frame.size.height) - 47)  * (1 - CGFloat(cell.metricDictionary[2] ?? 0.0)))
        WTopMargin.constant = 15 + (((containerView.frame.size.height) - 47)  * (1 - CGFloat(cell.metricDictionary[3] ?? 0.0)))
        RTopMargin.constant = 15 + (((containerView.frame.size.height) - 47)  * (1 - CGFloat(cell.metricDictionary[4] ?? 0.0)))
        FTopMargin.constant = 15 + (((containerView.frame.size.height) - 47)  * (1 - CGFloat(cell.metricDictionary[5] ?? 0.0)))
        STopMargin.constant = 15 + (((containerView.frame.size.height) - 47)  * (1 - CGFloat(cell.metricDictionary[6] ?? 0.0)))
        SuTopMargin.constant = 15 + (((containerView.frame.size.height) - 47)  * (1 - CGFloat(cell.metricDictionary[7] ?? 0.0)))
    }
}
