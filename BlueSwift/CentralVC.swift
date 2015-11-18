//
//  CentralVC.swift
//  BlueSwift
//
//  Created by Yang on 2015/11/17.
//  Copyright © 2015年 Yang. All rights reserved.
//

import UIKit
import CoreBluetooth

let serviceUUID = "FB694B90-F49E-4597-8306-171BBA78F846"
let characteristicUUID = "EB6727C4-F184-497A-A656-76B0CDAC633A"

extension CBPeripheral
{
    func getName() -> String
    {
        return (self.name != nil) ? self.name! : "Unknow"
    }
}

class CentralVC: UIViewController
{
    @IBOutlet var tableView: UITableView!
    @IBOutlet var textView: UITextView!
    
    var centralManager : CBCentralManager!
    var discoverPeripherals : [CBPeripheral] = []
    var restorePeripherals : [CBPeripheral] = []
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let options = [ CBCentralManagerOptionRestoreIdentifierKey: "keyForRestore" ]
        centralManager = CBCentralManager(delegate: self, queue: nil ,options: options)
        
        if let date = NSUserDefaults.standardUserDefaults().objectForKey("relaunchApp")
        {
            self.appendLog("Relaunch App At [" + date.description + "]" , push: false)
        }
        
        if let identify = NSUserDefaults.standardUserDefaults().stringForKey("BluetoothCentralsKey")
        {
            self.appendLog("Restore Identifier Key [" + identify + "]" , push: false)
        }
        
        refreshControl.addTarget(self, action: "startScan", forControlEvents: .ValueChanged)
        self.tableView.addSubview(refreshControl)
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        super.viewWillDisappear(animated)
        self.centralManager.stopScan()
    }
    
    @IBAction func killApp(sender: UIBarButtonItem)
    {
        kill(getpid(), SIGKILL)
    }

    func appendLog(text : String! , push needPush : Bool = true)
    {
        self.textView.text = self.textView.text + text + "\n"
        self.textView.scrollRangeToVisible(NSMakeRange(self.textView.text.utf16.count , 0))
        
        if UIApplication.sharedApplication().applicationState == .Background && needPush
        {
            let alert = UILocalNotification()
            alert.alertBody = text
            alert.fireDate = NSDate(timeIntervalSinceNow: 1)
            UIApplication.sharedApplication().scheduleLocalNotification(alert);
        }
    }
    
    func startScan()
    {
        discoverPeripherals = []
        self.tableView.reloadData()
        
        self.centralManager.scanForPeripheralsWithServices([CBUUID(string: serviceUUID)], options: nil)
        self.appendLog("Scanning......" , push: false)
        
        dispatch_after( dispatch_time(DISPATCH_TIME_NOW, Int64(5 * Double(NSEC_PER_SEC))) , dispatch_get_main_queue(), {
            
            self.appendLog("Stop Scan" , push: false)
            
            self.centralManager.stopScan()
            self.refreshControl.endRefreshing()
        })
    }
}

extension CentralVC : CBCentralManagerDelegate , CBPeripheralDelegate
{
    // MARK: - Central
    
    func centralManagerDidUpdateState(central: CBCentralManager)
    {
        if central.state == .PoweredOn
        {
            self.refreshControl.beginRefreshing()
            self.tableView.setContentOffset(CGPointMake(0, -self.refreshControl.frame.size.height), animated: false)
            self.startScan()
            
            for peripheral in self.restorePeripherals
            {
                self.centralManager.connectPeripheral(peripheral, options: nil)
            }
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber)
    {
        self.appendLog("Did discover " + peripheral.getName() , push: false)
        if !discoverPeripherals.contains(peripheral)
        {
            discoverPeripherals.append(peripheral)
            self.tableView.reloadData()
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral)
    {
        self.appendLog("Did connect to " + peripheral.getName() , push: false)
        self.appendLog("UUID : " + peripheral.identifier.UUIDString, push: false)
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?)
    {
        self.appendLog("Did disconnect to " + peripheral.getName() , push: false)
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?)
    {
        self.appendLog("Did fail to Connect" + peripheral.getName() , push: false)
    }
    
    // MARK: - Peripheral
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?)
    {
        for service in peripheral.services!
        {
            peripheral.discoverCharacteristics(nil, forService: service)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?)
    {
        for c in service.characteristics!
        {
            peripheral.setNotifyValue(true, forCharacteristic: c)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?)
    {
        if let text = String(data: characteristic.value!, encoding: NSUTF8StringEncoding)
        {
            self.appendLog(">>> " + text)
        }
    }
    
    func centralManager(central: CBCentralManager, willRestoreState dict: [String : AnyObject])
    {
        if let reconnectPeripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral]
        {
            //Don't connect peripheral here. Because central still not ready to connect
            self.restorePeripherals = reconnectPeripherals
        }
    }
}


extension CentralVC : UITableViewDelegate , UITableViewDataSource
{
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return discoverPeripherals.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        
        let peripheral = discoverPeripherals[indexPath.row]
        cell.textLabel?.text = peripheral.getName()
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let peripheral = discoverPeripherals[indexPath.row]
        self.centralManager.connectPeripheral(peripheral, options: nil)
        self.appendLog("Connecting to " + peripheral.getName() , push: false)
    }
}