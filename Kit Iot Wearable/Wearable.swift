//
//  Wearable.swift
//  kit-iot-wearable
//
//  Created by Vitor Leal on 4/1/15.
//  Copyright (c) 2015 Telefonica VIVO. All rights reserved.
//
import Foundation
import CoreBluetooth

// Create new instance of the wearable class
let wearable = Wearable()


class Wearable: NSObject, CBCentralManagerDelegate {
    
    private var centralManager: CBCentralManager?
    private var peripheralBLE: CBPeripheral?
    private let defaults = NSUserDefaults.standardUserDefaults()
    
    override init() {
        super.init()
        
        let centralQueue = dispatch_queue_create("com.wearable", DISPATCH_QUEUE_SERIAL)
        centralManager = CBCentralManager(delegate: self, queue: centralQueue)
        
        // When user update the user default connect to the new wearable name
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "conectWithNewWearable", name: NSUserDefaultsDidChangeNotification, object: nil)
    }
    
    
    // MARK: - Start scanning for the wearable
    func startScanning() {
        if let central = centralManager {
            central.scanForPeripheralsWithServices([ServiceUUID], options: nil)
        }
    }
    
    
    // MARK: - Discover wearable services
    var wearableService: WearableService? {
        didSet {
            if let service = self.wearableService {
                service.startDiscoveringServices()
            }
        }
    }
    
    
    // MARK: - Disconnect and start scanning for the wearable
    func conectWithNewWearable() {
        self.clearDevices()
        self.startScanning()
    }
    
    
    // MARK: - Discover peripheral
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        
        if ((peripheral == nil) || (peripheral.name == nil) || (peripheral.name == "")) {
            return
        }
        
        // If is the write peripheral connect using the settings bundle wearable name
        if ((self.peripheralBLE == nil) || (self.peripheralBLE?.state == CBPeripheralState.Disconnected)) {
            var wearableName = defaults.stringForKey("wearableName")
            
            if (peripheral.name == wearableName) {
                self.peripheralBLE = peripheral
                self.wearableService = nil
                
                central.connectPeripheral(peripheral, options: nil)
            }
        }
    }
    
    
    // MARK: - Did connect to the peripheral
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        
        if (peripheral == nil) {
            return;
        }
        
        // Create new instance of the service class
        if (peripheral == self.peripheralBLE) {
            self.wearableService = WearableService(initWithPeripheral: peripheral)
        }
        
        // Stop scan for the wearable
        central.stopScan()
    }
    
    
    // MARK: - Did disconnect from the peripheral
    func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        
        if (peripheral == nil) {
            return;
        }
        
        //  Clear service and peripheral
        if (peripheral == self.peripheralBLE) {
            self.clearDevices()
        }
        
        // Start scanning for the wearables
        self.startScanning()
    }
    
    
    // MARK: - Private - clear service and peripheral
    func clearDevices() {
        self.wearableService = nil
        self.peripheralBLE = nil
    }
    
    
    // MARK: - Central Manager update satate
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        switch (central.state) {
            case CBCentralManagerState.PoweredOff:
                self.clearDevices()
            
            case CBCentralManagerState.Unauthorized:
                break
            
            case CBCentralManagerState.Unknown:
                break
            
            case CBCentralManagerState.PoweredOn:
                self.startScanning()
            
            case CBCentralManagerState.Resetting:
                self.clearDevices()
            
            case CBCentralManagerState.Unsupported:
                break
            
            default:
                break
        }
    }
}