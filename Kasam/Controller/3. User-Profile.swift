//
//  ProfileViewController.swift
//  Kasam 1.0
//
//  Created by Vance Basilio on 2019-04-22.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Firebase
import Parchment
import FBSDKLoginKit
import SwiftEntryKit
import SkeletonView

class ProfileViewController: UIViewController {
   
    @IBOutlet weak var userFirstName: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var calendarNo: UILabel!
    @IBOutlet weak var followingNo: UILabel!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var levelLine: UIView!
    @IBOutlet weak var levelLineProgress: NSLayoutConstraint!
    @IBOutlet weak var levelLineBack: UIView!
    @IBOutlet weak var startLevel: UILabel!
    @IBOutlet weak var totalDays: UILabel!
    @IBOutlet weak var weekStatsCollectionView: UICollectionView!
    @IBOutlet weak var detailedStatsCollectionView: UICollectionView!
    @IBOutlet weak var detailedStatsCollectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var challoStatsHeight: NSLayoutConstraint!
    @IBOutlet weak var topViewHeight: NSLayoutConstraint!
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var contentView: NSLayoutConstraint!
    @IBOutlet weak var sideMenuButton: UIButton!
    @IBOutlet weak var completedKasamsTable: SelfSizedTableView!
    @IBOutlet weak var completedKasamTableHeight: NSLayoutConstraint!
    
    var weeklyStats: [weekStatsFormat] = []
    var detailedStats: [UserStatsFormat] = []
    var completedStats: [UserStatsFormat] = []
    var daysCompletedDict: [String:Int] = [:]
    var dayDictionary = [Int:String]()
    var metricDictionary = [Int:Double]()
    
    //Kasam Following
    var kasamIDGlobal: String = ""
    var kasamTitleGlobal: String = ""
    var kasamMetricTypeGlobal: String = ""
    var kasamImageGlobal: URL!
    var kasamHistoryRef: DatabaseReference! = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("History")
    var kasamUserRef: DatabaseReference! = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!)
    var kasamUserRefHandle: DatabaseHandle!
    var kasamHistoryRefHandle: DatabaseHandle!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        profileSetup()
        profileUpdate()
        profilePicture()
        setupDateDictionary()
        viewSetup()
        getDetailedStats()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //hides the nav bar
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidLayoutSubviews(){
        //Table Resizing
        completedKasamsTable.frame = CGRect(x: completedKasamsTable.frame.origin.x, y: completedKasamsTable.frame.origin.y, width: completedKasamsTable.frame.size.width, height: completedKasamsTable.contentSize.height)
        self.completedKasamTableHeight.constant = self.completedKasamsTable.contentSize.height
        completedKasamsTable.reloadData()
        
        let frame = self.view.safeAreaLayoutGuide.layoutFrame
        collectionViewHeight.constant = detailedStatsCollectionViewHeight.constant + challoStatsHeight.constant + 52.5 + 52.5
        let tableViewHeight = completedKasamTableHeight.constant + 42.5                                          //42.5 is the completed label height
        let contentViewHeight = topViewHeight.constant + collectionViewHeight.constant + tableViewHeight + 15 + 1   //15 is the bottom space
        if contentViewHeight > frame.height {
            contentView.constant = contentViewHeight
        } else if contentViewHeight <= frame.height {
            let diff = frame.height - contentViewHeight
            contentView.constant = contentViewHeight + diff + 1
        }
    }
    
    func viewSetup(){
        profileImage.showAnimatedSkeleton()
        levelLineBack.layer.cornerRadius = 4
        levelLineBack.clipsToBounds = true
        levelLine.layer.cornerRadius = 4
        levelLine.clipsToBounds = true
        sideMenuButton.setIcon(icon: .fontAwesomeSolid(.bars), iconSize: 17, color: UIColor.darkGray, backgroundColor: .clear, forState: .normal)
        self.navigationItem.title = ""
        navigationController?.navigationBar.barTintColor = UIColor.init(red: 249, green: 249, blue: 249)
        let notificationName = NSNotification.Name("ProfileUpdate")
        NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.profileUpdate), name: notificationName, object: nil)
        let challoStatsUpdate = NSNotification.Name("ChalloStatsUpdate")
        NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.getDetailedStats), name: challoStatsUpdate, object: nil)
        let goToCreateKasam = NSNotification.Name("GoToCreateKasam")
        NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.goToCreateKasam), name: goToCreateKasam, object: nil)
    }
    
    @IBAction func showUserOptionsButton(_ sender: Any) {
        showUserOptions()
    }
    
    @objc func goToCreateKasam() {
        performSegue(withIdentifier: "goToCreateKasam", sender: nil)
    }
    
    //GET ALL THE STATS-------------------------------------------------------------------------------------------------
    
    @objc func getDetailedStats() {
        detailedStats.removeAll()
        completedStats.removeAll()
        //loops through all kasams that user is following and get kasamID
        for kasam in SavedData.kasamArray {
            Database.database().reference().child("Coach-Kasams").child(kasam.kasamID).observeSingleEvent(of: .value) {(snap) in
                let snapshot = snap.value as! Dictionary<String,Any>
                let imageURL = URL(string:snapshot["Image"]! as! String)        //getting the image and saving it to SavedData
                kasam.image = snapshot["Image"]! as! String
                kasam.metricType = snapshot["Metric"]! as! String               //getting the metricType and saving it to SavedData
                let userStats = UserStatsFormat(kasamID: kasam.kasamID, kasamTitle: kasam.kasamName, imageURL: imageURL ?? self.placeholder() as! URL, joinedDate: kasam.joinedDate, endDate: kasam.endDate, metricType: kasam.metricType)
                if kasam.status == "completed" {
                    self.completedStats.append(userStats)
                    self.completedKasamsTable.reloadData()
                } else {
                    self.detailedStats.append(userStats)
                    self.detailedStatsCollectionView.reloadData()
                }
                if self.detailedStats.count + self.completedStats.count == SavedData.kasamArray.count {
                    self.getWeeklyStats()
                }
            
            //Kasam Level
            self.kasamHistoryRefHandle = self.kasamHistoryRef.child(kasam.kasamID).observe(.childAdded, with:{ (snapshot) in
                self.daysCompletedDict[snapshot.key] = 1
                let total = self.daysCompletedDict.count
                if total == 1 {
                     self.totalDays.text = "\(String(total)) Kasam Day"
                } else {
                    self.totalDays.text = "\(String(total)) Kasam Days"
                }
                if total <= 30 {
                    self.startLevel.setIcon(prefixText: "", icon: .fontAwesomeSolid(.smile), postfixText: " Beginner", size: 15)
                    self.levelLineProgress.constant = self.levelLineBack.frame.size.width * CGFloat(Double(total) / 30.0)
                } else if total > 30 && total <= 90 {
                    self.startLevel.setIcon(prefixText: "", icon: .fontAwesomeSolid(.grin), postfixText: " Intermediate", size: 15)
                    self.levelLineProgress.constant = self.levelLineBack.frame.size.width * CGFloat(Double(total) / 90.0)
                }
            })
            }
        }
    }
    
    func getWeeklyStats() {
        weeklyStats.removeAll()
        metricDictionary.removeAll()
        for kasam in SavedData.kasamTodayArray {
            let daysPast = (Calendar.current.dateComponents([.day], from: kasam.joinedDate, to: Date()).day!) + 1
            var metricCount = 0
            var metricMatrix = 0
            var checkerCount = 0
            let imageURL = URL(string:kasam.image)
            for x in 1...7 {
                var avgMetric = 0
                self.kasamHistoryRef.child(kasam.kasamID).child(self.dayDictionary[x]!).observe(.value, with:{(snapshot) in
                    checkerCount += 1
                    self.metricDictionary[x] = 0                                      //to set the base as zero for each day
                    
                    //only records progress bar if the joined date is after the kasam date
                    if self.stringToDate(date: self.dayDictionary[x]!) >= kasam.joinedDate {
                        if let value = snapshot.value as? [String: Any] {
                            self.metricDictionary[x] = value["Metric Percent"] as? Double   //get the metric for each day for each kasam
                            metricMatrix += Int(value["Total Metric"] as? Double ?? 0.0)
                            metricCount += 1
                        }
                    }
                    if checkerCount == 7 {
                        if metricCount != 0 {
                            avgMetric = (metricMatrix / metricCount)
                        }
                        self.weeklyStats.append(weekStatsFormat(kasamID: kasam.kasamID, kasamTitle: kasam.kasamName, imageURL: imageURL ?? self.placeholder() as! URL, daysLeft: daysPast, metricType: kasam.metricType, metricDictionary: self.metricDictionary, avgMetric: avgMetric, order: kasam.kasamOrder))
                        self.weeklyStats = self.weeklyStats.sorted(by: { $0.order < $1.order })     //orders the array as kasams with no history will always show up first, even though they were loaded later
                        self.weekStatsCollectionView.reloadData()
                    }
                })
            }
        }
    }
    
    func setupDateDictionary(){
        let todayDay = Date().dayNumberOfWeek()
        if todayDay == 1 {
            for x in 1...7 {
                self.dayDictionary[x] = self.dateFormat(date: Calendar.current.date(byAdding: .day, value: x - 7, to: Date())!)
            }
        } else {
            for x in 1...7 {
                self.dayDictionary[x] = self.dateFormat(date: Calendar.current.date(byAdding: .day, value: x - (todayDay! - 1), to: Date())!)
            }
        }
    }
    
    //PROFILE SETUP-------------------------------------------------------------------------------------------------
    
    func profileSetup(){
        self.profileImage.layer.cornerRadius = self.profileImage.frame.width / 2
        self.profileImage.clipsToBounds = true
        let userName = Auth.auth().currentUser?.displayName
        userFirstName.text = userName
        if let truncUserFirst = Auth.auth().currentUser?.displayName?.split(separator: " ").first.map(String.init), let truncUserLast = Auth.auth().currentUser?.displayName?.split(separator: " ").last.map(String.init) {
            userFirstName.text = truncUserFirst + " " + truncUserLast
        }
    }
    
    @objc func profileUpdate() {
        var kasamcount = 0
        var followingcount: [String: String] = [:]
        calendarNo.text = String(kasamcount)
        followingNo.text = String(followingcount.count)
            self.kasamUserRefHandle = self.kasamUserRef.child("Kasam-Following").observe(.childAdded) { (snapshot) in
                kasamcount += 1
                followingcount = [snapshot.key: "1"]
                self.calendarNo.text = String(kasamcount)
                self.followingNo.text = String(followingcount.count)
        }
    }
    
    func profilePicture() {
        if let user = Auth.auth().currentUser {
            let storage = Storage.storage()
            let storageRef = storage.reference(forURL: "gs://kasam-coach.appspot.com")
            let profilePicRef = storageRef.child("users/"+user.uid+"/profile_pic.jpg")
            
            //Check if the image is stored in Firebase
            profilePicRef.downloadURL { (url, error) in
                if url != nil {
                    //Get the image from Firebase
                    self.profileImage?.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder.png"), options: [], completed: { (image, error, cache, url) in
                        self.profileImage.hideSkeleton()
                    })
                } else {
                    if error != nil {
                    //Unable to download image from Firebase, so get from Facebook
                        let profilePic = GraphRequest(graphPath: "me/picture", parameters:  ["height": 300, "width": 300, "redirect": false], httpMethod: HTTPMethod(rawValue: "GET"))
                        profilePic.start(completionHandler: {(connection, result, error) -> Void in
                            if(error == nil)
                            {
                                let dictionary = result as? NSDictionary
                                let data = dictionary?.object(forKey: "data")
                                let urlPic = ((data as AnyObject).object(forKey: "url"))! as! String
                                if let imageData = NSData(contentsOf: NSURL(string:urlPic)! as URL)
                                {
                                    //Upload the file to the storage reference location
                                    _ = profilePicRef.putData(imageData as Data, metadata:nil){
                                        metadata, error in
                                        if(error == nil)
                                        {//image successfully downloaded to Firebase
                                        }
                                        else {print("Error in downloading image")}
                                    }
                                    self.profileImage.image = UIImage(data: imageData as Data)
                                    self.profileImage.hideSkeleton()
                                }
                            }
                        })
                    }
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToStats" {
            let kasamTransferHolder = segue.destination as! StatisticsViewController
            kasamTransferHolder.kasamID = kasamIDGlobal
            kasamTransferHolder.kasamName = kasamTitleGlobal
            kasamTransferHolder.kasamMetricType = kasamMetricTypeGlobal
            kasamTransferHolder.kasamImage = kasamImageGlobal
        }
    }
    
    //Stops the observer
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if kasamUserRefHandle != nil {
            self.kasamUserRef.removeObserver(withHandle: self.kasamUserRefHandle!)
        }
        if kasamHistoryRefHandle != nil {
            self.kasamHistoryRef.removeObserver(withHandle: self.kasamHistoryRefHandle)
        }
    }
}

extension ProfileViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == weekStatsCollectionView {
            if weeklyStats.count == 0 {
                return 1
            } else {
                return weeklyStats.count
            }
        } else {
            return detailedStats.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == weekStatsCollectionView {
            challoStatsHeight.constant = (view.bounds.size.width * (2/5))
        return CGSize(width: (view.frame.size.width - 30), height: view.frame.size.width * (2/5))
        } else {
            let cellWidth = ((view.frame.size.width - (15 * 4)) / 3)
            detailedStatsCollectionViewHeight.constant = cellWidth + 40
            return CGSize(width: cellWidth, height: cellWidth + 40)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == weekStatsCollectionView {
            if weeklyStats.count == 0 {
                //go to Discover Page when clicked
                animateTabBarChange(tabBarController: self.tabBarController!, to: self.tabBarController!.viewControllers![0])
                self.tabBarController?.selectedIndex = 0
            } else {
                kasamTitleGlobal = weeklyStats[indexPath.row].kasamTitle
                kasamIDGlobal = weeklyStats[indexPath.row].kasamID
                kasamMetricTypeGlobal = weeklyStats[indexPath.row].metricType
                kasamImageGlobal = weeklyStats[indexPath.row].imageURL
            }
        } else {
            kasamTitleGlobal = detailedStats[indexPath.row].kasamTitle
            kasamIDGlobal = detailedStats[indexPath.row].kasamID
            kasamMetricTypeGlobal = detailedStats[indexPath.row].metricType
            kasamImageGlobal = detailedStats[indexPath.row].imageURL
        }
        self.performSegue(withIdentifier: "goToStats", sender: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == weekStatsCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChalloStatsCell", for: indexPath) as! WeeklyStatsCell
            cell.height = challoStatsHeight.constant
            if weeklyStats.count == 0 {
                cell.setPlaceholder()
            } else {
                let stat = weeklyStats[indexPath.row]
                cell.setBlock(cell: stat)
            }
            return cell
        } else {
            let kasam = detailedStats[indexPath.row]
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "KasamFollowingCell", for: indexPath) as! KasamFollowingCell
            cell.setBlock(cell: kasam)
            return cell
        }
    }
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return completedStats.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let block = completedStats[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "CompletedKasamCell") as! CompletedKasamCell
        cell.setBlock(block: block)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        kasamTitleGlobal = completedStats[indexPath.row].kasamTitle
        kasamIDGlobal = completedStats[indexPath.row].kasamID
        kasamMetricTypeGlobal = completedStats[indexPath.row].metricType
        kasamImageGlobal = completedStats[indexPath.row].imageURL
        self.performSegue(withIdentifier: "goToStats", sender: indexPath)
    }
}
