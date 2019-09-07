//
//  KasamCalendar.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-05-15.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Foundation
import FSCalendar
import Firebase
import SDWebImage
import Lottie

class TodayBlocksViewController: UIViewController, FSCalendarDataSource, FSCalendarDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var calendar: FSCalendar!
    @IBOutlet weak var tableHeight: NSLayoutConstraint!
    @IBOutlet weak var kasamsNumber: UILabel!
    
    var kasamBlocks: [TodayBlockFormat] = []
    var kasamPrefernce: [KasamPreference] = []
    var blockURLGlobal = ""
    var dateSelected = ""
    var kasamIDGlobal = ""
    var blockIDGlobal = ""
    let semaphore = DispatchSemaphore(value: 1)
    let animationView = AnimationView()
    
    fileprivate lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableAndHeader()
        navBarShadow()
        getPreferences {self.retrieveKasams()}
        let stopLoadingAnimation = NSNotification.Name("RemoveLoadingAnimation")
        NotificationCenter.default.addObserver(self, selector: #selector(TodayBlocksViewController.stopLoadingAnimation), name: stopLoadingAnimation, object: nil)
    }
    
    func setupTableAndHeader(){
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 150
        tableView.reloadData()
        let calendarUpdate = NSNotification.Name("KasamCalendarUpdate")
        NotificationCenter.default.addObserver(self, selector: #selector(TodayBlocksViewController.getContinuedPreferences), name: calendarUpdate, object: nil)
    }

    deinit {
        print("\(#function)")
    }
    
    var kasamUserRef: DatabaseReference! = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Kasam-Following")
    var kasamUserRefHandle: DatabaseHandle!
    var blockUserRef: DatabaseReference!
    var blockUserRefHandle: DatabaseHandle!
    var orderUserRef: DatabaseQuery!
    var orderUserRefHandle: DatabaseHandle!
    
    @objc func getContinuedPreferences(){
        getPreferences {self.retrieveKasams()}
    }
    
    @objc func stopLoadingAnimation(){
        animationView.removeFromSuperview()
        print("hello")
    }
    
    func getPreferences(_ completion: @escaping () -> ()) {
        kasamPrefernce.removeAll()
        kasamUserRef.observeSingleEvent(of: .value, with:{ (snap) in
        let count = Int(snap.childrenCount)
            self.kasamUserRefHandle = self.kasamUserRef.observe(.childAdded) { (snapshot) in
                //Get Kasams from user following + their preference for each kasam
                var dateJoined = Date()
                var startTime = ""
                let kasamID = snapshot.key
                var kasamName = ""
                
                for child in snapshot.children {
                    let snap = child as! DataSnapshot
                    if snap.key == "Date Joined" {
                        dateJoined = self.dateConverter(datein: snap.value as! String)
                    } else if snap.key == "Time" {
                        startTime = snap.value as! String
                    } else if snap.key == "Kasam Name" {
                        kasamName = snap.value as! String
                    }
                }
                let preference = KasamPreference(kasamID: kasamID, kasamName: kasamName, joinedDate: dateJoined, startTime: startTime)
                self.kasamPrefernce.append(preference)
                if self.kasamPrefernce.count == count {
                    completion()
                    print ("kasamPreferences stopped observing")
                }
            }
        })
    }
    
    func retrieveKasams() {
        self.kasamBlocks.removeAll()
        let kasamPreferences = self.kasamPrefernce
        let sem = DispatchSemaphore(value: 1)
        var selectedDate = Date()
        if self.dateSelected != "" {
            selectedDate = dateFormatter.date(from: self.dateSelected)!
        }
        
        for kasam in kasamPreferences {
            DispatchQueue.global().async {
                sem.wait()
                var diff = 0
                var displayStatus: String?
                //Going through the blocks under a Kasam
                if selectedDate >= kasam.joinedDate {
                    diff = Calendar.current.dateComponents([.day], from: kasam.joinedDate, to: selectedDate).day!
                    self.blockUserRef = Database.database().reference().child("Coach-Kasams").child(kasam.kasamID).child("Blocks")
                    self.blockUserRefHandle = self.blockUserRef.observe(.value, with: { (snapshot: DataSnapshot!) in
                        let finalOrder = String(diff % Int(snapshot.childrenCount) + 1)
                        let currentDate = self.getCurrentDate()

                        //Seeing which blocks are needed for the day
                        self.orderUserRef = self.blockUserRef.queryOrdered(byChild: "Order").queryEqual(toValue : finalOrder)
                        self.orderUserRefHandle = self.orderUserRef.observe(.value, with: { (snapshot: DataSnapshot) in
                            //Gets all the info for one block
                            for blockSnap in snapshot.children {
                                let valueSnapshot = blockSnap as! DataSnapshot
                                let value = valueSnapshot.value as! [String:Any]
                                let blockURL = URL(string: value["Image"] as! String)
                                var hour = ""
                                
                                //Checks if user has completed Kasam for the current day
                                Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("History").child(kasam.kasamID).observeSingleEvent(of: .value, with: { (snapshot) in
                                    displayStatus = "Check"
                                        if snapshot.hasChild(currentDate ?? ""){
                                                displayStatus = "Check" //Kasam has been completed today
                                            } else {
                                                displayStatus = value["Status"] as?  String //Kasam has NOT been completed today
                                            }
                                            if let range = kasam.startTime.range(of: ":") {
                                                let firstPart = kasam.startTime[(kasam.startTime.startIndex)..<range.lowerBound]
                                                hour = String(format: "%02d", Int(firstPart)!)
                                            }
                                            guard let minute = kasam.startTime.slice(from: ":", to: " ") else {return}
                                    let block = TodayBlockFormat(kasamID: kasam.kasamID, kasamName: kasam.kasamName, title: value["Title"] as! String, hour: hour , minute: minute, duration: value["Duration"] as! String, image: blockURL!, url: value["Link"] as! String, creator: "Shawn T", statusType: value["Status"] as! String, displayStatus: displayStatus ?? "Display Status")
                                            print("block value sent is \(displayStatus!)")
                                            self.kasamBlocks.append(block)
                                            sem.signal()
                                            self.tableView.reloadData()
                                        })
                                    }
                                })
                            })
                        } else if selectedDate < kasam.joinedDate {
                            sem.signal()
                        }
                    }
                }
                self.tableView.reloadData()
            }
    
    func stopObserving(ref: AnyObject?, handle: DatabaseHandle?) {
        guard ref != nil else {
            print("Not observing")
            return
        }
        ref?.removeObserver(withHandle: handle!)
        print("Observer removed")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        self.view.layoutIfNeeded()
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        self.dateSelected = self.dateFormatter.string(from: date)
        retrieveKasams()
        if monthPosition == .next || monthPosition == .previous {
            calendar.setCurrentPage(date, animated: true)
        }
    }
    
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        print("\(self.dateFormatter.string(from: calendar.currentPage))")
    }
    
    func dateConverter(datein: String) -> Date{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy"
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale.current
        let joinedDate = dateFormatter.date(from: datein)
        return joinedDate!
    }
    
    func loadingAnimation(){
        animationView.animation = Animation.named("690-loading")
        animationView.contentMode = .scaleAspectFit
        view.addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.centerXAnchor.constraint(lessThanOrEqualTo: self.view.centerXAnchor).isActive = true
        animationView.centerYAnchor.constraint(lessThanOrEqualTo: self.view.centerYAnchor).isActive = true
        NSLayoutConstraint(item: animationView, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 100).isActive = true
        NSLayoutConstraint(item: animationView, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 100).isActive = true
        animationView.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        animationView.play()
        animationView.loopMode = .loop
    }
}

extension TodayBlocksViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if kasamBlocks.count == 0 {
            self.kasamsNumber.text = "You have no kasams today"
        } else if kasamBlocks.count > 1 {
            self.kasamsNumber.text = "You have \(kasamBlocks.count) kasams to keep today"
        } else {
            self.kasamsNumber.text = "You have \(kasamBlocks.count) kasam to keep today"
        }
        return kasamBlocks.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let height = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 150
        return height
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let block = kasamBlocks[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "CalendarKasamBlock") as! TodayBlockCell
        cell.delegate = self
        if indexPath.row != kasamBlocks.count - 1 {
            cell.setBlock(block: block, end: false)
        } else {
            cell.setBlock(block: block, end: true)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        loadingAnimation()
        UIApplication.shared.beginIgnoringInteractionEvents()
        kasamIDGlobal = kasamBlocks[indexPath.row].kasamID
        blockIDGlobal = kasamBlocks[indexPath.row].title
        performSegue(withIdentifier: "goToKasamViewer", sender: indexPath)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToKasamViewer" {
            let kasamActivityHolder = segue.destination as! KasamViewer
            kasamActivityHolder.kasamID = kasamIDGlobal
            kasamActivityHolder.blockID = blockIDGlobal
        }
    }
}

extension TodayBlocksViewController: TodayCellDelegate {
    func clickedButton(kasamID: String, blockID: String, status: String) {
        let statusDateTime = getCurrentDateTime()
        let statusDate = getCurrentDate()
        print(status)
        //Adds the status data as a subset of the Status
        if status == "Check" { Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("History").child(kasamID).child(statusDate ?? "StatusDate").updateChildValues(["Block Completed": blockID, "Time": statusDateTime ?? "StatusTime"]) {(error, reference) in}
        } else {
            Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("History").child(kasamID).child(statusDate ?? "StatusDateTime").removeValue()
        }
    }
}
