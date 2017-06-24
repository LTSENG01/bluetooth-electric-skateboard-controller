//
//  ViewController.swift
//  BluetoothArduino
//
//  Created by Larry on 6/22/17.
//  Copyright © 2017 Larry Tseng. All rights reserved.
//

import UIKit
import CoreMotion

enum Direction {
    case Forward, Backward
}

class ViewController: UIViewController, BTManagerDelegate {
    
    let btManager: BTManager = BTManager()
    let motionManager: CMMotionManager = CMMotionManager()
    var timer: Timer!
    
    // MARK: - Speed Slider
    
    @IBOutlet weak var speedSlider: UISlider!
    
    var lastSpeed: Int8 = 0
    @IBAction func sliderValueChange(_ sender: Any) {
        let currentSpeed = Int8(speedSlider.value)
        if currentSpeed != lastSpeed {
            setSpeed(speed: currentSpeed)
        }
        lastSpeed = currentSpeed
    }
    
    // MARK: - Motion Mode - refers to the pitch of the device
    
    var motionMode: Bool = false
    
    @IBAction func toggleMotionMode(_ sender: Any) {
        motionMode = !motionMode
        
        if motionMode {
            print("Starting Device Motion mode!")
            motionManager.startDeviceMotionUpdates()
            readMotionOutput()
        }
        
        if !motionMode {
            motionManager.stopDeviceMotionUpdates()
        }
    }
    
    @IBOutlet weak var motionStatus: UILabel!
    
    @objc func readMotionOutput() {
        if let data = motionManager.deviceMotion?.attitude.pitch {
            print(data)
        }
    }
    
    // MARK: - Buttons
    
    @IBAction func emergencyStopButton(_ sender: UIButton) {
        stop()
    }
    
    @IBOutlet weak var switchDirectionButton: UIButton!
    
    @IBAction func switchDirectionButton(_ sender: Any) {
        if direction == .Forward {
            setSpeed(speed: 101)
            stop()
            directionLabel.text = "Backwards"
            switchDirectionButton.backgroundColor = .red
            direction = .Backward
        } else if direction == .Backward {
            setSpeed(speed: 102)
            stop()
            directionLabel.text = "Forwards"
            switchDirectionButton.backgroundColor = .green
            direction = .Forward
        }
    }
    
    @IBAction func connectButton(_ sender: Any) {
        btManager.startScanning()
    }
    
    @IBAction func disconnectButton(_ sender: Any) {
        btManager.cancelScanning()
    }
    
    // MARK: - Status Message
    
    @IBOutlet weak var statusMessage: UITextView!
    
    @IBAction func clearStatusMessageButton(_ sender: Any) {
        statusMessage.text = ""
    }
    
    @IBOutlet weak var speedLabel: UILabel!
    
    @IBOutlet weak var directionLabel: UILabel!
    
    var direction: Direction = Direction.Forward
    
    override func viewDidLoad() {
        btManager.delegate = self
        motionManager.deviceMotionUpdateInterval = 0.5
        btConnectionIsNotReady()
        speedLabel.text = "0";
        
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(readMotionOutput), userInfo: nil, repeats: true)
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - BTManagerDelegate
    
    func updateStatusMessage(message: String) {
        statusMessage.insertText(message + "\n")
        print(message)
    }
    
    func btConnectionIsReady() {
        speedSlider.isEnabled = true
        switchDirectionButton.isEnabled = true
    }
    
    func btConnectionIsNotReady() {
        speedSlider.isEnabled = false
        switchDirectionButton.isEnabled = false
    }
    
    // MARK: - Methods
    
    func setSpeed(speed: Int8) {
        if btManager.arduinoPeripheral != nil && btManager.arduinoCharacteristic != nil {
            btManager.sendData(data: speed)
        }
        speedLabel.text = "\(speed)"
    }
    
    func stop() {
        setSpeed(speed: 0)
        speedSlider.setValue(0, animated: false)
    }
}
