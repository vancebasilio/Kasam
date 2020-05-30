//
//  KasamStatsCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-09-12.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit

class WeeklyStatsCell: UICollectionViewCell {
    @IBOutlet weak var MBar: UIView!
    @IBOutlet weak var TBar: UIView!
    @IBOutlet weak var WBar: UIView!
    @IBOutlet weak var RBar: UIView!
    @IBOutlet weak var FBar: UIView!
    @IBOutlet weak var SBar: UIView!
    @IBOutlet weak var SuBar: UIView!
    @IBOutlet weak var collectionView: UIView!
    @IBOutlet weak var averageMetricLabel: UILabel!
    @IBOutlet weak var averageMetric: UILabel!
    @IBOutlet weak var daysLeft: UILabel!
    @IBOutlet weak var kasamTitle: UILabel!
    @IBOutlet weak var MHeight: NSLayoutConstraint!
    @IBOutlet weak var THeight: NSLayoutConstraint!
    @IBOutlet weak var WHeight: NSLayoutConstraint!
    @IBOutlet weak var RHeight: NSLayoutConstraint!
    @IBOutlet weak var FHeight: NSLayoutConstraint!
    @IBOutlet weak var SHeight: NSLayoutConstraint!
    @IBOutlet weak var SuHeight: NSLayoutConstraint!
    var height = CGFloat(0.0)
    
    override func awakeFromNib() {
        collectionView.layer.cornerRadius = 15.0
        collectionView.clipsToBounds = true
        let barArray = [MBar, TBar, WBar, RBar, FBar, SBar, SuBar]
        for i in 0...6 {
            barArray[i]?.layer.cornerRadius = 5
            barArray[i]?.clipsToBounds = true
        }
    }
    
    func setPlaceholder() {
        kasamTitle.text = "Time to add a Kasam!"
        averageMetric.text = "TBD"
        daysLeft.text = "30"
    }
    
    func setBlock(cell: weekStatsFormat) {
        kasamTitle.text = cell.kasamTitle
        let constraintArray = [MHeight, THeight, WHeight, RHeight, FHeight, SHeight, SuHeight]
        for i in 0...6 {
            let pushValue = ((height - 70)  * (CGFloat(cell.metricDictionary[i+1] ?? 0.0)))
            constraintArray[i]?.constant = pushValue
        }
        self.daysLeft.text = String(cell.daysCompleted)
        if cell.metricType == "Time" && cell.avgMetric <= 60 {
            averageMetric.text = String(cell.avgMetric)
            averageMetricLabel.text = "Total secs"
        } else if cell.metricType == "Time" && cell.avgMetric > 60 {
            let time: Double = (Double(cell.avgMetric) / 60.0).rounded(toPlaces: 2)
            averageMetric.text = String(time)
            averageMetricLabel.text = "Total mins"
        } else if cell.metricType == "Reps" {
            averageMetric.text = String(cell.avgMetric)
            averageMetricLabel.text = "Total \(cell.metricType)"
        } else if cell.metricType == "Checkmark" {
            averageMetric.text = String(cell.avgMetric)
            averageMetricLabel.text = "Avg. %"
        }
    }
    
    func setBlankBlock(cell: UserStatsFormat) {
        kasamTitle.text = cell.kasamTitle
        averageMetricLabel.text = "Avg. \(cell.metricType)"
        averageMetric.text = "0"
    }
}
