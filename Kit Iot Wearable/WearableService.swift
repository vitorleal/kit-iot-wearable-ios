//
//  WearableService.swift
//  kit-iot-wearable
//
//  Created by Vitor Leal on 4/1/15.
//  Copyright (c) 2015 Telefonica VIVO. All rights reserved.
//
import Foundation
import CoreBluetooth


let ServiceUUID = CBUUID(string: "FFE0")
let CharacteristicUIID = CBUUID(string: "FFE1")
let WearableServiceStatusNotification = "WearableServiceChangedStatusNotification"
let WearableCharacteristicNewValue = "WearableCharacteristicNewValue"


class WearableService: NSObject, CBPeripheralDelegate {
    var peripheral: CBPeripheral?
    var peripheralCharacteristic: CBCharacteristic?
    
    init(initWithPeripheral peripheral: CBPeripheral) {
        super.init()

        self.peripheral = peripheral
        self.peripheral?.delegate = self
    }
    
    deinit {
        self.reset()
    }
    
    
    // MARK: - Start discovering services
    func startDiscoveringServices() {
        self.peripheral?.discoverServices([ServiceUUID])
    }
    
    
    // MARK: - Reset
    func reset() {
        if peripheral != nil {
            peripheral = nil
        }
        
        self.sendWearableServiceStatusNotification(false)
    }
    
    
    // MARK: - Look for bluetooth with the service FFEO
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        let uuidsForBTService: [CBUUID] = [CharacteristicUIID]
        
        if (peripheral != self.peripheral || error != nil) {
            return
        }
        
        if ((peripheral.services == nil) || (peripheral.services.count == 0)) {
            return
        }
        
        // Find characteristics
        for service in peripheral.services {
            if service.UUID == ServiceUUID {
                peripheral.discoverCharacteristics(uuidsForBTService, forService: service as! CBService)
            }
        }
    }
    
    
    // MARK: - Look for the bluetooth characteristics
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        if (peripheral != self.peripheral || error != nil) {
            return
        }
        
        for characteristic in service.characteristics {
            if characteristic.UUID == CharacteristicUIID {
                self.peripheralCharacteristic = (characteristic as! CBCharacteristic)
                peripheral.setNotifyValue(true, forCharacteristic: characteristic as! CBCharacteristic)
                
                self.sendWearableServiceStatusNotification(true)
            }
        }
    }
    
    
    // MARK: - Did update the characteristic value
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        
        if ((error) != nil) {
            println("Error changing notification state: %@", error.description)
        }
        
        if (!characteristic.UUID.isEqual(peripheralCharacteristic?.UUID)) {
            return
        }
        
        var value = NSString(bytes: characteristic.value.bytes, length: characteristic.value.length, encoding: NSUTF8StringEncoding)
        value = value?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        

        if let optionalValue = value {
            self.sendWearableCharacteristicNewValue(optionalValue)
        }
    }
    
    
    // MARK: - Send command
    func sendCommand(command: NSString) {
        let str = NSString(string: command)
        let data = NSData(bytes: str.UTF8String, length: str.length)
        
        self.peripheral?.writeValue(data, forCharacteristic: self.peripheralCharacteristic, type: CBCharacteristicWriteType.WithoutResponse)
    }
    
    
    // MARK: - Send wearable connected notification
    func sendWearableServiceStatusNotification(isBluetoothConnected: Bool) {
        let userInfo = ["isConnected": isBluetoothConnected]

        NSNotificationCenter.defaultCenter().postNotificationName(WearableServiceStatusNotification, object: self, userInfo: userInfo)
    }
    
    
    // MARK: - Send characteristic value
    func sendWearableCharacteristicNewValue(value: NSString) {
        let userInfo = ["value": value]
        
        NSNotificationCenter.defaultCenter().postNotificationName(WearableCharacteristicNewValue, object: self, userInfo: userInfo)
    }
}
