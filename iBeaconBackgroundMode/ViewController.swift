//
//  ViewController.swift
//  iBeaconBackgroundMode
//
//  Created by wwwins on 2016/4/20.
//  Copyright © 2016年 wwwins. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {

  private var regionState:CLRegionState?
  private let proximityUUID = [
    NSUUID(UUIDString: "B5B182C7-EAB1-4988-AA99-B5C1517008D9"),
//    NSUUID(UUIDString: "B5B182C7-EAB1-4988-AA99-B5C1517008D8"),
//    NSUUID(UUIDString: "B5B182C7-EAB1-4988-AA99-B5C1517008D7")
  ]
  private var locationManager:CLLocationManager?
  //private var myRegion:CLBeaconRegion?
  private var myRegions:NSMutableArray = []

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.

    /** Info.plist
    <key>UIBackgroundModes</key>
    <array>
    <string>bluetooth-central</string>
    <string>location</string>
    */
    locationManager = CLLocationManager()
    locationManager!.requestAlwaysAuthorization()
    locationManager!.desiredAccuracy = kCLLocationAccuracyBest
    locationManager!.allowsBackgroundLocationUpdates = true
    locationManager!.pausesLocationUpdatesAutomatically = false
    locationManager!.delegate = self

    for uuid in proximityUUID {
      // 指定 major/minor id 反應會比較快
      let s = (uuid?.UUIDString)!
      let beacon = CLBeaconRegion(proximityUUID: uuid!, major: 1, minor: 9, identifier: s)
      //let beacon = CLBeaconRegion(proximityUUID: uuid!, identifier: s)
      //let beacon = CLBeaconRegion(proximityUUID: uuid!, major: 1, identifier: s)
      myRegions.addObject(beacon)
    }
    startMonitoring()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)

  }

  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)

  }

  /**
  前景或背景下偵測 ibeacon 可以用 startRangingBeaconsInRegion
  要在 app 不執行的狀態下偵測 ibeacon 必需用 startMonitoringForRegion
  */
  func startMonitoring() {
    print("Start Monitoring")
    locationManager!.startUpdatingLocation()
    for r in myRegions {
      let region = r as! CLBeaconRegion
      locationManager!.startMonitoringForRegion(region)
      locationManager!.startRangingBeaconsInRegion(region)
    }

  }

  func stopMonitoring() {
    print("Stop Monitoring")
    for r in myRegions {
      let region = r as! CLBeaconRegion
      locationManager!.stopMonitoringForRegion(region)
      locationManager!.stopRangingBeaconsInRegion(region)
    }

  }

  // startRangingBeaconsInRegion 觸發
  func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
    //print("Range Beacons",beacons)

  }

  // startMonitoringForRegion 觸發
  func locationManager(manager: CLLocationManager, didDetermineState state: CLRegionState, forRegion region: CLRegion) {

    print("Determine:",region)

    var msg:String
    switch state {
      case .Inside:
        print("Inside")
        UIView.animateWithDuration(0.5, animations: { () -> Void in
          self.view.backgroundColor = UIColor.greenColor()
        })
        msg = "Inside"
      case .Outside:
        print("Outside")
        UIView.animateWithDuration(0.5, animations: { () -> Void in
          self.view.backgroundColor = UIColor.redColor()
        })
        msg = "Outside"
      case .Unknown:
        print("Unknown")
        UIView.animateWithDuration(0.5, animations: { () -> Void in
          self.view.backgroundColor = UIColor.grayColor()
        })
        msg = "Unknown"
    }
    if (regionState != state) {
      regionState = state
      let idString = region.identifier.substringFromIndex(region.identifier.startIndex.advancedBy(34))
      sendNotification(idString + ":" + msg)
      load_data("http://192.168.200.103:8000/index.html?"+String(arc4random()))
    }


  }

// startMonitoringForRegion 觸發
//  func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
//    print("Enter Region")
//
//  }
//
//  func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
//    print("Exit Region")
//    
//  }

  func sendNotification(msg:String) {
    let buf = msg + ":" + NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .ShortStyle, timeStyle: .MediumStyle)
    let notification = UILocalNotification()
    notification.alertBody = buf
    notification.soundName = "Default"
    UIApplication.sharedApplication().presentLocalNotificationNow(notification)
  }

  func load_data(urlString:String) {
    let url = NSURL(string: urlString)!
    let session = NSURLSession.sharedSession()
    let request = NSMutableURLRequest(URL: url)
//    request.HTTPMethod = "POST"
//    request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringCacheData
//    let paramString = ""
//    request.HTTPBody = paramString.dataUsingEncoding(NSUTF8StringEncoding)

    let task = session.dataTaskWithRequest(request) {
      (let data, let response, let error) in guard let _:NSData = data, let _:NSURLResponse = response  where error == nil else {
          print("error")
          return
      }
      let dataString = NSString(data: data!, encoding: NSUTF8StringEncoding)
      print(dataString)
    }
    task.resume()
  }

}

