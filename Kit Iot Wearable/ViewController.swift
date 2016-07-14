//
//  ViewController.swift
//  Kit Iot Wearable
//
//  Created by Vitor Leal on 4/1/15.
//  Copyright (c) 2015 Telefonica VIVO. All rights reserved.
//
import UIKit
import CoreBluetooth


class ViewController: UIViewController {

    // IB Outlets
    @IBOutlet weak var accelerometrX: UILabel!
    @IBOutlet weak var accelerometrY: UILabel!
    @IBOutlet weak var accelerometrZ: UILabel!
    @IBOutlet weak var luminosityValue: UILabel!
    @IBOutlet weak var temperatureValue: UILabel!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var loader: UIActivityIndicatorView!
    @IBOutlet weak var redSlider: UISlider!
    @IBOutlet weak var greenSlider: UISlider!
    @IBOutlet weak var blueSlider: UISlider!
    
    let blueColor = UIColor(red: 51/255, green: 73/255, blue: 96/255, alpha: 1.0)
    var timer: NSTimer?
    
    // MARK: - View did load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Notification center observers
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("connectionChanged:"),
            name: WearableServiceStatusNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("characteristicNewValue:"),
            name: WearableCharacteristicNewValue, object: nil)
        
        //Wearable instance
        wearable
    }
    
    
    // MARK: - On characteristic new value update interface
    func characteristicNewValue(notification: NSNotification) {
        
        let userInfo = notification.userInfo as! Dictionary<String, NSString>
        let value = userInfo["value"]!
        let val = value.substringFromIndex(3).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        let sensor = value.substringWithRange(NSMakeRange(0, 3))
        
        dispatch_async(dispatch_get_main_queue()) {
            switch sensor {
                case "#TE":
                    self.temperatureValue.text = "\(val)º"
                    break
            
                case "#LI":
                    self.luminosityValue.text = val
                    break
            
                case "#AX":
                    self.accelerometrX.text = val
                    break
            
                case "#AY":
                    self.accelerometrY.text = val
                    break
            
                case "#AZ":
                    self.accelerometrZ.text = val
                    break
            
                default:

                    break
            }
        }
    }
    
    
    // MARK: - On connection change
    func connectionChanged(notification: NSNotification) {
        let userInfo = notification.userInfo as! [String: Bool]
        
        dispatch_async(dispatch_get_main_queue(), {
            
            if let isConnected: Bool = userInfo["isConnected"] {
                
                if isConnected {
                    self.wearableConnected()
                    
                } else {
                    self.wearableDisconnected()
                }
            }
        });
    }
    
    
    // MARK: - On wearable disconnection
    func wearableDisconnected() {
        // Change the title
        self.navigationController!.navigationBar.topItem?.title = "Buscando Wearable"
        // Change naviagation color
        self.navigationController!.navigationBar.barTintColor = UIColor.grayColor()
        // Show loader
        self.loader.hidden = false
        // Show content view
        self.contentView.hidden = true
        // Cancel timer
        self.timer!.invalidate()
    }

    
    // MARK: - On wearable connection
    func wearableConnected() {
        //Change the title
        self.navigationController!.navigationBar.topItem?.title = "Conectado"
        //Change naviagation color
        self.navigationController!.navigationBar.barTintColor = self.blueColor
        // Hide loader
        self.loader.hidden = true
        // Show content view
        self.contentView.hidden = false
        
        // Get the sensor values
        self.getSensorValues()
        
        // Start timer
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("getSensorValues"), userInfo: nil, repeats: true)
    }
    
    
    // MARK: - Deinit and memory warning
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: WearableServiceStatusNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: WearableCharacteristicNewValue, object: nil)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Slider change
    @IBAction func sliderChange(slider: UISlider) {
        if let wearableService = wearable.wearableService {
            if (slider.isEqual(redSlider)) {
                wearableService.sendCommand(String(format: "#LR0%.0f\n\r", slider.value))
            }
            
            if (slider.isEqual(greenSlider)) {
                wearableService.sendCommand(String(format: "#LG0%.0f\n\r", slider.value))
            }
            
            if (slider.isEqual(blueSlider)) {
                wearableService.sendCommand(String(format: "#LB0%.0f\n\r", slider.value))
            }
        }
    }
    
    
    // MARK: - Button click
    @IBAction func ledOFF(sender: AnyObject) {
        if let wearableService = wearable.wearableService {
            wearableService.sendCommand("#LL0000\n\r")
            
            redSlider.setValue(0, animated: true)
            greenSlider.setValue(0, animated: true)
            blueSlider.setValue(0, animated: true)
        }
    }
    
    
    // MARK: - Get {light,temperature,accelerometer} value
    func getSensorValues() {
        if let wearableService = wearable.wearableService {
            wearableService.sendCommand("#TE0000\n\r")
             wearableService.sendCommand("#LI0000\n\r")
            wearableService.sendCommand("#AC0003\n\r")
        }
    }
    
    
    // MARK: - Melody buttons click
    @IBAction func playMelody(sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
            case 0:
                if let wearableService = wearable.wearableService {
                    wearableService.sendCommand("#PM1234\n\r")
                }
            
            case 1:
                if let wearableService = wearable.wearableService {
                    wearableService.sendCommand("#PM6789\n\r")
                }
            
            case 2:
                if let wearableService = wearable.wearableService {
                    wearableService.sendCommand("#PM4567\n\r")
                }

            default:
                break;
        }
    }
}

