//
//  AppDelegate.swift
//  iBeaconBackgroundMode
//
//  Created by wwwins on 2016/4/20.
//  Copyright © 2016年 wwwins. All rights reserved.
//

import UIKit
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

  var window: UIWindow?
  let locationManager = CLLocationManager()

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.

    // 檢查是否支援 location
    if (locationManager.responds(to: #selector(CLLocationManager.requestAlwaysAuthorization))) {
      print("Support CLLocation")
      //locationManager.requestAlwaysAuthorization()
      //locationManager.delegate = self

      // 註冊播推設定
      let notificationType:UIUserNotificationType = [UIUserNotificationType.sound, UIUserNotificationType.alert]
      let notificationSettings = UIUserNotificationSettings(types: notificationType, categories: nil)
      UIApplication.shared.registerUserNotificationSettings(notificationSettings)

    }

    return true
  }

  func applicationWillResignActive(_ application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }



}

