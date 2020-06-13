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
import SwipeCellKit
import SwiftEntryKit

class StatisticsViewController: UIViewController, SwipeTableViewCellDelegate {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var mChart: LineChartView!
    @IBOutlet weak var historyTableView: UITableView!
    @IBOutlet weak var historyView: UIView!
    @IBOutlet weak var navView: UIView!
    @IBOutlet weak var kasamNameLabel: UILabel!
    @IBOutlet weak var kasamImageView: UIImageView!
    @IBOutlet weak var imageWhiteBack: UIView!
    @IBOutlet weak var topViewHeight: NSLayoutConstraint!
    @IBOutlet weak var bottomViewHeight: NSLayoutConstraint!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var dayNoIcon: UILabel!
    @IBOutlet weak var dayNoValue: UILabel!
    @IBOutlet weak var avgMetricIcon: UILabel!
    @IBOutlet weak var avgMetric: UILabel!
    
    var dataEntries: [ChartDataEntry] = []
    var kasamStatsTransfer: UserStatsFormat?                        //transfered in value if viewing current kasam history
    var userHistoryTransfer: CompletedKasamFormat?                  //transfered in value if viewing full history
    var metricArray: [Int:Int] = [:]
    var kasamBlocks: [kasamFollowingFormat] = []
    var kasamFollowingRefHandle: DatabaseHandle!
    var kasamHistoryRefHandle: DatabaseHandle!
    var dayTrackerRefHandle: DatabaseHandle!
    var dayTrackerArray = [Int]()
    var dayTrackerDateArray = [Int:String]()
    var dateToLoadGlobal: Date?
    var kasamID = ""
    
    var metricTotal = 0
    var block: kasamFollowingFormat?
    var progressDayCount = 0
    var noProgressDayCount = 0
    var firstDate: Date?
    var firstDateCheck = true
    var dayNo = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if kasamStatsTransfer != nil {kasamID = kasamStatsTransfer!.kasamID}
        else {kasamID = userHistoryTransfer!.kasamID}
        setupView()
        getKasamStats()
        setupChart()
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        tableViewHeight.constant = historyTableView.contentSize.height
        bottomViewHeight.constant = tableViewHeight.constant + 50 + mChart.frame.height + 4.0
        contentViewHeight.constant = bottomViewHeight.constant + topViewHeight.constant
        //elongates the entire scrollview, based on the tableview height
        let frame = self.view.safeAreaLayoutGuide.layoutFrame
        if contentViewHeight.constant <= frame.height {
            let diff = frame.height - contentViewHeight.constant - navView.frame.height
            contentViewHeight.constant += (diff + 1)
        }
    }
    
    func setupView(){
        if kasamStatsTransfer != nil {
            kasamImageView.sd_setImage(with: kasamStatsTransfer?.imageURL, placeholderImage: PlaceHolders.kasamLoadingImage)
            kasamNameLabel.text = SavedData.kasamDict[kasamID]?.kasamName
        } else if userHistoryTransfer != nil {
            kasamImageView.sd_setImage(with: userHistoryTransfer?.imageURL, placeholderImage: PlaceHolders.kasamLoadingImage)
            kasamNameLabel.text = userHistoryTransfer?.kasamName
        }
        
        kasamImageView.layer.cornerRadius = kasamImageView.frame.width / 2
        kasamImageView.clipsToBounds = true
        imageWhiteBack.backgroundColor = UIColor.init(hex: 0xFFD062).withAlphaComponent(0.5)
        imageWhiteBack.layer.cornerRadius = imageWhiteBack.frame.width / 2
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
        if kasamStatsTransfer != nil && kasamStatsTransfer!.endDate! > Date() {
            //OPTION 1 - Get Current Kasam Stats only
            let repeatDuration = SavedData.kasamDict[kasamStatsTransfer!.kasamID]?.repeatDuration ?? 0
            self.dayNoValue.text = "Day \(SavedData.kasamDict[kasamStatsTransfer!.kasamID]?.currentDay ?? 0)"
            for day in 1...repeatDuration {
                let dayDate = (Calendar.current.date(byAdding: .day, value: day - 1, to: kasamStatsTransfer!.joinedDate)!).dateToString()
                self.kasamHistoryRefHandle = DBRef.userHistory.child(kasamStatsTransfer!.kasamID).child(dayDate).observe(.value, with:{(snapshot) in
                    self.getChartsAndTableStats(metricType: SavedData.kasamDict[self.kasamStatsTransfer!.kasamID]!.metricType, day: day, dayDate: dayDate, kasamDay: repeatDuration, snapshot: snapshot)
                })
            }
        } else if userHistoryTransfer != nil {
            //OPTION 2 - Get all Kasam Stats
            self.dayNoValue.text = userHistoryTransfer!.daysCompleted.pluralUnit(unit: "Day")
            let enumerator = userHistoryTransfer!.userHistorySnap!.children
            while let history = enumerator.nextObject() as? DataSnapshot {
                getChartsAndTableStats(metricType: SavedData.kasamDict[userHistoryTransfer!.kasamID]!.metricType, day: nil, dayDate: nil, kasamDay: userHistoryTransfer!.daysCompleted, snapshot: history)
            }
        }
        
    }
        
    func getChartsAndTableStats(metricType: String, day: Int?, dayDate: String?, kasamDay: Int, snapshot: DataSnapshot){
        var indieMetric = 0.0
        var textField = ""
        if day != nil {dayNo = day!}
        else {
            if firstDateCheck == true {firstDate = snapshot.key.stringToDate(); firstDateCheck = false}
            dayNo = (Calendar.current.dateComponents([.day], from: firstDate!, to: snapshot.key.stringToDate()).day ?? 0) + 1
        }
        if snapshot.exists() {
            progressDayCount += 1
            if let value = snapshot.value as? [String: Any] {
                //Kasam is Reps or Timer
                indieMetric = value["Total Metric"] as? Double ?? 0.0
                let text = value["Text Breakdown"] as? [Any]
                textField = text?[1] as! String
                var timeAndMetric = (0.0,"")
                if metricType == "Time" {
                    timeAndMetric = self.convertTimeAndMetric(time: indieMetric, metric: metricType)
                    indieMetric = timeAndMetric.0.rounded(toPlaces: 2)
                }
            } else if let value = snapshot.value as? Int{
                //Kasam is only Checkmark
                indieMetric = Double(value * 100)
            }
            self.metricArray[dayNo] = Int(indieMetric)
            metricTotal += Int(indieMetric)
            
            //OPTION 1 - REPS
            var metric = ""
            if metricType == "Reps" {
                metric = "\(indieMetric.removeZerosFromEnd()) \(metricType)"
            //OPTION 2 - TIME
            } else if metricType == "Time" {
                let tableTime = self.convertTimeAndMetric(time: indieMetric, metric: metricType)
                metric = "\(tableTime.0.removeZerosFromEnd()) \(tableTime.1)"
            //OPTION 3 - PERCENTAGE COMPLETED
            } else if metricType == "Checkmark" {
                metric = "Complete"
            }
            block = kasamFollowingFormat(day: dayNo, shortDate: self.convertLongDateToShort(date: snapshot.key), fullDate: snapshot.key, metric: metric, text: textField)
            self.kasamBlocks.append(block!)
            self.kasamBlocks = self.kasamBlocks.sorted(by: { $0.day < $1.day })
        } else {
            //Adds the missing zero days to the chart where the user hasn't logged any progress
            noProgressDayCount += 1
        }
        if progressDayCount + noProgressDayCount == kasamDay {
            //OPTION 1 - REPS
            if metricType == "Reps" {
                self.avgMetric.text = "\(metricTotal) Total \(metricType)"
            //OPTION 2 - TIME
            } else if metricType == "Time" {
//                let avgMetric = (metricTotal) / progressDayCount
                let avgTimeAndMetric = self.convertTimeAndMetric(time: Double(metricTotal), metric: metricType)
                self.avgMetric.text = "\(Int(avgTimeAndMetric.0)) total \(avgTimeAndMetric.1)"
            //OPTION 3 - PERCENTAGE COMPLETED
            } else if metricType == "Checkmark" {
                var avgMetric = 0
                avgMetric = (metricTotal) / (dayNo)
                self.avgMetric.text = "\(avgMetric)% Avg."
            }
            
            if self.metricArray[kasamDay] == nil {self.metricArray[kasamDay] = 0}
            self.historyTableView.reloadData()
            self.setChart(values: self.metricArray)
            //For current kasam stats
            if dayDate != nil {DBRef.userHistory.child(self.kasamStatsTransfer!.kasamID).child(dayDate!).removeAllObservers()}
            self.metricArray.removeAll()
        }
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
        cell.delegate = self
        cell.setBlock(block: block)
        return cell
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        if orientation == .left {
            return nil
        } else {
            let delete = SwipeAction(style: .destructive, title: nil) { action, indexPath in
                let popupImage = UIImage.init(icon: .fontAwesomeSolid(.eraser), size: CGSize(width: 30, height: 30), textColor: .white)
                showPopupConfirmation(title: "Are you sure you want to delete your progress on\n\(self.kasamBlocks[indexPath.row].shortDate)?", description: "", image: popupImage, buttonText: "Delete") {(success) in
                    DBRef.userHistory.child(self.kasamID).child(self.kasamBlocks[indexPath.row].fullDate).setValue(nil)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "KasamStatsUpdate"), object: self)
                    self.kasamBlocks.remove(at: indexPath.row)
                    self.historyTableView.reloadData()
                    self.updateViewConstraints()
                    SwiftEntryKit.dismiss()
                }
            }
            configure(action: delete, with: .trash)
            
            let edit = SwipeAction(style: .default, title: nil) { action, indexPath in
                self.dateToLoadGlobal = self.kasamBlocks[indexPath.row].fullDate.stringToDate()
                self.performSegue(withIdentifier: "goToKasamActivityViewer", sender: indexPath)
            }
            configure(action: edit, with: .edit)
            return [delete, edit]
        }
    }
    
    func configure(action: SwipeAction, with descriptor: ActionDescriptor) {
        action.title = descriptor.title(forDisplayMode: .imageOnly)
        action.image = descriptor.image(forStyle: .backgroundColor, displayMode: .imageOnly)
        action.backgroundColor = descriptor.color(forStyle: .backgroundColor)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToKasamActivityViewer" {
            let kasamActivityHolder = segue.destination as! KasamActivityViewer
            kasamActivityHolder.kasamID = kasamID
            kasamActivityHolder.dateToLoad = dateToLoadGlobal
        }
    }
}
