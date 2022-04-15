//
//  ViewController.swift
//  BLEStudy
//
//  Created by mio kato on 2022/03/06.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {
    
    @IBOutlet weak var leftGraphView: GraphView!
    @IBOutlet weak var rightGraphView: GraphView!
    
    @IBOutlet weak var scanBtn: UIButton!
    @IBOutlet weak var connectBtn: UIButton!
    @IBOutlet weak var startBtn: UIButton!
    @IBOutlet weak var clearBtn: UIButton!
    
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var batteryLabel: UILabel!
    @IBOutlet weak var leftValueLabel: UILabel!
    @IBOutlet weak var rightValueLabel: UILabel!
    
    var deviceNameLabelText: String = "DeviceName : " {
        willSet {
            DispatchQueue.main.async {
                self.deviceNameLabel.text = newValue
            }
        }
    }
    var batteryLabelText: String = "Battery : - [%]" {
        willSet {
            DispatchQueue.main.async {
                self.batteryLabel.text = newValue
            }
        }
    }
    var statusLabelText: String = "Status : NotConnected" {
        willSet {
            DispatchQueue.main.async {
                self.statusLabel.text = newValue
            }
        }
    }
    var leftValueLabelInt: Int32 = 0 {
        willSet {
            DispatchQueue.main.async {
                self.leftValueLabel.text = String(newValue)
            }
        }
    }
    var rightValueLabelInt: Int32 = 0 {
        willSet {
            DispatchQueue.main.async {
                self.rightValueLabel.text = String(newValue)
            }
        }
    }
    
    var isConnecting: Bool = false
    
    var rightEEGSamples = [Int32](repeating: 0, count: 600)
    var leftEEGSamples = [Int32](repeating: 0, count: 600)
    
    // MARK: - View
    override func viewDidLoad() {
        super.viewDidLoad()
        
        BLEDevice.sharedInstance().delegate = self
        
        startBtn.isEnabled = false
        clearBtn.isEnabled = false
        
        let rightValues = rightEEGSamples.map { Float($0) }
        let leftValues = leftEEGSamples.map { Float($0) }

        leftGraphView.update(values: leftValues)
        rightGraphView.update(values: rightValues)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("view controller will apppear")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // 自動接続
        BLEManager.shared.connect()
    }
    
    // MARK: - Actions
    /// スキャンボタン押下
    @IBAction func onTapScanBtn(_ sender: UIButton) {
        let vc = DeviceSelectTableViewController()
        vc.presentationController?.delegate = self
        present(vc, animated: true)
        BLEManager.shared.scan()
        
    }
    
    /// ディスコネクトボタン押下
    @IBAction func onTapConnectBtn(_ sender: UIButton) {
        if isConnecting {
            BLEManager.shared.disconnect()
        } else {
            BLEManager.shared.connect()
        }
        print("on tap connect")
    }
    
    /// スタートボタン押下
    @IBAction func onTapStartBtn(_ sender: UIButton) {
        print("on tap start")
        let isStarted = BLEManager.shared.toggleStart()
        if isStarted {
            startBtn.setTitle("Stop", for: .normal)
        } else {
            startBtn.setTitle("Start", for: .normal)
        }
    }
    
    /// ストップボタン押下
    @IBAction func onTapClearBtn(_ sender: UIButton) {
        print("on tap clear")
        BLEManager.shared.clear()
        deviceNameLabelText = "DeviceName : Unknown"
    }
    
    // MARK: - Utils
    /// チャートを更新
    func updateGraph() {
        let leftValues = leftEEGSamples.map { Float($0) }
        let rightValues = rightEEGSamples.map { Float($0) }

        leftGraphView.update(values: leftValues)
        rightGraphView.update(values: rightValues)
    }
    
    /// 左耳のサンプルリストの更新
    func updateLeftSamples(value: Int32) {
        leftEEGSamples.removeFirst()
        leftEEGSamples.append(value)
    }
    
    func updateRightSamples(value: Int32) {
        rightEEGSamples.removeFirst()
        rightEEGSamples.append(value)
    }
}

/// BLEデバイスのコールバック
extension ViewController: BLEDelegate {
    /// アドバタイズしているデバイスを見つける
    func deviceFound(_ devName: String!, mfgID: String!, deviceID: String!) {
        guard let devName = devName,
              let mfgID = mfgID,
              let deviceID = deviceID else {
            return
        }
        
        BLEManager.shared.update(name: devName, uuidStr: deviceID)
        
        print("name \(devName), mfgID: \(mfgID), deviceID: \(deviceID) found")
    }
    
    /// 接続された時のコールバック
    func didConnect() {
        print("did connect")
        BLEManager.shared.stopScan()
        
        isConnecting = true
        if let deviceID = BLEManager.shared.selectedDeviceID {
            let deviceName = "VIE-10004 [\(deviceID.prefix8)]"
            deviceNameLabelText = deviceName
        }
        DispatchQueue.main.async {
            self.connectBtn.setTitle("Disconnect", for: .normal)
            self.scanBtn.isEnabled = false
            self.startBtn.isEnabled = true
        }
    }
    
    /// 接続が切れた時のコールバック
    func didDisconnect() {
        print("did disconnect")
        isConnecting = false
        DispatchQueue.main.async {
            self.connectBtn.setTitle("Connect", for: .normal)
            self.scanBtn.isEnabled = true
            self.startBtn.isEnabled = false
        }
    }
    
    /// 信号を受信
    func eegSampleLeft(_ left: Int32, right: Int32) {
        print("Receive Left: \(left), Right: \(right)")
        let leftRaw = left
        let rightRaw = right
        
        // update eegSamples
        leftValueLabelInt = left
        rightValueLabelInt = right
        updateLeftSamples(value: leftRaw)
        updateRightSamples(value: rightRaw)
        updateGraph()
    }
    
    /// センサーの状態が変化した時のコールバック
    func sensorStatus(_ status: Int32) {
        print("Sensor status : \(status)")
        statusLabelText = "Status : \(EEGStatus.get(rawValue: UInt8(status)).description)"
    }
    
    /// バッテリー
    func battery(_ percent: Int32) {
        print("Battery : \(percent)")
        batteryLabelText = "Battery : \(percent) [%]"
    }
}

extension ViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        print("dismiss")
    }
}
