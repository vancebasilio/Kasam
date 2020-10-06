//
//  Statistics.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-09-28.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import FirebaseDatabase
import SwipeCellKit
import SwiftEntryKit

struct cellData {
    var opened = Bool()
    var title = String()
    var sectionData = [kasamFollowingFormat]()
    var repeatDuration: Int?
}

class StatisticsViewController: UIViewController, SwipeTableViewCellDelegate {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var historyTableView: UITableView!
    @IBOutlet weak var navView: UIView!
    @IBOutlet weak var kasamNameLabel: UILabel!
    @IBOutlet weak var kasamImageView: UIImageView!
    @IBOutlet weak var imageWhiteBack: UIView!
    @IBOutlet weak var topViewHeight: NSLayoutConstraint!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var dayNoIcon: UILabel!
    @IBOutlet weak var dayNoValue: UILabel!
    @IBOutlet weak var avgMetricIcon: UILabel!
    @IBOutlet weak var avgMetric: UILabel!
    
    var transferArray: CompletedKasamFormat?      //loaded in
    var currentKasam = false
    var kasamFollowingRefHandle: DatabaseHandle!
    var kasamHistoryRefHandle: DatabaseHandle!
    var dayTrackerRefHandle: DatabaseHandle!
    var dayTrackerArray = [Int]()
    var dayTrackerDateArray = [Int:String]()
    var dateToLoadGlobal: Date?
    
    var kasamHistoryArray: [kasamFollowingFormat] = []
    var tableViewData = [cellData]()
    var setTableViewHeight = CGFloat(40)
    
    var metricTotal = 0
    var block: kasamFollowingFormat?
    var progressDayCount = 0
    var noProgressDayCount = 0
    var firstDate: Date?
    var firstDateCheck = true
    var dayNo = 0
    var totalDayCount = 0
    var repeatDurationTotal = 0
    
    var sectionHeight = CGFloat(60)
    var chartHeight = CGFloat(200)
    var rowHeight = CGFloat(40)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        getKasamStats()
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
        tableViewHeight.constant = setTableViewHeight
        contentViewHeight.constant = tableViewHeight.constant + topViewHeight.constant + 20
        //Elongates the entire scrollview, based on the tableview height
        let frame = self.view.safeAreaLayoutGuide.layoutFrame
        if contentViewHeight.constant <= frame.height {
            let diff = frame.height - contentViewHeight.constant - navView.frame.height
            contentViewHeight.constant += (diff + 1)
        }
    }
    
    func setupView(){
        if transferArray != nil {
            kasamImageView.sd_setImage(with: transferArray?.imageURL, placeholderImage: PlaceHolders.kasamLoadingImage)
            kasamNameLabel.text = transferArray?.kasamName
        }
        
        kasamImageView.layer.cornerRadius = kasamImageView.frame.width / 2
        kasamImageView.clipsToBounds = true
        imageWhiteBack.backgroundColor = UIColor.init(hex: 0xFFD062).withAlphaComponent(0.5)
        imageWhiteBack.layer.cornerRadius = imageWhiteBack.frame.width / 2
        self.avgMetricIcon.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight: .semibold), prefixTextColor: UIColor.darkGray, icon: .fontAwesomeSolid(.chartBar), iconColor: UIColor.darkGray, postfixText: "", postfixTextFont: UIFont.systemFont(ofSize: 15, weight: .semibold), postfixTextColor: UIColor.darkGray, iconSize: 20)
        self.dayNoIcon.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight: .semibold), prefixTextColor: UIColor.darkGray, icon: .fontAwesomeSolid(.calendarCheck), iconColor: UIColor.darkGray, postfixText: "", postfixTextFont: UIFont.systemFont(ofSize: 15, weight: .semibold), postfixTextColor: UIColor.darkGray, iconSize: 20)
        backButton.setIcon(prefixText: "", prefixTextFont: UIFont.systemFont(ofSize: 15, weight: .semibold), prefixTextColor: UIColor.darkGray, icon: .fontAwesomeSolid(.chevronLeft), iconColor: UIColor.darkGray, postfixText: " Profile", postfixTextFont: UIFont.systemFont(ofSize: 15, weight: .semibold), postfixTextColor: UIColor.darkGray, backgroundColor: UIColor.clear, forState: .normal, iconSize: 15)
    }
    
    @objc func getKasamStats(){
        var indieMetric = 0.0
        totalDayCount = 0
        repeatDurationTotal = 0
        setTableViewHeight = 0
        self.tableViewData.removeAll()
        let metricType = self.transferArray!.metric
        DBRef.userPersonalHistory.child(transferArray!.kasamID).observeSingleEvent(of: .value) {(snapshot) in
            //SECTIONS
            for snap in snapshot.children.allObjects as! [DataSnapshot]{
                self.kasamHistoryArray.removeAll()
                self.setTableViewHeight += self.sectionHeight
                let startDate = snap.key.stringToDate()
                if let progressDate = snap.value as? [String:Any] {
                    //ROWS
                    var goalCheck = 0
                    var repeatDuration: Int?
                    for individualDate in progressDate {
                        if individualDate.key == "Goal" {
                            repeatDuration = individualDate.value as? Int; goalCheck = 1
                            self.repeatDurationTotal += repeatDuration ?? 0
                        } else {
                            self.dayNo = (Calendar.current.dateComponents([.day], from: startDate, to: individualDate.key.stringToDate()).day ?? 0) + 1
                            self.progressDayCount += 1
                            var blockName = ""
                            if let block = individualDate.value as? [String:Any] {
                                indieMetric = block["Total Metric"] as? Double ?? -1.0
                                if self.transferArray?.program == true {blockName = block["Block Name"] as? String ?? ""}   //load block name for program kasams
                            } else if let block = individualDate.value as? Int {
                                indieMetric = Double(block * 100)           //Kasam is only Checkmark
                            }
                            //Kasam is Reps or Timer
                            var timeAndMetric = (0.0,"")
                            if metricType == "Time" {
                                timeAndMetric = self.convertTimeAndMetric(time: indieMetric, metric: metricType)
                                indieMetric = timeAndMetric.0.rounded(toPlaces: 2)
                            } else if metricType == "Video" {
                                indieMetric = (indieMetric / 60.0).rounded(toPlaces: 2)
                            }
                            self.metricTotal += Int(indieMetric)
                            
                            var metricAndType = ""
                            var middleBold = self.convertLongDateToShort(date: individualDate.key)
                            if self.transferArray?.program == false {
                            //OPTION 1 - REPS
                                if metricType == "Reps" {
                                    metricAndType = "\(indieMetric.removeZerosFromEnd()) \(metricType)"
                            //OPTION 2 - TIME
                                } else if metricType == "Time" {
                                    let tableTime = self.convertTimeAndMetric(time: indieMetric, metric: metricType)
                                    metricAndType = "\(tableTime.0.removeZerosFromEnd()) \(tableTime.1)"
                            //OPTION 3 - PERCENTAGE COMPLETED
                                } else if metricType == "Checkmark" {
                                    metricAndType = "Complete"
                                }
                            //OPTION 4 - PROGRAM KASAM
                            } else {
                                middleBold = blockName
                                metricAndType = self.convertLongDateToShort(date: individualDate.key)
                            }
                            
                            self.kasamHistoryArray.append(kasamFollowingFormat(day: self.dayNo, shortDate: middleBold, fullDate: individualDate.key, metric: indieMetric, metricAndType: metricAndType))
                        }
                        if self.kasamHistoryArray.count + goalCheck == snap.childrenCount {
                            self.kasamHistoryArray = self.kasamHistoryArray.sorted(by: { $0.day < $1.day })
                            self.tableViewData.append(cellData(opened: false, title: startDate.dateToString(), sectionData: self.kasamHistoryArray, repeatDuration: repeatDuration))
                            self.totalDayCount += self.kasamHistoryArray.count
                            self.updateContentTableHeight()
                        }
                    }
                }
                if self.tableViewData.count == snapshot.childrenCount {
                    self.setAvgMetric()
                    //Update Firebase history totals
                    DBRef.userHistoryTotals.child(self.transferArray!.kasamID).setValue(["First": self.tableViewData.first?.sectionData.first?.fullDate as Any,"Last": self.tableViewData.last?.sectionData.last?.fullDate as Any, "Days": self.totalDayCount])
                    self.historyTableView.reloadData()
                }
            }
        }
    }
       
    //STEP 2 - IF ALL DAYS ACCOUNTED FOR, UPDATE TABLE AND CHART
    func setAvgMetric(){
        self.dayNoValue.text = self.totalDayCount.pluralUnit(unit: "Day")
        let metricType = self.transferArray!.metric
        //OPTION 1 - REPS
        if metricType == "Reps" {
            self.avgMetric.text = "\(metricTotal) Total \(metricType)"
        //OPTION 2 - TIME
        } else if metricType == "Time" {
            let avgTimeAndMetric = self.convertTimeAndMetric(time: Double(metricTotal), metric: metricType)
            self.avgMetric.text = "\(Int(avgTimeAndMetric.0)) total \(avgTimeAndMetric.1)"
        //OPTION 3 - PERCENTAGE COMPLETED
        } else if metricType == "Checkmark" && repeatDurationTotal != 0 {
            let avgMetric = ((totalDayCount * 100) / repeatDurationTotal)
            self.avgMetric.text = "\(avgMetric)%\nGoal"
        //OPTION 4 - VIDEO
        } else if metricType == "Video" {
            self.avgMetric.text = "\(metricTotal) Total mins"
        }
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

extension StatisticsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableViewData[section].opened == true {
            return tableViewData[section].sectionData.count + 2
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "KasamStatsCell") as? KasamHistoryTableCell else {return UITableViewCell()}
            cell.setSection(title: tableViewData[indexPath.section].title.shortDateToLongDate(), open: tableViewData[indexPath.section].opened, count: tableViewData[indexPath.section].sectionData.count)
            cell.selectionStyle = .none
            return cell
        } else if indexPath.row == 1 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "KasamStatsChart") as? KasamHistoryTableCell else {return UITableViewCell()}
            cell.setChart(dataSet: tableViewData[indexPath.section].sectionData, repeatDuration: tableViewData[indexPath.section].repeatDuration)
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "KasamStatsCell") as? KasamHistoryTableCell else {return UITableViewCell()}
            cell.delegate = self
            cell.setBlock(block: tableViewData[indexPath.section].sectionData[indexPath.row - 2])
            cell.selectionStyle = .none
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
            case 0: return sectionHeight
            case 1: return chartHeight
            default: return rowHeight
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableViewData.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            //Closing the section
            if tableViewData[indexPath.section].opened == true {
                tableViewData[indexPath.section].opened = false
                setTableViewHeight -= (chartHeight + rowHeight * CGFloat((tableViewData[indexPath.section].sectionData.count)))
                tableView.reloadSections(IndexSet.init(integer: indexPath.section), with: .none)
                updateContentTableHeight()
            } else {
            //Opening the section
                self.tableViewData[indexPath.section].opened = true
                setTableViewHeight += chartHeight + (rowHeight * CGFloat((tableViewData[indexPath.section].sectionData.count)))
                updateContentTableHeight()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
                    tableView.reloadSections(IndexSet.init(integer: indexPath.section), with: .none)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        if orientation == .left {
            return nil
        } else {
            let row = tableViewData[indexPath.section].sectionData[indexPath.row - 2]
            let delete = SwipeAction(style: .destructive, title: nil) { action, indexPath in
                showCenterOptionsPopup(kasamID: nil, title: "Delete Progress?", subtitle: nil, text: "You will be permanently deleting your progress on \(row.shortDate)", type: "deleteHistory", button: "Delete") {(success) in
                    DBRef.userPersonalHistory.child(self.transferArray!.kasamID).child(self.tableViewData[indexPath.section].title).child(row.fullDate).setValue(nil)
                    self.metricTotal -= Int(self.tableViewData[indexPath.section].sectionData[indexPath.row - 2].metric)
                    self.tableViewData[indexPath.section].sectionData.remove(at: indexPath.row - 2)
                    self.historyTableView.deleteRows(at: [IndexPath(row: indexPath.row, section: indexPath.section)], with: .fade)
                    self.setTableViewHeight -= self.rowHeight
                    self.totalDayCount -= 1
                    self.updateContentTableHeight()
                    self.setAvgMetric()
                    if let cell = self.historyTableView.cellForRow(at: IndexPath(item: 0, section: indexPath.section)) as? KasamHistoryTableCell {
                        let count = String(self.tableViewData[indexPath.section].sectionData.count)
                        cell.dayCount.setTitle(count, for: .normal)
                    }
                    SwiftEntryKit.dismiss()
                }
            }
            configure(action: delete, with: .trash)

            let edit = SwipeAction(style: .default, title: nil) { action, indexPath in
                self.dateToLoadGlobal = row.fullDate.stringToDate()
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
            kasamActivityHolder.kasamID = transferArray!.kasamID
            kasamActivityHolder.dateToLoad = dateToLoadGlobal
        }
    }
}
