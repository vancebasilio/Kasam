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
    @IBOutlet weak var logOut: UIButton!
    @IBOutlet weak var challoStatsCollectionView: UICollectionView!
    @IBOutlet weak var challoStatsHeight: NSLayoutConstraint!
    
    var challoStats: [challoStatFormat] = []
    var kasamTitleArray: [String] = []
    var metricTypeArray: [String] = []
    var avgMetricArray: [Int] = []
    var daysLeftArray: [Int] = []
    var daysCompletedDict: [String:Int] = [:]
    var dayDictionary = [Int:String]()
    var metricDictionary = [Int:Double]()
    var kasamFollowingRef: DatabaseReference! = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Kasam-Following")
    var kasamFollowingRefHandle: DatabaseHandle!
    var kasamHistoryRef: DatabaseReference! = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("History")
    var kasamUserRef: DatabaseReference! = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!)
    var kasamUserRefHandle: DatabaseHandle!
    var kasamRef = Database.database().reference().child("Coach-Kasams")
    var kasamRefHandle: DatabaseHandle!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        profileSetup()
        profileUpdate()
        profilePicture()
        setupDateDictionary()
        viewSetup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getChalloStats()
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
    
    @objc func getChalloStats(){
        challoStats.removeAll()
        avgMetricArray.removeAll()
        metricTypeArray.removeAll()
        kasamTitleArray.removeAll()
        //loops through all kasams that user is following and get kasamID
        self.kasamFollowingRefHandle = self.kasamFollowingRef.observe(.childAdded, with:{ (snap) in
            self.kasamRefHandle = self.kasamRef.child(snap.key).observe(.value, with: { (snapshot: DataSnapshot!) in
                if let value = snapshot.value as? [String: Any] {
                    self.kasamTitleArray.append(value["Title"] as? String ?? "")
                    self.metricTypeArray.append(value["Metric"] as? String ?? "")
                }
            })
            
            //gets the kasam days remaining count
            self.kasamHistoryRef.child(snap.key).observeSingleEvent(of: .value, with:{ (snap) in
                let daysCount = Int(snap.childrenCount)
                self.daysLeftArray.append(daysCount)
            })
            
            //gets the kasamLevel
            self.kasamHistoryRef.child(snap.key).observe(.childAdded, with:{ (snapshot) in
                self.daysCompletedDict[snapshot.key] = 1
                let total = self.daysCompletedDict.count
                self.totalDays.text = "\(String(total)) Days"
                self.levelLineProgress.constant = self.levelLineBack.frame.size.width * CGFloat(Double(total) / 30.0)
            })
        
            //gets the stats for each kasam
            var metricMatrix: Int = 0
            var count = 0
            for x in 1...7 {
                self.kasamHistoryRef.child(snap.key).child(self.dayDictionary[x]!).observe(.value, with:{ (snapshot) in
                    if let value = snapshot.value as? [String: Any] {
                        self.metricDictionary[x] = value["Metric Percent"] as? Double
                        metricMatrix += Int(value["Total Metric"] as? Double ?? 0.0)
                        count += 1
                    }
                    
                    if x == 7 {
                        let transferStats = challoStatFormat(metricDictionary: self.metricDictionary)
                        self.challoStats.append(transferStats)
                        self.avgMetricArray.append(metricMatrix / count)
                        self.challoStatsCollectionView.reloadData()
                        self.metricDictionary.removeAll()
                    }
                })
            }
        })
    }
    
    func setupDateDictionary(){
        let todayDay = Date().dayNumberOfWeek()
        if todayDay == 1 {
            for x in 1...7{
                self.dayDictionary[x] = self.dateFormat(date: Calendar.current.date(byAdding: .day, value: x - 7, to: Date())!)
            }
        } else {
            for x in 1...7{
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
    
    func profilePicture(){
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
    
    //Stops the observer
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.kasamUserRef.removeObserver(withHandle: self.kasamUserRefHandle!)
        self.kasamFollowingRef.removeObserver(withHandle: self.kasamFollowingRefHandle)
        self.kasamRef.removeObserver(withHandle: self.kasamRefHandle)
    }
}

extension ProfileViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return challoStats.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        challoStatsHeight.constant = (view.bounds.size.width * (2/5))
        return CGSize(width: (view.frame.size.width - 30), height: view.frame.size.width * (2/5))
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let stat = challoStats[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChalloStatsCell", for: indexPath) as! ChalloStatsCell
        cell.height = challoStatsHeight.constant
        cell.setBlock(cell: stat)
        cell.kasamTitle.text = kasamTitleArray[indexPath.row]
        DispatchQueue.main.async {
            cell.daysLeft.text = String(30 - self.daysLeftArray[indexPath.row]) //async loading this as it takes a long time to gather
        }
        cell.averageMetricLabel.text = "Avg. \(metricTypeArray[indexPath.row])"
        cell.averageMetric.text = String(avgMetricArray[indexPath.row])
        return cell
    }
}
