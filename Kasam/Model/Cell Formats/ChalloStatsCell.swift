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
    @IBOutlet weak var averageMetricLabel: UILabel!
    @IBOutlet weak var avearageMetric: UILabel!
    @IBOutlet weak var daysLeft: UILabel!
    @IBOutlet weak var kasamTitle: UILabel!
    
    override func awakeFromNib() {
        collectionView.layer.cornerRadius = 15.0
        collectionView.clipsToBounds = true
        let barArray = [MBar, TBar, WBar, RBar, FBar, SBar, SuBar]
        for i in 0...6 {
            barArray[i]?.layer.cornerRadius = 4
            barArray[i]?.clipsToBounds = true
        }
    }
    
    func setBlock(cell: challoStatFormat) {
        let constraintArray = [MTopMargin, TTopMargin, WTopMargin, RTopMargin, FTopMargin, STopMargin, SuTopMargin]
        for i in 0...6{
            let pushValue = 15 + (((containerView.frame.size.height) - 47)  * (1 - CGFloat(cell.metricDictionary[i+1] ?? 0.0)))
            constraintArray[i]?.constant = pushValue
        }
    }
}
