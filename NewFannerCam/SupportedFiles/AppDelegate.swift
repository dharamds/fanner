//
//  AppDelegate.swift
//  NewFannerCam
//
//  Created Jin on 12/24/18.
//  Copyright © 2018 fannercam3. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift
import DropDown
import WatchConnectivity
import AVFoundation

fileprivate(set) var dirManager             : DirectoryManager!
fileprivate(set) var backgroundQueue        : DispatchQueue!

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    public var videoTimerTime       : String = "00'00"
    public var videoCountdownTime   : String = "15'00"
    public var isTimeFromCountdown      : Bool = true
    var yourNumber = 0
    var secondWindow: UIWindow?
    var window: UIWindow?
    var loginWindow : UIWindow!
    public var isSwiped : Bool = false
    
    static var shared: AppDelegate {
        guard let `self` = UIApplication.shared.delegate as? AppDelegate else {
            fatalError()
        }
        return self
    }
    
    var myOrientation : UIInterfaceOrientationMask = .portrait
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return myOrientation
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        IQKeyboardManager.shared.enable = true
        UIApplication.shared.delegate = self

        DropDown.startListeningToKeyboard()
        
        dirManager = DirectoryManager()
        backgroundQueue = DispatchQueue(label: "com.fanner.queue", qos: .background, target: nil)
        print("app launched successfully")
        // Activate WCSession so both iPhone and Watch share data
        if WCSession.isSupported() {
            let defaultSession = WCSession.default
            defaultSession.delegate = FannerCamWatchKitShared.sharedManager
     
            defaultSession.activate()
        }

        return true
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

//    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
//        return ApplicationDelegate.shared.application(
//            app,
//            open: url,
//            options: options
//        )
//    }
    
//    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
//        let sourceApplication = options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String
//        let annotation = options[UIApplication.OpenURLOptionsKey.annotation]
//        return GIDSignIn.sharedInstance().handle(url, sourceApplication: sourceApplication,  annotation: annotation)
//    }
    
//    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
//        return googleSignIn.openURL(url, sourceApplication: sourceApplication, annotation: annotation)
//    }
    
    
}
