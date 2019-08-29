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
import SkeletonView

class ProfileViewController: UIViewController {
   
    @IBOutlet weak var userFirstName: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var calendarNo: UILabel!
    @IBOutlet weak var winsNo: UILabel!
    @IBOutlet weak var followingNo: UILabel!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var logOut: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        profileSetup()
        profileUpdate()
        profilePicture()
        view.showAnimatedSkeleton()
        self.navigationItem.title = ""
        navigationController?.navigationBar.barTintColor = UIColor.init(red: 249, green: 249, blue: 249)
        let notificationName = NSNotification.Name("ProfileUpdate")
        NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.profileUpdate), name: notificationName, object: nil)
    }
    
    var kasamsRef: DatabaseReference! = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!)
    var kasamsRefHandle: DatabaseHandle!
    
    @IBAction func logOut(_ sender: Any) {
        AppManager.shared.logoout()
        LoginManager().logOut()
        self.dismiss(animated: true, completion: nil)
    }
    
    func profileSetup(){
        let userName = Auth.auth().currentUser?.displayName
        userFirstName.text = userName
        if let truncUserFirst = Auth.auth().currentUser?.displayName?.split(separator: " ").first.map(String.init), let truncUserLast = Auth.auth().currentUser?.displayName?.split(separator: " ").last.map(String.init) {
            userFirstName.text = truncUserFirst + " " + truncUserLast
        }
        self.profileImage.layer.cornerRadius = self.profileImage.frame.width / 2
        self.profileImage.clipsToBounds = true
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
                    self.profileImage?.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder.png"), completed: { (image, error, cache, url) in
                        self.view.hideSkeleton(transition: .crossDissolve(0.25))
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
