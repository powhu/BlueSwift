//
//  PeripheralVC.swift
//  BlueSwift
//
//  Created by Yang on 2015/11/17.
//  Copyright © 2015年 Yang. All rights reserved.
//

import UIKit
import CoreBluetooth

class PeripheralVC: UIViewController , UITextViewDelegate
{
    var peripheralManager : CBPeripheralManager!
    var transferCharacteristic : CBMutableCharacteristic!
    @IBOutlet var textView: UITextView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        super.viewWillAppear(animated)
        peripheralManager.stopAdvertising()
    }

    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool
    {
        if text == "\n"
        {
            self.sendData()
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func sendData()
    {
        if let text = self.textView.text.dataUsingEncoding(NSUTF8StringEncoding)
        {
            self.peripheralManager.updateValue(text, forCharacteristic: self.transferCharacteristic, onSubscribedCentrals: nil)
        }
    }
}

extension PeripheralVC : CBPeripheralManagerDelegate
{
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager)
    {
        if peripheral.state == .PoweredOn
        {
            self.transferCharacteristic = CBMutableCharacteristic(type: CBUUID(string: characteristicUUID), properties: .Notify, value: nil, permissions: .Readable)
            
            let transferService = CBMutableService(type: CBUUID(string: serviceUUID), primary: true)
            transferService.characteristics = [self.transferCharacteristic]
            peripheral.addService(transferService)
            
            peripheral.startAdvertising([CBAdvertisementDataServiceUUIDsKey : [CBUUID(string: serviceUUID)] ])
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic)
    {
        self.sendData()
        self.peripheralManager.stopAdvertising()
    }
}