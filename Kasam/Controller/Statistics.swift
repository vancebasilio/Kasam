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
    @IBOutlet weak var navView: UIView!
    @IBOutlet weak var kasamNameLabel: UILabel!
    @IBOutlet weak var kasamImageView: UIImageView!
    @IBOutlet weak var imageWhiteBack: UIView!
    @IBOutlet weak var bottomViewHeight: NSLayoutConstraint!
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    
    var dataEntries: [ChartDataEntry] = []
    var kasamID = ""
    var kasamName = ""
    var kasamMetricType = ""
    var kasamImage: URL!
    var kasamBlocks: [kasamFollowingFormat] = []
    var kasamFollowingRefHandle: DatabaseHandle!
    var kasamHistoryRef: DatabaseReference! = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("History")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getKasamStats()
        setupView()
        setChart(values: [24.0,43.0,56.0,23.0,56.0,68.0,48.0,120.0,41.0,24.0,43.0,56.0,23.0,56.0,68.0,48.0,120.0,41.0,24.0,43.0,56.0,23.0,56.0,68.0,48.0,120.0,41.0,40.0,40.0,30.0,20.0])
       
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        tableViewHeight.constant = historyTableView.contentSize.height
    }
    
    override func viewDidAppear(_ animated: Bool) {
        updateViewConstraints()
        bottomViewHeight.constant = tableViewHeight.constant + 50 + mChart.frame.height + 4.0
        contentViewHeight.constant = bottomViewHeight.constant + 205
    }
    
    func setupView(){
        kasamImageView.sd_setImage(with: kasamImage, placeholderImage: UIImage(named: "placeholder.png"))
        kasamImageView.layer.cornerRadius = kasamImageView.frame.width / 2
        kasamImageView.clipsToBounds = true
        imageWhiteBack.layer.cornerRadius = kasamImageView.frame.width / 2
        imageWhiteBack.clipsToBounds = true
        kasamNameLabel.text = kasamName
        backButton.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight: .semibold), prefixTextColor: UIColor.darkGray, icon: .fontAwesomeSolid(.chevronLeft), iconColor: UIColor.darkGray, postfixText: " Profile", postfixTextFont: UIFont.systemFont(ofSize: 15, weight: .semibold), postfixTextColor: UIColor.darkGray, backgroundColor: UIColor.clear, forState: .normal, iconSize: 15)
    }
    
    func setChart(values: [Double]) {
        mChart.noDataText = "No data available!"
        for i in 0..<values.count {
            let dataEntry = ChartDataEntry(x: Double(i), y: values[i])
            dataEntries.append(dataEntry)
        }
        let line1 = LineChartDataSet(entries: dataEntries, label: "Units Consumed")
        line1.colors = [NSUIColor.colorFour]
        line1.mode = .cubicBezier
        line1.cubicIntensity = 0.2
        
        let gradient = getGradientFilling()
        line1.fill = Fill.fillWithLinearGradient(gradient, angle: 90.0)
        line1.drawFilledEnabled = true
        line1.lineWidth = 3
        line1.drawCirclesEnabled = false
        line1.drawHorizontalHighlightIndicatorEnabled = false  //highlight lines
        line1.drawVerticalHighlightIndicatorEnabled = false //highlight lines
        
        let data = LineChartData()
        data.addDataSet(line1)
        mChart.data = data
        
        let marker = BalloonMarker(color: UIColor(white: 180/255, alpha: 1), font: .systemFont(ofSize: 12), textColor: .white, insets: UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8))
        marker.chartView = mChart
        marker.minimumSize = CGSize(width: 40, height: 40)
        mChart.marker = marker
        
        let backColor = UIColor.white
        mChart.gridBackgroundColor = backColor
        mChart.backgroundColor = backColor
        
        mChart.setScaleEnabled(false)
        mChart.animate(yAxisDuration: 0.5)
        mChart.drawGridBackgroundEnabled = true
        mChart.legend.enabled = false
        mChart.xAxis.enabled = true
        
        mChart.xAxis.drawLabelsEnabled = true //horizontal axis labels
        mChart.xAxis.labelPosition = .bottom
        mChart.xAxis.labelTextColor = UIColor.init(hex: 0x7F7F7F)
        mChart.leftAxis.labelTextColor = UIColor.init(hex: 0x7F7F7F)
        mChart.xAxis.labelFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
        mChart.leftAxis.labelFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
        
        mChart.xAxis.drawAxisLineEnabled = true //horizontal axis
        mChart.xAxis.drawGridLinesEnabled = false //vertical lines
        mChart.xAxis.gridLineDashLengths = [5, 5]
        mChart.xAxis.gridLineDashPhase = 0
        mChart.leftAxis.enabled = true
        mChart.leftAxis.drawAxisLineEnabled = true //y axis
        mChart.leftAxis.drawGridLinesEnabled = false //horizontal lines
        
        mChart.rightAxis.enabled = false
        mChart.rightAxis.drawAxisLineEnabled = false
        mChart.rightAxis.drawGridLinesEnabled = false
        
        for set in mChart.data!.dataSets {
            set.drawValuesEnabled = !set.drawValuesEnabled
        }
    }
    
    /// Creating gradient for filling space under the line chart
    private func getGradientFilling() -> CGGradient {
        // Setting fill gradient color
        let coloTop = UIColor.init(hex: 0xFFD062).cgColor
        let colorBottom = UIColor.init(hex: 0xFFD062).cgColor
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
            var day = 1
            self.kasamHistoryRef.child(self.kasamID).observe(.childAdded, with:{ (snapshot) in
                if let value = snapshot.value as? [String: Any] {
                    let metric = value["Total Metric"] as? Int ?? 0
                    let block = kasamFollowingFormat(day: day, date: self.convertLongDateToShort(date: snapshot.key), metric: "\(metric) \(self.kasamMetricType)")
                    day += 1
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
