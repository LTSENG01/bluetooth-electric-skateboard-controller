//
//  BTManager.swift
//  BluetoothArduino
//
//  Created by Larry on 6/23/17.
//  Copyright © 2017 Larry Tseng. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit

protocol BTManagerDelegate {
    func updateStatusMessage(message: String)
    func btConnectionIsReady()
    func btConnectionIsNotReady()
}

class BTManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var delegate: BTManagerDelegate? = nil
    
    var centralManager: CBCentralManager!
    var arduinoPeripheral: CBPeripheral?
    var arduinoCharacteristic: CBCharacteristic?
    
    let arduinoUUID: CBUUID = CBUUID(string: "4651FAB4-8C39-6212-40EE-91B6C0696FEC")
    let serviceUUID: CBUUID = CBUUID(string: "FFE0")
    let characteristicUUID: CBUUID = CBUUID(string: "FFE1")
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Methods
    
    func sendData(data: Int8) {
        var data = data
        let packedData: Data = Data(bytes: &data, count: 1)
        arduinoPeripheral?.writeValue(packedData, for: arduinoCharacteristic!, type: .withoutResponse)
    }
    
    func startScanning() {
        if (!centralManager.isScanning || arduinoPeripheral != nil) {
            if (centralManager.state == .poweredOn) {
                centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
                delegate?.updateStatusMessage(message: "Scanning...")
            }
        }
    }
    
    func cancelScanning() {
        if arduinoPeripheral != nil {
            centralManager.cancelPeripheralConnection(arduinoPeripheral!)
        }
        if centralManager.isScanning {
            centralManager.stopScan()
        }
        delegate?.updateStatusMessage(message: "**Canceled scanning.**")
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        var message: String;
        
        switch central.state {
        case .poweredOff:
            message = "Turn on Bluetooth!"
            break
        case .resetting:
            message = "Resetting..."
            break
        case .unauthorized:
            message = "Unauthorized to use BLE."
            break
        case .unknown:
            message = "Something went wrong with BLE."
            break
        case .unsupported:
            message = "BLE not supported."
            break
        case .poweredOn:
            message = "Ready to go! Scanning..."
            central.scanForPeripherals(withServices: [serviceUUID], options: nil)
            break
        @unknown default:
            fatalError()
        }
        delegate?.updateStatusMessage(message: message)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        delegate?.updateStatusMessage(message: "Found: \(peripheral.name!)")
        if let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            if peripheralName == "BT05" {
                delegate?.updateStatusMessage(message: "Found \(peripheralName)! Connecting... RSSI: \(RSSI)")
                
                arduinoPeripheral = peripheral
                arduinoPeripheral!.delegate = self
                
                central.connect(arduinoPeripheral!, options: nil)
                
                if central.isScanning {
                    central.stopScan()
                }
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        delegate?.updateStatusMessage(message: "\(peripheral.name!) connected!")
        UIApplication.shared.isIdleTimerDisabled = true;
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        delegate?.updateStatusMessage(message: "**Error: \(peripheral.name!) disconnected!**")
        arduinoPeripheral = nil
        arduinoCharacteristic = nil
        UIApplication.shared.isIdleTimerDisabled = false;
        delegate?.btConnectionIsNotReady()
        if error != nil {
            delegate?.updateStatusMessage(message: "*Error: \(error!.localizedDescription)")
        }
    }
    
    // MARK: - CBPeripheral
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if error != nil {
            delegate?.updateStatusMessage(message: "**Error: \(error!.localizedDescription).**")
        }
        
        delegate?.updateStatusMessage(message: "Found \(peripheral.name!) services.")
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics([characteristicUUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if error != nil {
            delegate?.updateStatusMessage(message: "**Error: \(error!.localizedDescription).**")
        }
        
        delegate?.updateStatusMessage(message: "Found \(peripheral.name!) characteristics.")
        
        for characteristic in service.characteristics! {
            if characteristic.uuid == characteristicUUID {
                arduinoCharacteristic = characteristic
                delegate?.updateStatusMessage(message: "All set!")
                delegate?.btConnectionIsReady()
            }
        }
    }
    
}
