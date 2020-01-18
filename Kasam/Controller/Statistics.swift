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
    @IBOutlet weak var dayNoIcon: UILabel!
    @IBOutlet weak var dayNoValue: UILabel!
    @IBOutlet weak var avgMetricIcon: UILabel!
    @IBOutlet weak var avgMetric: UILabel!
    
    var dataEntries: [ChartDataEntry] = []
    var kasamID = ""                    //transfered in value
    var kasamName = ""                  //transfered in value
    var kasamMetricType = ""            //transfered in value
    var kasamImage: URL!                //transfered in value
    var metricArray: [Int:Int] = [:]
    var joinedDate: Date?
    var kasamBlocks: [kasamFollowingFormat] = []
    var kasamFollowingRefHandle: DatabaseHandle!
    var kasamHistoryRef: DatabaseReference! = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("History")
    var kasamHistoryRefHandle: DatabaseHandle!
    let dayTrackerRef = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("History")
    var dayTrackerRefHandle: DatabaseHandle!
    var dayTrackerArray = [Int]()
    var dayTrackerDateArray = [Int:String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getKasamStats()
        setupView()
        setupChart()
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
        kasamImageView.sd_setImage(with: kasamImage, placeholderImage: PlaceHolders.kasamLoadingImage)
        kasamImageView.layer.cornerRadius = kasamImageView.frame.width / 2
        kasamImageView.clipsToBounds = true
        imageWhiteBack.backgroundColor = UIColor.init(hex: 0xFFD062).withAlphaComponent(0.5)
        imageWhiteBack.layer.cornerRadius = imageWhiteBack.frame.width / 2
        kasamNameLabel.text = kasamName
        self.avgMetricIcon.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight: .semibold), prefixTextColor: UIColor.darkGray, icon: .fontAwesomeSolid(.chartBar), iconColor: UIColor.darkGray, postfixText: "", postfixTextFont: UIFont.systemFont(ofSize: 15, weight: .semibold), postfixTextColor: UIColor.darkGray, iconSize: 20)
        self.dayNoIcon.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight: .semibold), prefixTextColor: UIColor.darkGray, icon: .fontAwesomeSolid(.calendarCheck), iconColor: UIColor.darkGray, postfixText: "", postfixTextFont: UIFont.systemFont(ofSize: 15, weight: .semibold), postfixTextColor: UIColor.darkGray, iconSize: 20)
        backButton.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight: .semibold), prefixTextColor: UIColor.darkGray, icon: .fontAwesomeSolid(.chevronLeft), iconColor: UIColor.darkGray, postfixText: " Profile", postfixTextFont: UIFont.systemFont(ofSize: 15, weight: .semibold), postfixTextColor: UIColor.darkGray, backgroundColor: UIColor.clear, forState: .normal, iconSize: 15)
        let mainStatsUpdate = NSNotification.Name("MainStatsUpdate")
        NotificationCenter.default.addObserver(self, selector: #selector(StatisticsViewController.getKasamStats), name: mainStatsUpdate, object: nil)
    }
    
    //Creating gradient for filling space under the line chart
    private func getGradientFilling() -> CGGradient {
        let coloTop = UIColor.init(hex: 0xFFD062).cgColor
        let colorBottom = UIColor.init(hex: 0xFFD062).cgColor
        let gradientColors = [coloTop, colorBottom] as CFArray
        let colorLocations: [CGFloat] = [0.7, 0.0]
        return CGGradient.init(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors, locations: colorLocations)!
    }
    
    @objc func getKasamStats(){
        self.kasamBlocks.removeAll()
        joinedDate = SavedData.kasamDict[kasamID]?.joinedDate
        let kasamDay = ((Calendar.current.dateComponents([.day], from: joinedDate!, to: Date()).day!) + 1)
        self.dayNoValue.text = "Day \(kasamDay)"
        //if the kasam is active
        if kasamDay > 30 && SavedData.dayTrackerDict[kasamID] == nil {
            //for completed kasams without saved day trackers
            getCompletedKasamDayTracker()
        } else {
            //for in progress kasams and completed kasams with saved day trackers
            getChartAndTableStats(kasamDay: kasamDay)
        }
    }
    
    func getChartAndTableStats(kasamDay: Int){
        let dateArray = SavedData.dayTrackerDict[kasamID]
        var metricTotal = 0
        var metricType = ""
        //kasamDay is the current day of the Kasam that the user is on
        for day in 1...kasamDay {
            if dateArray?[day] != nil {
                self.kasamHistoryRefHandle = self.kasamHistoryRef.child(kasamID).child((dateArray![day]!)).observe(.value, with:{(snapshot) in
                if let value = snapshot.value as? [String: Any] {
                    let metric = Int(value["Total Metric"] as? Double ?? 0.0)
                    metricType = self.kasamMetricType
                    var indieMetric = Double(metric)
                    var indieMetricType = metricType
                    let text = value["Text Breakdown"] as? [Any]
                    let textField = text?[1]
                    let dayOrder = Int(value["Day Order"] as? String ?? "0")
                    self.metricArray[dayOrder!] = metric
                    var timeAndMetric = (0.0,"")
                    if self.kasamMetricType == "Time" {
                        timeAndMetric = self.convertTimeAndMetric(time: Double(metric), metric: metricType)
                        indieMetric = timeAndMetric.0.rounded(toPlaces: 2)
                        indieMetricType = timeAndMetric.1
                    } else if self.kasamMetricType == "Checkmark" {
                        indieMetricType = "%"
                    }
                    metricTotal += metric
                    let block = kasamFollowingFormat(day: dayOrder!, date: self.convertLongDateToShort(date: snapshot.key), metric: "\(indieMetric.removeZerosFromEnd()) \(indieMetricType)", text: textField as? String ?? "")
                    self.kasamBlocks.append(block)
                }
                if self.kasamBlocks.count == dateArray?.count {
                    self.kasamBlocks = self.kasamBlocks.sorted(by: { $0.day < $1.day })
                    if metricType == "Reps" {
                         self.avgMetric.text = "\(metricTotal) Total \(metricType)"
                    } else if metricType == "Time" {
                        let avgMetric = (metricTotal) / (dateArray?.count ?? 1)
                        let avgTimeAndMetric = self.convertTimeAndMetric(time: Double(avgMetric), metric: metricType)
                        self.avgMetric.text = "\(Int(avgTimeAndMetric.0)) Avg. \(avgTimeAndMetric.1)"
                    } else if metricType == "Checkmark" {
                        let avgMetric = (metricTotal) / (kasamDay)
                        self.avgMetric.text = "Avg. \(avgMetric) %"
                    }
                    self.historyTableView.reloadData()
                    self.setChart(values: self.metricArray)
                    self.kasamHistoryRef.child(self.kasamID).child((dateArray?[day])!).removeAllObservers()
                    self.metricArray.removeAll()
                }
            })
            //adds the missing zero days to the chart where the user hasn't logged any progress
            } else if dateArray?[day] == nil && day <= 30 {
                self.metricArray[day] = 0
            }
        }
    }
    
    func getCompletedKasamDayTracker() {
        let dayTrackerKasamRef = self.dayTrackerRef.child(kasamID)
        var dayCount = 0
        //Checks if there's kasam history
        self.dayTrackerRef.child(kasamID).observeSingleEvent(of: .value, with: {(snap) in
            dayCount = Int(snap.childrenCount)
            //Gets the DayTracker info - only goes into this loop if the user has kasam history
            self.dayTrackerRefHandle = dayTrackerKasamRef.observe(.childAdded, with: {(snap) in
                let kasamDate = self.stringToDate(date: snap.key)
                if kasamDate >= self.joinedDate! {
                    let order = (Calendar.current.dateComponents([.day], from: self.joinedDate!, to: kasamDate)).day! + 1
                    self.dayTrackerDateArray[order] = snap.key      //to save the kasam date and order
                    self.dayTrackerArray.append(order)              //gets the order to display what day it is for each kasam
                } else {
                    dayCount -= 1
                }
                if self.dayTrackerArray.count == dayCount && dayCount > 0 {
                    SavedData.dayTrackerDict[self.kasamID] = self.dayTrackerDateArray
                    dayTrackerKasamRef.removeAllObservers()
                    self.getChartAndTableStats(kasamDay: 30)
                }
            })
        })
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    //CHART--------------------------------------------------------------------------------------------------------
    
    func setChart(values: [Int:Int]) {
        mChart.noDataText = "No data available!"
        let dayUpperBound = ((values.keys.sorted().last.map({ ($0, values[$0]!) }))?.0) ?? 0
        for i in 1...dayUpperBound {
            let dataEntry = ChartDataEntry(x: Double(i), y: Double(values[i] ?? 0))
            dataEntries.append(dataEntry)
        }
        let line1 = LineChartDataSet(entries: dataEntries, label: "Units Consumed")
        line1.colors = [NSUIColor.colorFour]
        line1.mode = .horizontalBezier
        line1.cubicIntensity = 0.2
        
        let gradient = getGradientFilling()
        line1.fill = Fill.fillWithLinearGradient(gradient, angle: 90.0)
        line1.drawFilledEnabled = true
        line1.lineWidth = 2
        line1.drawCirclesEnabled = true
        line1.circleColors = [UIColor.colorFour]
        line1.circleRadius = 4
        line1.drawHorizontalHighlightIndicatorEnabled = false   //highlight lines
        line1.drawVerticalHighlightIndicatorEnabled = false     //highlight lines
        
        let data = LineChartData()
        data.addDataSet(line1)
        mChart.data = data
        
        for set in mChart.data!.dataSets {set.drawValuesEnabled = !set.drawValuesEnabled}      //removes the titles above each datapoint
        mChart.leftAxis.axisMinimum = 1.0
        mChart.xAxis.axisMinimum = 1.0
        dataEntries.removeAll()
    }
    
    func setupChart(){
        let marker = BalloonMarker(color: UIColor.colorFour, font: .systemFont(ofSize: 12), textColor: .white, insets: UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8))
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
        
        //Labels
        mChart.xAxis.drawLabelsEnabled = true //horizontal axis labels
        mChart.xAxis.labelPosition = .bottom
        mChart.xAxis.labelTextColor = UIColor.init(hex: 0x7F7F7F)
        mChart.xAxis.labelFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
        mChart.leftAxis.labelTextColor = UIColor.init(hex: 0x7F7F7F)
        mChart.leftAxis.labelFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
    
        mChart.xAxis.drawAxisLineEnabled = true         //horizontal axis
        mChart.xAxis.drawGridLinesEnabled = false       //vertical lines
        mChart.xAxis.gridLineDashLengths = [5, 5]
        mChart.xAxis.gridLineDashPhase = 0
        mChart.xAxis.granularityEnabled = true
        
        mChart.leftAxis.enabled = true
        mChart.leftAxis.drawAxisLineEnabled = true      //y axis
        mChart.leftAxis.drawGridLinesEnabled = false    //horizontal lines
        
        mChart.rightAxis.enabled = false
        mChart.rightAxis.drawAxisLineEnabled = true
        mChart.rightAxis.drawGridLinesEnabled = false
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
