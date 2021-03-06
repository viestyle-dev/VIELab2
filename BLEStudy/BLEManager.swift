//
//  BLEManager.swift
//  BLEStudy
//
//  Created by mio kato on 2022/04/12.
//

import Foundation

class BLEManager {
    static var shared = BLEManager()
    
    var bleDevice = BLEDevice.shared
    
    // 選択したデバイス
    var selectedDeviceID: String?
    // 発見したデバイスのリスト
    var discoverDevices = [String]()
    
    var isScanning: Bool = false
    var isConnected: Bool = false
    var isStarted: Bool = false
    
    
    func clear() {
        discoverDevices.removeAll()
        selectedDeviceID = nil
    }
    
    func update(name: String, uuidStr: String) {
        for discoverDeivice in discoverDevices {
            if discoverDeivice == uuidStr {
                return
            }
        }
        discoverDevices.append(uuidStr)
    }
    
    func selectDevice(deviceID: String) {
        selectedDeviceID = deviceID
    }
    
    // MARK: - BLE action
    // スキャン開始
    func scan() {
        discoverDevices.removeAll()
        
        bleDevice.scanDevice()
    }
    
    // スキャン停止
    func stopScan() {
        bleDevice.stopScanDevice()
    }
    
    // 接続をトグル
    func toggleConnect() {
        if isConnected {
            disconnect()
        } else {
            connect()
        }
    }
    
    /// 接続
    func connect() {
        if let deviceID = selectedDeviceID  {
            bleDevice.connect(deviceID)
            UserDefaults.standard.set(deviceID, forKey: "lastConnectedDeviceID")
        } else {
            if let lastConnectedDeviceID = UserDefaults.standard.string(forKey: "lastConnectedDeviceID") {
                bleDevice.connect(lastConnectedDeviceID)
                selectedDeviceID = lastConnectedDeviceID
            }
        }
    }
    
    // 接続解除
    func disconnect() {
        bleDevice.disconnectDevice()
    }
    
    func toggleStart() -> Bool {
        if isStarted {
            stop()
            isStarted = false
        } else {
            start()
            isStarted = true
        }
        return isStarted
    }
    
    // EEG検出スタート
    func start() {
        bleDevice.start()
    }
    
    // EEG検出停止
    func stop() {
        bleDevice.stop()
    }
}
