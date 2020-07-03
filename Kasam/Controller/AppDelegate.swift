//
//  AppDelegate.swift
//  Kasam 1.0
//
//  Created by Vance Basilio on 2019-04-19.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import WebKit
import CFNetwork
import Firebase
import GoogleSignIn
import FBSDKCoreKit
import IQKeyboardManagerSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    override init() {
        super.init()
        FirebaseApp.configure()
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        UITabBar.appearance().tintColor = UIColor.colorFour
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // first launch
        // this method is called only on first launch when app was closed / killed
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        IQKeyboardManager.shared.enable = true
        Database.database().reference().child("Assets").child("Levels").observeSingleEvent(of: .value, with:{(snap) in
            let levelsString = snap.value as? String
            Assets.levelsArray = levelsString?.components(separatedBy: ";") ?? ["Easy","Medium","Hard"]
        })
        Database.database().reference().child("Assets").child("Featured").observeSingleEvent(of: .value, with:{(snap) in
            let featuredString = snap.value as? String
            Assets.featuredKasams = featuredString?.components(separatedBy: ";") ?? ["-LqRRHDQuwf2tJmoNoaa"]
        })
        Database.database().reference().child("Assets").child("DiscoverCriteria").observeSingleEvent(of: .value, with:{(snap) in
            let discoverCriteria = snap.value as? String
            Assets.discoverCriteria = discoverCriteria?.components(separatedBy: ";") ?? ["Fitness", "Health", "User"]
        })
        profileInfo()
        
        return true
    }
    
    func profileInfo() {
        if Auth.auth().currentUser != nil {
            DBRef.currentUser.child("Type").observeSingleEvent(of: .value, with:{(snap) in
                SavedData.userType = snap.value as? String ?? "Basic"
            })
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let handled = GIDSignIn.sharedInstance().handle(url)
        return handled
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return ApplicationDelegate.shared.application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {

    }

    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {

    }
}

