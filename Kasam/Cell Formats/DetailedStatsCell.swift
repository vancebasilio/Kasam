//
//  KasamHistoryTableCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-09-28.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Charts
import SwipeCellKit
import Charts

class KasamHistoryTableCell: SwipeTableViewCell {
    
    @IBOutlet weak var sectionView: UIView!
    @IBOutlet weak var sectionTitle: UILabel!
    @IBOutlet weak var dropdownArrow: UIButton!
    
    @IBOutlet weak var rowView: UIView!
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var metricLabel: UILabel!
    
    
    
    var dataEntries: [ChartDataEntry] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setSection(title: String, open: Bool){
        dropdownArrow.setIcon(icon: .fontAwesomeSolid(.chevronCircleRight), iconSize: 20, color: UIColor.darkGray, backgroundColor: .clear, forState: .normal)
        if open == true {dropdownArrow.rotate(.pi / 2)}
        rowView.isHidden = true
        sectionView.isHidden = false
        sectionTitle.text = title
        sectionTitle.textColor = .colorFive
    }
    
    func setBlock(block: kasamFollowingFormat) {
        rowView.isHidden = false
        sectionView.isHidden = true
        dayLabel.text = "Day \(block.day)"
        dateLabel.text = block.shortDate
        metricLabel.text = block.metric
    }
    
    //CHART--------------------------------------------------------------------------------------------------------
    
//    func setChart(values: [Int:Double]) {
//        mChart.noDataText = "No data available!"
//        let dayUpperBound = ((values.keys.sorted().last.map({ ($0, values[$0]!) }))?.0) ?? 0
//        for i in 1...dayUpperBound {
//            let dataEntry = ChartDataEntry(x: Double(i), y: Double(values[i] ?? 0))
//            dataEntries.append(dataEntry)
//        }
//        let line1 = LineChartDataSet(entries: dataEntries, label: "Units Consumed")
//        line1.colors = [NSUIColor.colorFour]
//        line1.mode = .horizontalBezier
//        line1.cubicIntensity = 0.2
//
//        let gradient = getGradientFilling()
//        line1.fill = Fill.fillWithLinearGradient(gradient, angle: 90.0)
//        line1.drawFilledEnabled = true
//        line1.lineWidth = 2
//        line1.drawCirclesEnabled = true
//        line1.circleColors = [UIColor.colorFour]
//        line1.circleRadius = 4
//        line1.drawHorizontalHighlightIndicatorEnabled = false   //highlight lines
//        line1.drawVerticalHighlightIndicatorEnabled = false     //highlight lines
//
//        let data = LineChartData()
//        data.addDataSet(line1)
//        mChart.data = data
//
//        for set in mChart.data!.dataSets {set.drawValuesEnabled = !set.drawValuesEnabled}      //removes the titles above each datapoint
//        mChart.leftAxis.axisMinimum = 1.0
//        mChart.xAxis.axisMaximum = Double(dayUpperBound) - 1.0
//        mChart.xAxis.axisMinimum = 1.0
//        dataEntries.removeAll()
//    }
//
//    func setupChart(){
//        let marker = BalloonMarker(color: UIColor.colorFour, font: .systemFont(ofSize: 12), textColor: .white, insets: UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8))
//        marker.chartView = mChart
//        marker.minimumSize = CGSize(width: 40, height: 40)
//        mChart.marker = marker
//
//        let backColor = UIColor.white
//        mChart.gridBackgroundColor = backColor
//        mChart.backgroundColor = backColor
//
//        mChart.setScaleEnabled(false)
//        mChart.animate(yAxisDuration: 0.5)
//        mChart.drawGridBackgroundEnabled = true
//        mChart.legend.enabled = false
//        mChart.xAxis.enabled = true
//
//        //Labels
//        mChart.xAxis.drawLabelsEnabled = true //horizontal axis labels
//        mChart.xAxis.labelPosition = .bottom
//        mChart.xAxis.labelTextColor = UIColor.init(hex: 0x7F7F7F)
//        mChart.xAxis.labelFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
//        mChart.leftAxis.labelTextColor = UIColor.init(hex: 0x7F7F7F)
//        mChart.leftAxis.labelFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
//
//        mChart.xAxis.drawAxisLineEnabled = true         //horizontal axis
//        mChart.xAxis.drawGridLinesEnabled = false       //vertical lines
//        mChart.xAxis.gridLineDashLengths = [5, 5]
//        mChart.xAxis.gridLineDashPhase = 0
//        mChart.xAxis.granularityEnabled = true
//
//        mChart.leftAxis.enabled = true
//        mChart.leftAxis.drawAxisLineEnabled = true      //y axis
//        mChart.leftAxis.drawGridLinesEnabled = false    //horizontal lines
//
//        mChart.rightAxis.enabled = false
//        mChart.rightAxis.drawAxisLineEnabled = true
//        mChart.rightAxis.drawGridLinesEnabled = false
//    }
}
