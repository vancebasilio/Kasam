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
}

class StatisticsViewController: UIViewController, SwipeTableViewCellDelegate {
    
    @IBOutlet weak var backButton: UIButton!
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
    
    var transferArray: CompletedKasamFormat?      //loaded in
    var currentKasam = false
    var metricArray: [Int:Double] = [:]
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
        bottomViewHeight.constant = tableViewHeight.constant + 54
        contentViewHeight.constant = bottomViewHeight.constant + topViewHeight.constant
        //elongates the entire scrollview, based on the tableview height
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
        var indieMetric = 0.0
        let metricType = self.transferArray!.metric
        self.kasamHistoryArray.removeAll()
        self.dayNoValue.text = self.transferArray?.daysCompleted.pluralUnit(unit: "Day")
        DBRef.userPersonalHistory.child(transferArray!.kasamID).observeSingleEvent(of: .value) {(snapshot) in
        //SECTIONS
            for snap in snapshot.children.allObjects as! [DataSnapshot]{
                let startDate = snap.key.stringToDate()
                if let joinDate = snap.value as? [String:[String:Any]] {
                    for individualDate in joinDate {
                        //ROWS
                        indieMetric = individualDate.value["Total Metric"] as! Double
                        self.dayNo = (Calendar.current.dateComponents([.day], from: startDate, to: individualDate.key.stringToDate()).day ?? 0) + 1
                        self.progressDayCount += 1
                        var blockName = ""
                        //Kasam is Reps or Timer
                            var timeAndMetric = (0.0,"")
                            if metricType == "Time" {
                                timeAndMetric = self.convertTimeAndMetric(time: indieMetric, metric: metricType)
                                indieMetric = timeAndMetric.0.rounded(toPlaces: 2)
                            } else if metricType == "Video" {
                                indieMetric = (indieMetric / 60.0).rounded(toPlaces: 2)
                            }
                            if SavedData.kasamDict[self.transferArray!.kasamID]?.programDuration != nil {
//                                blockName = value["Block Name"] as? String ?? ""
                            }
//                        } else if let value = snap.value as? Int{
//                        //Kasam is only Checkmark
//                            indieMetric = Double(value * 100)
//                        }
                        self.metricArray[self.dayNo] = indieMetric
                        self.metricTotal += Int(indieMetric)
                        
                        var metricAndType = ""
                        var shortDate = self.convertLongDateToShort(date: individualDate.key)
                        if SavedData.kasamDict[self.transferArray!.kasamID]?.programDuration == nil {
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
                            self.dayNo += 1
                            shortDate = blockName
                            metricAndType = self.convertLongDateToShort(date: snap.key)
                        }
                        
                        self.kasamHistoryArray.append(kasamFollowingFormat(day: self.dayNo, shortDate: shortDate, fullDate: individualDate.key, metric: metricAndType))
                        if self.kasamHistoryArray.count == snap.childrenCount {
                            self.kasamHistoryArray = self.kasamHistoryArray.sorted(by: { $0.day < $1.day })
                            self.tableViewData.append(cellData(opened: false, title: startDate.dateToString(), sectionData: self.kasamHistoryArray))
                            self.updateContentTableHeight()
                            self.setAvgMetric(metricType: metricType, kasamDay: self.dayNo)
                        }
                    }
                }
                if self.tableViewData.count == snapshot.childrenCount {
                    self.historyTableView.reloadData()
                }
            }
        }
    }
        
    func setAvgMetric(metricType: String, kasamDay: Int){
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
            //OPTION 4 - VIDEO
                } else if metricType == "Video" {
                    self.avgMetric.text = "\(metricTotal) Total mins"
                }
                if self.metricArray[kasamDay] == nil {self.metricArray[kasamDay] = 0}
                self.metricArray.removeAll()
        }
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

extension StatisticsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableViewData[section].opened == true {
            return tableViewData[section].sectionData.count + 1
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "KasamStatsCell") as? KasamHistoryTableCell else {return UITableViewCell()}
            cell.setSection(title: tableViewData[indexPath.section].title.shortDateToLongDate(), open: tableViewData[indexPath.section].opened)
            cell.selectionStyle = .none
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "KasamStatsCell") as? KasamHistoryTableCell else {return UITableViewCell()}
            cell.delegate = self
            cell.setBlock(block: tableViewData[indexPath.section].sectionData[indexPath.row - 1])
            cell.selectionStyle = .none
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableViewData.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            //Closing the section
            if tableViewData[indexPath.section].opened == true {
                tableViewData[indexPath.section].opened = false
                tableView.reloadSections(IndexSet.init(integer: indexPath.section), with: .none)
                setTableViewHeight = 40
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                     self.updateContentTableHeight()
                 }
            } else {
            //Opening the section
                setTableViewHeight = CGFloat(40 * (tableViewData[indexPath.section].sectionData.count))
                updateContentTableHeight()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
                    self.tableViewData[indexPath.section].opened = true
                    tableView.reloadSections(IndexSet.init(integer: indexPath.section), with: .none)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        if orientation == .left {
            return nil
        } else {
            let delete = SwipeAction(style: .destructive, title: nil) { action, indexPath in
                let popupImage = UIImage.init(icon: .fontAwesomeSolid(.eraser), size: CGSize(width: 30, height: 30), textColor: .white)
                showPopupConfirmation(title: "Sure you want to delete your progress on \(self.kasamHistoryArray[indexPath.row].shortDate)?", description: "", image: popupImage, buttonText: "Delete") {(success) in
                    DBRef.userPersonalHistory.child(self.transferArray!.kasamID).child(self.kasamHistoryArray[indexPath.row].fullDate).setValue(nil)
                    self.kasamHistoryArray.remove(at: indexPath.row)
                    self.historyTableView.reloadData()
                    self.updateViewConstraints()
                    SwiftEntryKit.dismiss()
                }
            }
            configure(action: delete, with: .trash)

            let edit = SwipeAction(style: .default, title: nil) { action, indexPath in
                self.dateToLoadGlobal = self.kasamHistoryArray[indexPath.row].fullDate.stringToDate()
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
