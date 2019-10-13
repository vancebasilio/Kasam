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
    @IBOutlet weak var challoStatsCollectionView: UICollectionView!
    @IBOutlet weak var kasamFollowingCollectionView: UICollectionView!
    @IBOutlet weak var challoStatsHeight: NSLayoutConstraint!
    @IBOutlet weak var logOut: UIButton!
    
    var metricStats: [challoStatFormat] = []
    var userStats: [UserStatsFormat] = []
    var avgMetricArray: [Int] = []
    var daysCompletedDict: [String:Int] = [:]
    var dayDictionary = [Int:String]()
    var metricDictionary = [Int:Double]()
    
    //Kasam Following
    var kasamIDGlobal: String = ""
    var kasamTitleGlobal: String = ""
    var kasamMetricTypeGlobal: String = ""
    var kasamImageGlobal: URL!
    var kasamAvgMetricGlobal = ""
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
        getChalloStats()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
  
    func viewSetup(){
        levelLineBack.layer.cornerRadius = 4
        levelLineBack.clipsToBounds = true
        levelLine.layer.cornerRadius = 4
        levelLine.clipsToBounds = true
        startLevel.setIcon(prefixText: "", icon: .fontAwesomeSolid(.grin), postfixText: " Beginner", size: 15)
        self.navigationItem.title = ""
        navigationController?.navigationBar.barTintColor = UIColor.init(red: 249, green: 249, blue: 249)
        let notificationName = NSNotification.Name("ProfileUpdate")
        NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.profileUpdate), name: notificationName, object: nil)
        let challoStatsUpdate = NSNotification.Name("ChalloStatsUpdate")
        NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.getChalloStats), name: challoStatsUpdate, object: nil)
    }
    
    //too many functions under this. Break it out, so it isn't refinding all these details
    @objc func getChalloStats() {
        metricStats.removeAll()
        userStats.removeAll()
        avgMetricArray.removeAll()
        metricDictionary.removeAll()
        //loops through all kasams that user is following and get kasamID
        for kasam in SavedData.kasamArray {
            Database.database().reference().child("Coach-Kasams").child(kasam.kasamID).observeSingleEvent(of: .value) { (snap) in
                let snapshot = snap.value as! Dictionary<String,Any>
                let metricType = snapshot["Metric"]! as! String
                let imageURL = URL(string:snapshot["Image"]! as! String)
                let daysPast = (Calendar.current.dateComponents([.day], from: kasam.joinedDate, to: Date()).day!) + 1
                let userStats = UserStatsFormat(kasamID: kasam.kasamID, kasamTitle: kasam.kasamName, imageURL: imageURL ?? self.placeholder() as! URL, metricType: metricType, daysLeft: daysPast)
                self.userStats.append(userStats)
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
                self.levelLineProgress.constant = self.levelLineBack.frame.size.width * CGFloat(Double(total) / 30.0)
            })
            
            //Stats for each kasam
            var metricMatrix = 0
            var metricCount = 0
            var checkerCount = 0
            for x in 1...7 {
                self.kasamHistoryRef.child(kasam.kasamID).child(self.dayDictionary[x]!).observe(.value, with:{ (snapshot) in
                    checkerCount += 1
                    self.metricDictionary[x] = 0                                        //to set the base as zero for each day
                    if let value = snapshot.value as? [String: Any] {
                        self.metricDictionary[x] = value["Metric Percent"] as? Double   //get the metric for each day for each kasam
                        metricMatrix += Int(value["Total Metric"] as? Double ?? 0.0)
                        metricCount += 1
                }
                if checkerCount == 7 {
                    if metricCount != 0 {
                        self.avgMetricArray.append(metricMatrix / metricCount)
                    } else {
                        self.avgMetricArray.append(0)                       //if there are no stats, we don't want to divde by zero
                    }
                    self.metricStats.append(challoStatFormat(metricDictionary: self.metricDictionary))
                    self.challoStatsCollectionView.reloadData()
                    self.kasamFollowingCollectionView.reloadData()
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
    
    @IBAction func logOut(_ sender: Any) {
        AppManager.shared.logoout()
        LoginManager().logOut()
        self.dismiss(animated: true, completion: nil)
    }
    
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
                    self.profileImage?.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder.png"))
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
            kasamTransferHolder.avgMetricHolder = String(kasamAvgMetricGlobal)
        }
    }
    
    //Stops the observer
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.kasamUserRef.removeObserver(withHandle: self.kasamUserRefHandle!)
        self.kasamHistoryRef.removeObserver(withHandle: self.kasamHistoryRefHandle)
    }
}

extension ProfileViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == challoStatsCollectionView {
            return metricStats.count
        } else {
            return userStats.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == challoStatsCollectionView {
            challoStatsHeight.constant = (view.bounds.size.width * (2/5))
        return CGSize(width: (view.frame.size.width - 30), height: view.frame.size.width * (2/5))
        } else {
            return CGSize(width: 100, height: 140)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == challoStatsCollectionView {
        } else {
            kasamTitleGlobal = userStats[indexPath.row].kasamTitle
            kasamIDGlobal = userStats[indexPath.row].kasamID
            kasamMetricTypeGlobal = userStats[indexPath.row].metricType
            kasamImageGlobal = userStats[indexPath.row].imageURL
            var avgMetric = ""
            if userStats[indexPath.row].metricType == "mins" && avgMetricArray[indexPath.row] < 60 {
                avgMetric = "\(String(self.avgMetricArray[indexPath.row])) secs"
            } else if userStats[indexPath.row].metricType == "mins" && avgMetricArray[indexPath.row] > 60 {
                let time: Double = Double(self.avgMetricArray[indexPath.row]) / 60.0
                avgMetric = "\(String(time)) mins"
            } else {
                avgMetric = "\(String(self.avgMetricArray[indexPath.row])) \(userStats[indexPath.row].metricType)"
            }
            kasamAvgMetricGlobal = avgMetric
            self.performSegue(withIdentifier: "goToStats", sender: indexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == challoStatsCollectionView {
            let stat = metricStats[indexPath.row]
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChalloStatsCell", for: indexPath) as! ChalloStatsCell
            cell.height = challoStatsHeight.constant
            cell.setBlock(cell: stat)
            cell.kasamTitle.text = userStats[indexPath.row].kasamTitle
            DispatchQueue.main.async {
                cell.daysLeft.text = String(30 - self.userStats[indexPath.row].daysLeft) //async loading this as it takes a long time to gather
            }
            if userStats[indexPath.row].metricType == "mins" && avgMetricArray[indexPath.row] < 60 {
                cell.averageMetric.text = String(self.avgMetricArray[indexPath.row])
                cell.averageMetricLabel.text = "Avg. secs"
            } else if userStats[indexPath.row].metricType == "mins" && avgMetricArray[indexPath.row] > 60 {
                let time: Double = Double(self.avgMetricArray[indexPath.row]) / 60.0
                cell.averageMetric.text = String(time)
                cell.averageMetricLabel.text = "Avg. mins"
            } else {
                cell.averageMetric.text = String(self.avgMetricArray[indexPath.row])
                cell.averageMetricLabel.text = "Avg. \(userStats[indexPath.row].metricType)"
            }
            return cell
        } else {
            let kasam = userStats[indexPath.row]
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "KasamFollowingCell", for: indexPath) as! KasamFollowingCell
            cell.setBlock(cell: kasam)
            return cell
        }
    }
}
