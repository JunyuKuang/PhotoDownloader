//
//  AppDelegate.swift
//  PhotoDownloader
//
//  Created by Jonny Kuang on 1/12/18.
//  Copyright © 2018 Jonny Kuang. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        
        window = UIWindow()
        
        let tvc = DownloaderTableViewController(style: .plain)
        window?.rootViewController = UINavigationController(rootViewController: tvc)
        window?.makeKeyAndVisible()
        
        return true
    }
}
