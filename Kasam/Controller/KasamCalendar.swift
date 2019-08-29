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

class KasamCalendar: UIViewController, FSCalendarDataSource, FSCalendarDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var calendar: FSCalendar!
    @IBOutlet weak var calendarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var calendarChamfer: UIView!
    @IBOutlet weak var topLabel: UIView!
    
    var kasamBlocks: [KasamCalendarBlockFormat] = []
    var kasamPrefernce: [KasamPreference] = []
    var blockURLGlobal = ""
    var dateSelected = ""
    let semaphore = DispatchSemaphore(value: 1)
    
    fileprivate lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter
    }()
    fileprivate lazy var scopeGesture: UIPanGestureRecognizer = {
        [unowned self] in
        let panGesture = UIPanGestureRecognizer(target: self.calendar, action: #selector(self.calendar.handleScopeGesture(_:)))
        panGesture.delegate = self
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 2
        return panGesture
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpCalendar()
        getPreferences {self.retrieveKasams()}
        
        let calendarUpdate = NSNotification.Name("KasamCalendarUpdate")
        NotificationCenter.default.addObserver(self, selector: #selector(KasamCalendar.getContinuedPreferences), name: calendarUpdate, object: nil)
    }

    deinit {
        print("\(#function)")
    }
    
    // MARK:- UIGestureRecognizerDelegate
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let shouldBegin = self.tableView.contentOffset.y <= -self.tableView.contentInset.top
        if shouldBegin {
            let velocity = self.scopeGesture.velocity(in: self.view)
            switch self.calendar.scope {
            case .month:
                return velocity.y < 0
            case .week:
                return velocity.y > 0
            }
        }
        return shouldBegin
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
    
    
    func getPreferences(_ completion: @escaping () -> ()) {
        kasamPrefernce.removeAll()
        kasamUserRef.observeSingleEvent(of: .value, with:{ (snap) in
        let count = Int(snap.childrenCount)
            self.kasamUserRefHandle = self.kasamUserRef.observe(.childAdded) { (snapshot) in
                //Get Kasams from user following + their preference for each kasam
                var dateJoined = Date()
                var startTime = ""
                let kasamID = snapshot.key
                
                for child in snapshot.children {
                    let snap = child as! DataSnapshot
                    if snap.key == "Date Joined" {
                        dateJoined = self.dateConverter(datein: snap.value as! String)
                    } else if snap.key == "Time" {
                        startTime = snap.value as! String
                    }
                }
                let perference = KasamPreference(kasamID: kasamID, joinedDate: dateJoined, startTime: startTime)
                self.kasamPrefernce.append(perference)
                if self.kasamPrefernce.count == count {completion()}
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
                //Going through the blocks under a Kasam
                if selectedDate >= kasam.joinedDate {
                    diff = Calendar.current.dateComponents([.day], from: kasam.joinedDate, to: selectedDate).day!
                    self.blockUserRef = Database.database().reference().child("Coach-Kasams").child(kasam.kasamID).child("Blocks")
                    self.blockUserRefHandle = self.blockUserRef.observe(.value, with: { (snapshot: DataSnapshot!) in
                        let finalOrder = String(diff % Int(snapshot.childrenCount) + 1)
                
                        //Seeing which blocks are needed for the day
                        self.orderUserRef = self.blockUserRef.queryOrdered(byChild: "Order").queryEqual(toValue : finalOrder)
                        self.orderUserRefHandle = self.orderUserRef.observe(.value, with: { (snapshot: DataSnapshot) in
            
                            //Gets all the info for one block
                            for blockSnap in snapshot.children {
                                print("In blockSnap with \(kasam.kasamID)")
                                let valueSnapshot = blockSnap as! DataSnapshot
                                let value = valueSnapshot.value as! [String:String]
                                let blockURL = URL(string: value["Image"] ?? "")
                                var hour = ""
                
                                if let range = kasam.startTime.range(of: ":") {
                                    let firstPart = kasam.startTime[(kasam.startTime.startIndex)..<range.lowerBound]
                                    hour = String(format: "%02d", Int(firstPart)!)
                                }
        //              let am = String(startTime.suffix(2))
                                guard let minute = kasam.startTime.slice(from: ":", to: " ") else {
                                    return
                                    }
                                    let block = KasamCalendarBlockFormat(title: value["Title"] ?? "", hour: hour , minute: minute, duration: value["Duration"] ?? "", image: blockURL!, url: value["Link"] ?? "", creator: "Shawn T")
                                    self.kasamBlocks.append(block)
                                    sem.signal()
                                    self.tableView.reloadData()
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
    
    //Stops the observer
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopObserving(ref: kasamUserRef, handle: kasamUserRefHandle)
        stopObserving(ref: blockUserRef, handle: blockUserRefHandle)
        stopObserving(ref: orderUserRef, handle: orderUserRefHandle)
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
        self.calendarHeightConstraint.constant = bounds.height
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
}

extension KasamCalendar: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return kasamBlocks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let block = kasamBlocks[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "CalendarKasamBlock") as! KasamCalendarCell
        if indexPath.row != kasamBlocks.count - 1 {
            cell.setBlock(block: block, end: false)
        } else {
            cell.setBlock(block: block, end: true)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 15.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let blockID = kasamBlocks[indexPath.row].url
        blockURLGlobal = blockID
        getBlockVideo(url: blockID)
    }
    
    func setUpCalendar(){
        calendarChamfer.layer.cornerRadius = 10
        calendarChamfer.clipsToBounds = true

        self.topLabel.backgroundColor = UIColor.baseColor
        self.calendar.calendarHeaderView.backgroundColor = UIColor.baseColor
        
        self.calendar.select(Date())
        self.view.addGestureRecognizer(self.scopeGesture)
        self.tableView.panGestureRecognizer.require(toFail: self.scopeGesture)
        self.calendar.scope = .week
        self.calendar.appearance.headerMinimumDissolvedAlpha = 0.0
        self.calendar.headerHeight = 40
        
        // For UITest
        self.calendar.accessibilityIdentifier = "calendar"
    }
}
