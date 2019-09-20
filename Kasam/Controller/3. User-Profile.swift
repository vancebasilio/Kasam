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
    @IBOutlet weak var winsNo: UILabel!
    @IBOutlet weak var followingNo: UILabel!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var logOut: UIButton!
    @IBOutlet weak var challoStatsCollectionView: UICollectionView!
    @IBOutlet weak var challoStatsHeight: NSLayoutConstraint!
    
    var challoStats: [challoStatFormat] = []
    var kasamTitleArray: [String] = []
    var kasamTitle = ""
    var dayDictionary = [Int:String]()
    var metricDictionary = [Int:Double]()
    var kasamFollowingRef: DatabaseReference! = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Kasam-Following")
    var kasamHistoryRef: DatabaseReference! = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("History")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        profileSetup()
        profileUpdate()
        profilePicture()
        setupDateDictionary()
        getChalloStats()
        viewSetup()
    }
    
    func viewSetup(){
        self.navigationItem.title = ""
        navigationController?.navigationBar.barTintColor = UIColor.init(red: 249, green: 249, blue: 249)
        let notificationName = NSNotification.Name("ProfileUpdate")
        NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.profileUpdate), name: notificationName, object: nil)
        let challoStatsUpdate = NSNotification.Name("ChalloStatsUpdate")
        NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.getChalloStats), name: challoStatsUpdate, object: nil)
    }
    
    @objc func getChalloStats(){
        challoStats.removeAll()
        //loops through all kasams that user is following and get kasamID
        self.kasamFollowingRef.observe(.childAdded, with:{ (snap) in
            if let value = snap.value as? [String: Any] {
                self.kasamTitle = value["Kasam Name"] as? String ?? ""
                self.kasamTitleArray.append(self.kasamTitle)
            }
                for x in 1...7 {
                    self.kasamHistoryRef.child(snap.key).child(self.dayDictionary[x]!).child("Metric Completed").observeSingleEvent(of: .value, with:{ (snapshot) in
                        self.metricDictionary[x] = snapshot.value as? Double
                        
                        if x == 7 {
                            let transferStats = challoStatFormat(metric: "Reps", avgMetric: 1000, daysLeft: 5, metricDictionary: self.metricDictionary)
                            self.challoStats.append(transferStats)
                            self.challoStatsCollectionView.reloadData()
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
    
    var kasamsRef: DatabaseReference! = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!)
    var kasamsRefHandle: DatabaseHandle!
    
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
            self.kasamsRefHandle = self.kasamsRef.child("Kasam-Following").observe(.childAdded) { (snapshot) in
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
        self.kasamsRef.removeObserver(withHandle: self.kasamsRefHandle!)
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
        cell.setBlock(cell: stat)
        cell.kasamTitle.text = kasamTitleArray[indexPath.row]
        return cell
    }
    
    
}
