//
//  ViewController.swift
//  iBeaconBackgroundMode
//
//  Created by wwwins on 2016/4/20.
//  Copyright © 2016年 wwwins. All rights reserved.
//

import UIKit
import CoreLocation
import CoreBluetooth

class ViewController: UIViewController, CLLocationManagerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate {

  private var regionState:[String:CLRegionState] = [String:CLRegionState]()
  private let proximityUUID = [
    NSUUID(UUIDString: "B5B182C7-EAB1-4988-AA99-B5C1517008D9"),
//    NSUUID(UUIDString: "B5B182C7-EAB1-4988-AA99-B5C1517008D8"),
//    NSUUID(UUIDString: "B5B182C7-EAB1-4988-AA99-B5C1517008D7")
  ]
  private var locationManager:CLLocationManager?
  //private var myRegion:CLBeaconRegion?
  private var myRegions:NSMutableArray = []

  private var centralManager:CBCentralManager?
  private var connectedPeripheral:CBPeripheral?
  private var discoveredPeripheral:CBPeripheral?


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

    // BLE
    centralManager = CBCentralManager(delegate: self, queue: nil)
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

  // CBCentralManagerDelegate
  func centralManagerDidUpdateState(central: CBCentralManager) {
    print("central state:\(central.state.description)")
    if central.state != CBCentralManagerState.PoweredOn {
      return;
    }
    //print("Start scan")
    //startScanning()

  }

  func startScanning() {
    print("Start scan")
    centralManager?.scanForPeripheralsWithServices([hm10ServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey:NSNumber(bool: false)])

  }

  func stopScanning() {
    print("Stop scan")
    centralManager?.stopScan()

  }

  func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
    if RSSI.integerValue > 0 {
      print("Device not at correct range:",RSSI)
      return
    }

    // 第五步: 找出符合的裝置進行連線
    if (peripheral.identifier.UUIDString == DEVICE_IDENTIFIER_UUID) {
      if (discoveredPeripheral != peripheral) {
        print("Start connect peripheral")
        discoveredPeripheral = peripheral
        centralManager?.connectPeripheral(peripheral, options: nil)
      }
    }
    /*
    centralManager?.connectPeripheral(peripheral, options: [
      CBCentralManagerRestoredStatePeripheralsKey:NSNumber(bool: true),
      CBCentralManagerRestoredStateScanServicesKey:NSNumber(bool: true),
      CBCentralManagerRestoredStateScanOptionsKey:NSNumber(bool: true)
      ])
    */

  }

  func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
    print("didConnectPeripheral:",peripheral)
    // 連線成功後該裝置訊號就不會再觸發 didDiscoverPeripheral
    // 如果只有單一藍芽裝置，即可以停止掃描
    //stopScanning()

    if (connectedPeripheral == peripheral) {
      return
    }
    // 第七步: 設定連線裝置 delegate
    // Make sure we get the discovery callbacks
    peripheral.delegate = self

    // 第八步: 掃描此連線裝置有哪些服務
    // Search only for services that match our UUID
    peripheral.discoverServices([hm10ServiceUUID])
    //peripheral.discoverServices(nil)

    // 第九步: 讀取 RSSI 值(非同步)
    peripheral.readRSSI()

  }


  func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
    print("結束連線")

    connectedPeripheral = nil
    discoveredPeripheral = nil

  }

  func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
    print("連線失敗")

    connectedPeripheral = nil
    discoveredPeripheral = nil
  }

  func centralManager(central: CBCentralManager, willRestoreState dict: [String : AnyObject]) {
    print("Restore")
  }

  // 第十步: 傳回連線裝置 RSSI 值
  func peripheral(peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: NSError?) {
    // 更新
    //savePeripheral(peripheral, rssi: RSSI)
  }

  // 第十一步: 發現裝置服務會觸發此函式
  func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
    if let err = error {
      print("Discover Services error:",err)
    }

    // 第十二步: 掃描 Characteristics
    print("p Services:",peripheral.services)
    for service in peripheral.services as [CBService]! {
      if (service.UUID == hm10ServiceUUID) {
        print("discover HM10")
        peripheral.discoverCharacteristics([hm10CharacteristicUUID], forService: service)
      }
    }

  }

  // 第十三步: 發現 Characteristics
  func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
    if let err = error {
      print("Discover Characteristics For Service error:",err)

    }

    // 比對 characteristics
    for characteristic in service.characteristics as [CBCharacteristic]! {
      if (characteristic.UUID == hm10CharacteristicUUID) {
        // 第十四步: 回應需要訂閱
        print("Set Notify")
        peripheral.setNotifyValue(true, forCharacteristic: characteristic)
      }
    }

  }

  // 第十五步: 處理訂閱後傳回來的資料
  func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
    if let error = error {
      print("Error discovering services: \(error.localizedDescription)")
      return
    }

    print("characteristic:",characteristic)
    if let stringFromData = String(data: characteristic.value!, encoding: NSUTF8StringEncoding) {
      print("Received: \(stringFromData)")
      // 處理回傳資料
      // 取消訂閱
      //peripheral.setNotifyValue(false, forCharacteristic: characteristic)
      // 取消連線
      //centralManager?.cancelPeripheralConnection(peripheral)
    }
  }

  // 第十六步: 處理裝置訂閱狀態改變
  func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
    print("Error changing notification state: \(error?.localizedDescription)")
    
  }


  // iBeacon
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
    if (regionState.indexForKey(region.identifier) != nil) {
      if (regionState[region.identifier] != state) {
        regionState[region.identifier] = state
        handleRegionActions(region, msg: msg)
      }
      startScanning()
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
  func handleRegionActions(region:CLRegion, msg:String) {
    let idString = region.identifier.substringFromIndex(region.identifier.startIndex.advancedBy(34))
    sendNotification(idString + ":" + msg)
    load_data("http://192.168.200.103:8000/index.html?"+String(arc4random()))
  }

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

