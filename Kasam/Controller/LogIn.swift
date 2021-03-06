//
//  ViewController.swift
//  Kasam 1.0
//
//  Created by Vance Basilio on 2019-04-19.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import FirebaseUI
import FirebaseDatabase
import FirebaseStorage
import FBSDKLoginKit
import GoogleSignIn
import AuthenticationServices
import CryptoKit

class ViewController: UIViewController, GIDSignInDelegate, FUIAuthDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var segmentedControl: CustomSegmentedControl!
    @IBOutlet weak var kasamLogo: UIImageView!
    
    var currentNonce: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        kasamLogo.image = UIImage(named: "kasam-logo")!.withRenderingMode(.alwaysTemplate)
        kasamLogo.tintColor = UIColor.colorFour
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance().delegate = self
        self.hideKeyboardWhenTappedAround()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        collectionView.shouldIgnoreScrollingAdjustment = true
        scrollView.shouldIgnoreScrollingAdjustment = false
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
            case 0: scrollToMenuIndex(menuIndex: 0)
            case 1: scrollToMenuIndex(menuIndex: 1)
            default: scrollToMenuIndex(menuIndex: 0)
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

extension ViewController: RegisterViewCellDelegate, LoginViewCellDelegate {
    func performSegue() {
        self.performSegue(withIdentifier: "goToMainUser", sender: self)
    }
    
    func showError(_ error: Error) {
        if let errorCode = AuthErrorCode(rawValue: error._code) {
            print(errorCode.errorMessage)
            let alert = UIAlertController(title: "Error", message: errorCode.errorMessage, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
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
            self.firebaseLoginandRegistration(authResult: authResult, appleName: nil, error: error)
            //Get the profile image for google
            self.getProfilePicture(googleUser:user)
        }
    }
    
    func CustomFBLogin(){
        LoginManager().logIn(permissions: ["email", "public_profile"], from: self) {(result: LoginManagerLoginResult?, error: Error?) in
            if error == nil {
                if result!.isCancelled {return}
                let credential = FacebookAuthProvider.credential(withAccessToken: AccessToken.current!.tokenString)
                Auth.auth().signIn(with: credential) {(authResult, error) in
                    self.firebaseLoginandRegistration(authResult: authResult, appleName: nil, error: error)
                    //get the profile image for facebook
                    self.getProfilePicture(googleUser:nil)
                }
                if Auth.auth().currentUser != nil {
                   self.dismiss(animated: true, completion: nil)
                } else {
                    //User Not logged in
                }
            } else { //else for first error
                print(error?.localizedDescription as Any)
                return
            }
        }
    }
    
//Apple Login------------------------------------------------------------------------------------------------
    
    func CustomAppleLogin(){
        let nonce = randomNonceString()
        currentNonce = nonce
        if #available(iOS 13.0, *) {
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = sha256(nonce)
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        } else {
            // Fallback on earlier versions
        }
    }
    
    @available(iOS 13, *)
       private func sha256(_ input: String) -> String {
           let inputData = Data(input.utf8)
           let hashedData = SHA256.hash(data: inputData)
           let hashString = hashedData.compactMap {
               return String(format: "%02x", $0)
           }.joined()
        return hashString
    }
    
    private func randomNonceString(length: Int = 32) -> String {
      precondition(length > 0)
      let charset: Array<Character> =
          Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
      var result = ""
      var remainingLength = length

      while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
          var random: UInt8 = 0
          let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
          if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
          }
          return random
        }

        randoms.forEach { random in
          if remainingLength == 0 {
            return
          }

          if random < charset.count {
            result.append(charset[Int(random)])
            remainingLength -= 1
          }
        }
      }

      return result
    }
    
//Firebase Login------------------------------------------------------------------------------------------------
    
    func firebaseLoginandRegistration(authResult: AuthDataResult?, appleName: String?, error: Error?){
        if let error = error {
            //error signing new user in
            showError(error)
            return
        } else {
            var name = authResult?.user.displayName
            if name == nil && appleName != nil {name = appleName!}
            DBRef.users.observeSingleEvent(of: .value, with: {(snapshot) in
                //If the user exists, don't add data
                if snapshot.hasChild(Auth.auth().currentUser?.uid ?? "") {
                    //user already exists in Firebase, so just sign them in
                    self.dismiss(animated: true, completion: nil)               //this takes them to the Personal page
                    return
                } else {
                    //User doesn't exist, so create a new profile for them
                    let newUser = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!)
                    let userDictionary = ["Name": name, "UserID": Auth.auth().currentUser?.uid, "Type": "Basic"]
                    
                    newUser.child("Info").setValue(userDictionary) {
                        (error, reference) in
                        if error != nil {
                            print(error!)
                        } else {
                            DBRef.userEmails.child(authResult?.user.email?.MD5() ?? "email").setValue((Auth.auth().currentUser?.uid)!)
                        }
                    }
                    let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                    changeRequest?.displayName = name
                    changeRequest?.commitChanges {(error) in
                        if error != nil{
                            print(error!)
                        } else {
                            print ("Username update successful!")
                            self.dismiss(animated: true, completion: nil)               //this takes them to the Personal page
                        }
                    }
                }
            })
        }
    }
    
    func getProfilePicture(googleUser: GIDGoogleUser?){
        if let userFirebase = Auth.auth().currentUser {
            let storage = Storage.storage()
            let storageRef = storage.reference(forURL: "gs://kasam-coach.appspot.com")
            let profilePicRef = storageRef.child("users/"+userFirebase.uid+"/profile_pic.jpg")
            
            //Check if the image is stored in Firebase
            profilePicRef.downloadURL {(url, error) in
                if url != nil {
                    //OPTION 1 - Get the image from Firebase
                } else {
                    if error != nil {
                    //Unable to download image from Firebase, so get from Google
                        if googleUser != nil {
                            //OPTION 2 - Download image from Google
                            if let imageData = NSData(contentsOf: googleUser!.profile.imageURL(withDimension: 400)) {
                            //Upload the file to the storage reference location
                                profilePicRef.putData(imageData as Data, metadata:nil){ metadata, error in
                                    //Image successfully downloaded to Firebase
                                    profilePicRef.downloadURL(completion: { (url, error) in
                                        if let urlText = url?.absoluteString {
                                            Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Info").child("ProfilePic").setValue(urlText)
                                        }
                                    })
                                }
                            }
                        } else {
                            //OPTION 3 - Download image from Facebook
                            let profilePic = GraphRequest(graphPath: "me/picture", parameters:  ["height": 300, "width": 300, "redirect": false], httpMethod: HTTPMethod(rawValue: "GET"))
                            profilePic.start(completionHandler: {(connection, result, error) -> Void in
                                if(error == nil) {
                                    let dictionary = result as? NSDictionary
                                    let data = dictionary?.object(forKey: "data")
                                    let urlPic = ((data as AnyObject).object(forKey: "url"))! as! String
                                    if let imageData = NSData(contentsOf: NSURL(string:urlPic)! as URL) {
                                        //Upload the file to the storage reference location
                                        profilePicRef.putData(imageData as Data, metadata:nil) {metadata, error in
                                            //Image successfully downloaded to Firebase
                                            profilePicRef.downloadURL(completion: { (url, error) in
                                                if let urlText = url?.absoluteString {
                                                    Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Info").child("ProfilePic").setValue(urlText)
                                                }
                                            })
                                        }
                                    }
                                }
                            })
                        }
                    }
                }
            }
        }
    }
}

//Sign in with Apple------------------------------------------------------------------------------------------------

@available(iOS 13.0, *)
extension ViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if (error != nil) {
                    print(error?.localizedDescription ?? "")
                    return
                }
                let appleFullName = "\(appleIDCredential.fullName?.givenName ?? "") \(appleIDCredential.fullName?.familyName ?? "")"
                self.firebaseLoginandRegistration(authResult: authResult, appleName: appleFullName, error: error)
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
        print("Sign in with Apple errored: \(error)")
    }
}

@available(iOS 13.0, *)
extension ViewController : ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}

