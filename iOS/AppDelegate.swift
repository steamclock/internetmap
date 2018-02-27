//
//  AppDelegate.swift
//  Internet Map
//
//  Created by Nigel Brooke on 2018-02-15.
//  Copyright © 2018 Peer1. All rights reserved.
//

import UIKit
//import BuddyBuildSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    @objc public var rootVC: RootVC!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        rootVC = window?.rootViewController as! RootVC
        BuddyBuildSDK.setup()
        return true
    }
}
