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
    var userHistoryTransfer: CompletedKasamFormat?                  //transfered in value if viewing full history
    var currentKasam = false
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
        kasamID = userHistoryTransfer!.kasamID
        setupView()
        getKasamStats()
        setupChart()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //Hides the nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //Shows the nav bar
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func updateContentTableHeight() {
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
        if userHistoryTransfer != nil {
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
        let enumerator = userHistoryTransfer!.userHistorySnap!.children
        var historyArray = [DataSnapshot]()
        if userHistoryTransfer != nil {
            if currentKasam == true {
                //OPTION 1 - Get Current Kasam Stats only
                self.dayNoValue.text = "Day \(SavedData.kasamDict[kasamID]?.currentDay ?? 0)"
                while let history = enumerator.nextObject() as? DataSnapshot {
                    if history.key.stringToDate() >= SavedData.kasamDict[kasamID]!.joinedDate {
                        historyArray.append(history)
                    }
                }
                getChartsAndTableStats(metricType: SavedData.kasamDict[kasamID]!.metricType, kasamDay: SavedData.kasamDict[kasamID]!.streakInfo.daysWithAnyProgress, snapshot: historyArray)
            } else {
                //OPTION 2 - Get all Kasam Stats
                self.dayNoValue.text = userHistoryTransfer!.daysCompleted.pluralUnit(unit: "Day")
                while let history = enumerator.nextObject() as? DataSnapshot {
                    historyArray.append(history)
                }
                getChartsAndTableStats(metricType: SavedData.kasamDict[userHistoryTransfer!.kasamID]!.metricType, kasamDay: userHistoryTransfer!.daysCompleted, snapshot: historyArray)
            }
        }
    }
        
    func getChartsAndTableStats(metricType: String, kasamDay: Int, snapshot: [DataSnapshot]){
        for snap in snapshot {
            var indieMetric = 0.0
            let textField = ""
            
        //STEP 1 - GET THE INFO FOR THE DAY
            if snap.exists() {
                progressDayCount += 1
                var blockName = ""
                if let value = snap.value as? [String: Any] {
                    //Kasam is Reps or Timer
                    indieMetric = value["Total Metric"] as? Double ?? 0.0
//                    let text = value["Text Breakdown"] as? [Any]
                    var timeAndMetric = (0.0,"")
                    if metricType == "Time" {
                        timeAndMetric = self.convertTimeAndMetric(time: indieMetric, metric: metricType)
                        indieMetric = timeAndMetric.0.rounded(toPlaces: 2)
                    }
                    if SavedData.kasamDict[kasamID]?.timeline != nil {
                        blockName = value["Block Name"] as? String ?? ""
                    }
                } else if let value = snap.value as? Int{
                    //Kasam is only Checkmark
                    indieMetric = Double(value * 100)
                }
                self.metricArray[dayNo] = Int(indieMetric)
                metricTotal += Int(indieMetric)
                
                var metric = ""
                var shortDate = ""
                if SavedData.kasamDict[kasamID]?.timeline == nil {
                    if currentKasam == true {
                        firstDate = SavedData.kasamDict[kasamID]?.joinedDate
                        dayNo = (Calendar.current.dateComponents([.day], from: firstDate!, to: snap.key.stringToDate()).day ?? 0) + 1
                    } else {
                        if firstDateCheck == true {firstDate = snap.key.stringToDate(); firstDateCheck = false}
                        dayNo = (Calendar.current.dateComponents([.day], from: firstDate!, to: snap.key.stringToDate()).day ?? 0) + 1
                    }
                //OPTION 1 - REPS
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
                    shortDate = self.convertLongDateToShort(date: snap.key)
                //OPTION 4 - TIMELINE KASAM
                } else {
                    self.dayNo += 1
                    shortDate = blockName
                    metric = self.convertLongDateToShort(date: snap.key)
                }
                self.block = kasamFollowingFormat(day: self.dayNo, shortDate: shortDate, fullDate: snap.key, metric: metric, text: textField)
                self.kasamBlocks.append(self.block!)
                self.kasamBlocks = self.kasamBlocks.sorted(by: { $0.day < $1.day })
            }
            
        //STEP 2 - IF ALL DAYS ACCOUNTED FOR, UPDATE TABLE AND CHART
            if progressDayCount >= kasamDay {
            //OPTION 1 - REPS
                if metricType == "Reps" {
                    self.avgMetric.text = "\(metricTotal) Total \(metricType)"
            //OPTION 2 - TIME
                } else if metricType == "Time" {
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
                updateContentTableHeight()
                self.setChart(values: self.metricArray)
                self.metricArray.removeAll()
            }
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "KasamStatsCell") as! KasamHistoryTableCell
        cell.delegate = self
        let block = kasamBlocks[indexPath.row]
        cell.setBlock(block: block)
        return cell
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        if orientation == .left {
            return nil
        } else {
            let delete = SwipeAction(style: .destructive, title: nil) { action, indexPath in
                let popupImage = UIImage.init(icon: .fontAwesomeSolid(.eraser), size: CGSize(width: 30, height: 30), textColor: .white)
                showPopupConfirmation(title: "Sure you want to delete your progress on \(self.kasamBlocks[indexPath.row].shortDate)?", description: "", image: popupImage, buttonText: "Delete") {(success) in
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
            return [delete]
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
