//
//  ViewController.swift
//  Kasam 1.0
//
//  Created by Vance Basilio on 2019-04-19.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit
import GoogleSignIn

class ViewController: UIViewController, GIDSignInDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var segmentedControl: CustomSegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance().delegate = self
        self.hideKeyboardWhenTappedAround()
    }
    
    //make the login screen move with the segmented control
    func scrollToMenuIndex(menuIndex: Int) {
        let indexPath = NSIndexPath(item: menuIndex, section: 0)
        collectionView?.scrollToItem(at: indexPath as IndexPath, at: .init(), animated: true)
    }
    
    //moves the segmented control when the login screen is swiped
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let index = Int(targetContentOffset.pointee.x / view.frame.width)
        segmentedControl.changeScroll(index: index)
        segmentedControl.buttons[index].setTitleColor(segmentedControl.selectorTextColor, for: .normal)
        if index == 0 {
            segmentedControl.buttons[index + 1].setTitleColor(UIColor.white, for: .normal)
        } else {
            segmentedControl.buttons[index - 1].setTitleColor(UIColor.white, for: .normal)
        }
    }
    
    @IBAction func customSegmentValueChanged(_ sender: CustomSegmentedControl) {
        switch sender.selectedSegmentIndex {
            case 0:
                scrollToMenuIndex(menuIndex: 0)
            case 1:
                scrollToMenuIndex(menuIndex: 1)
            default:
                scrollToMenuIndex(menuIndex: 0)
        }
    }
    
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        print("user logged out!")
    }
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LoginViewCell", for: indexPath) as! LoginViewCell
            cell.delegate = self
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RegisterViewCell", for: indexPath) as! RegisterViewCell
            cell.delegate = self
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.size.width, height: collectionView.frame.size.height)
    }
}

extension ViewController: RegisterViewCellDelegate {
    func performSegue() {
        self.performSegue(withIdentifier: "goToMainUser", sender: self)
    }
}

extension ViewController: LoginViewCellDelegate {
    
    func presentAlert(alert: UIAlertController) {
        self.present(alert, animated: true, completion: nil)
    }
    
    func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }
    
    func CustomGoogleLogin() {
        GIDSignIn.sharedInstance().signIn()
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        guard let auth = user.authentication else { return }
        let credentials = GoogleAuthProvider.credential(withIDToken: auth.idToken, accessToken: auth.accessToken)
        Auth.auth().signIn(with: credentials) {(authResult, error) in
            self.userLoginandRegistration(authResult: authResult, error: error)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func CustomFBLogin(){
        LoginManager().logIn(permissions: ["email", "public_profile"], from: self) { (result: LoginManagerLoginResult?, error: Error?) in
            if error == nil {
                if result!.isCancelled {return}
                let credential = FacebookAuthProvider.credential(withAccessToken: AccessToken.current!.tokenString)
                Auth.auth().signIn(with: credential) {(authResult, error) in
                    self.userLoginandRegistration(authResult: authResult, error: error)
                }
                self.dismiss(animated: true, completion: nil)
            } else { //else for first error
                print(error?.localizedDescription as Any)
                return
            }
        }
    }
    
    func userLoginandRegistration(authResult: AuthDataResult?, error: Error?){
        if let error = error {
            //error signing new user in
            print(error.localizedDescription)
            return
        } else {
            let ref = Database.database().reference().child("Users")
            ref.observeSingleEvent(of: .value, with: { (snapshot) in
                //if the user exists, don't add data
                if snapshot.hasChild(Auth.auth().currentUser?.uid ?? "") {
                    //user already exists in Firebase
                    return
                } else {
                    //new Firebase registration
                    let newUser = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!)
                    let userDictionary = ["Name": authResult?.user.displayName!, "History" : "", "UserID": Auth.auth().currentUser?.uid, "Following": "", "Type": "User", "Wins": "5", "Blocks": "7"]
                    
                    newUser.setValue(userDictionary) {
                        (error, reference) in
                        if error != nil {
                            print(error!)
                        } else {
                            print ("Registration Successful!")
                        }
                    }
                    
                    let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                    changeRequest?.displayName = authResult?.user.displayName!
                    changeRequest?.commitChanges { (error) in
                        if error != nil{
                            print(error!)
                        } else {
                            print ("username update successful!")
                            self.performSegue(withIdentifier: "goToMainUser", sender: self)
                            //end of new registration section
                        }
                    }
                }
            })
        }
    }
}

