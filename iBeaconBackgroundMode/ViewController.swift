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

  @IBOutlet weak var msgLabel: UILabel!

  fileprivate var regionState:[String:CLRegionState] = [String:CLRegionState]()
  fileprivate let proximityUUID = [
    UUID(uuidString: "B5B182C7-EAB1-4988-AA99-B5C1517008D9"),
//    UUID(uuidString: "B5B182C7-EAB1-4988-AA99-B5C1517008D8"),
//    UUID(uuidString: "B5B182C7-EAB1-4988-AA99-B5C1517008D7")
  ]
  fileprivate var locationManager:CLLocationManager?
  //private var myRegion:CLBeaconRegion?
  fileprivate var myRegions:NSMutableArray = []

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
      let s = (uuid?.uuidString)!
      let beacon = CLBeaconRegion(proximityUUID: uuid!, major: 1, minor: 9, identifier: s)
      //let beacon = CLBeaconRegion(proximityUUID: uuid!, identifier: s)
      //let beacon = CLBeaconRegion(proximityUUID: uuid!, major: 1, identifier: s)
      myRegions.add(beacon)
    }
    startMonitoring()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

  }

  override func viewDidDisappear(_ animated: Bool) {
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
      locationManager!.startMonitoring(for: region)
      locationManager!.startRangingBeacons(in: region)
    }

  }

  func stopMonitoring() {
    print("Stop Monitoring")
    for r in myRegions {
      let region = r as! CLBeaconRegion
      locationManager!.stopMonitoring(for: region)
      locationManager!.stopRangingBeacons(in: region)
    }

  }

  // startRangingBeaconsInRegion 觸發
  func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
    //print("Range Beacons",beacons)

  }

  // startMonitoringForRegion 觸發
  func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {

    print("Determine:",region)

    var msg:String
    switch state {
      case .inside:
        print("Inside")
        UIView.animate(withDuration: 0.5, animations: { () -> Void in
          self.view.backgroundColor = UIColor.green
        })
        msg = "Inside"
      case .outside:
        print("Outside")
        UIView.animate(withDuration: 0.5, animations: { () -> Void in
          self.view.backgroundColor = UIColor.red
        })
        msg = "Outside"
      case .unknown:
        print("Unknown")
        UIView.animate(withDuration: 0.5, animations: { () -> Void in
          self.view.backgroundColor = UIColor.gray
        })
        msg = "Unknown"
    }
    if (regionState.index(forKey: region.identifier) != nil) {
      if (regionState[region.identifier] != state) {
        regionState[region.identifier] = state
        handleRegionActions(region, msg: msg)
      }
    }
    else {
      regionState.updateValue(state, forKey: region.identifier)
      handleRegionActions(region, msg: msg)
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

  // send local notification
  // send http request
  // ble scanning...?
  func handleRegionActions(_ region:CLRegion, msg:String) {
    print("handleRegionActions:"+msg)
    let idString = String(region.identifier.suffix(2))
    msgLabel.text = "編號:" + idString + "\n狀態:" + msg
    if (msg=="Inside") {
      sendNotification(idString + ":" + msg)
//    load_data("https://314f2c94.ngrok.io/?"+String(arc4random()))
    }
  }

  func sendNotification(_ msg:String) {
    let buf = msg + ":" + DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
    let notification = UILocalNotification()
    notification.alertBody = buf
    notification.soundName = "Default"
    UIApplication.shared.presentLocalNotificationNow(notification)
  }

  func load_data(_ urlString:String) {
    let url = URL(string: urlString)!
    let session = URLSession.shared
    let request = NSMutableURLRequest(url: url)
//    request.HTTPMethod = "POST"
//    request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringCacheData
//    let paramString = ""
//    request.HTTPBody = paramString.dataUsingEncoding(NSUTF8StringEncoding)
    let task = session.dataTask(with: request as URLRequest, completionHandler: {
      (data, response, error) in guard let _:Data = data, let _:URLResponse = response, error == nil else {
          print("error")
          return
      }
      let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
      print(dataString!)
    }) 
    task.resume()
  }

}

