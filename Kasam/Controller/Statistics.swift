//
//  Statistics.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-09-28.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Firebase
import Charts

class StatisticsViewController: UIViewController {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var mChart: LineChartView!
    @IBOutlet weak var historyTableView: UITableView!
    @IBOutlet weak var historyView: UIView!
    
    var dataEntries: [ChartDataEntry] = []
    var kasamID = ""
    var kasamName = ""
    var kasamMetricType = ""
    var kasamBlocks: [kasamFollowingFormat] = []
    var kasamFollowingRefHandle: DatabaseHandle!
    var kasamHistoryRef: DatabaseReference! = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("History")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getKasamStats()
        mChart.layer.cornerRadius = 30.0
        mChart.clipsToBounds = true
        setChart(values: [24.0,43.0,56.0,23.0,56.0,68.0,48.0,120.0,41.0,24.0,43.0,56.0,23.0,56.0,68.0,48.0,120.0,41.0,24.0,43.0,56.0,23.0,56.0,68.0,48.0,120.0,41.0,40.0,40.0,30.0,20.0,30.0,10.0])
        backButton.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight: .semibold), prefixTextColor: UIColor.darkGray, icon: .fontAwesomeSolid(.chevronLeft), iconColor: UIColor.darkGray, postfixText: "   Profile", postfixTextFont: UIFont.systemFont(ofSize: 15, weight: .semibold), postfixTextColor: UIColor.darkGray, backgroundColor: UIColor.clear, forState: .normal, iconSize: 15)
    }
    
    func setChart(values: [Double]) {
        mChart.noDataText = "No data available!"
        for i in 0..<values.count {
            print("chart point : \(values[i])")
            let dataEntry = ChartDataEntry(x: Double(i), y: values[i])
            dataEntries.append(dataEntry)
        }
        let line1 = LineChartDataSet(entries: dataEntries, label: "Units Consumed")
        line1.colors = [NSUIColor.init(hex: 0xE1B29F)]
        line1.mode = .cubicBezier
        line1.cubicIntensity = 0.2
        
//        let gradient = getGradientFilling()
//        line1.fill = Fill.fillWithLinearGradient(gradient, angle: 90.0)
//        line1.drawFilledEnabled = true
        line1.lineWidth = 4
        line1.drawCirclesEnabled = false
        
        let data = LineChartData()
        data.addDataSet(line1)
        mChart.data = data
        
        let marker = BalloonMarker(color: UIColor(white: 180/255, alpha: 1),
                                   font: .systemFont(ofSize: 12),
                                   textColor: .white,
                                   insets: UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8))
        marker.chartView = mChart
        marker.minimumSize = CGSize(width: 80, height: 40)
        mChart.marker = marker
        
        mChart.setScaleEnabled(false)
        mChart.animate(yAxisDuration: 0.5)
        mChart.drawGridBackgroundEnabled = true
        mChart.gridBackgroundColor = UIColor.init(hex: 0xF0E8DD)
        mChart.backgroundColor = UIColor.init(hex: 0xF0E8DD)
        mChart.xAxis.drawAxisLineEnabled = false
        mChart.xAxis.drawGridLinesEnabled = true
        mChart.xAxis.gridLineDashLengths = [5, 5]
        mChart.xAxis.gridLineDashPhase = 0
        mChart.xAxis.labelPosition = .bottom
        mChart.leftAxis.drawAxisLineEnabled = true
        mChart.leftAxis.drawGridLinesEnabled = true
        mChart.rightAxis.drawAxisLineEnabled = true
        mChart.rightAxis.drawGridLinesEnabled = true
        mChart.legend.enabled = false
        mChart.xAxis.enabled = true
        mChart.leftAxis.enabled = false
        mChart.rightAxis.enabled = false
        mChart.xAxis.drawLabelsEnabled = false
        for set in mChart.data!.dataSets {
            set.drawValuesEnabled = !set.drawValuesEnabled
        }
    }
    
    /// Creating gradient for filling space under the line chart
    private func getGradientFilling() -> CGGradient {
        // Setting fill gradient color
        let coloTop = UIColor(red: 141/255, green: 133/255, blue: 220/255, alpha: 1).cgColor
        let colorBottom = UIColor(red: 230/255, green: 155/255, blue: 210/255, alpha: 1).cgColor
        // Colors of the gradient
        let gradientColors = [coloTop, colorBottom] as CFArray
        // Positioning of the gradient
        let colorLocations: [CGFloat] = [0.7, 0.0]
        // Gradient Object
        return CGGradient.init(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors, locations: colorLocations)!
    }
    
    @objc func getKasamStats(){
        self.kasamBlocks.removeAll()
        self.kasamHistoryRef.child(self.kasamID).observeSingleEvent(of: .value, with:{ (snap) in
            let count = Int(snap.childrenCount)
            self.kasamHistoryRef.child(self.kasamID).observe(.childAdded, with:{ (snapshot) in
                if let value = snapshot.value as? [String: Any] {
                    let metric = value["Total Metric"] as? Int ?? 0
                    let block = kasamFollowingFormat(date: self.convertLongDateToShort(date: snapshot.key), metric: "\(metric) \(self.kasamMetricType)")
                    self.kasamBlocks.append(block)
                }
                
                if self.kasamBlocks.count == count {
                    self.historyTableView.reloadData()
                }
            })
        })
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

extension StatisticsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return kasamBlocks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let block = kasamBlocks[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "KasamStatsCell") as! KasamHistoryTableCell
        cell.setBlock(block: block)
        return cell
    }
}
