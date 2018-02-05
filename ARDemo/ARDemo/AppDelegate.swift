//
//  AppDelegate.swift
//  ARDemo
//
//  Created by 623971951 on 2017/12/27.
//  Copyright © 2017年 syc. All rights reserved.
//

import UIKit
import SceneKit
import CoreLocation

// 全局变量
var locationService: LocationService!
// 保存轨迹, 可以通过 key archive 归档
var singleScene: SCNScene!
// 保存圆点的 GPS
var lastLocation: CLLocation!


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // get last locatin
        if let latitude = UserDefaults.standard.value(forKey: "latitude") as? Double,
            let longitude = UserDefaults.standard.value(forKey: "longitude") as? Double,
            let altitude = UserDefaults.standard.value(forKey: "altitude") as? Double{
            
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            lastLocation = CLLocation(coordinate: coordinate, altitude: altitude)
        }
        //UserDefaults.standard.set(location.coordinate.latitude, forKey: "latitude")
        //UserDefaults.standard.set(location.coordinate.longitude, forKey: "longitude")
        
        let v = TabViewController()
        let nav = UINavigationController(rootViewController: v)
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = nav
        window?.makeKeyAndVisible()
        
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


}

