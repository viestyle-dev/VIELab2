//
//  BLEDevice.swift
//  CoreBluetoothStudy
//
//  Created by mio kato on 2022/04/11.
//

import Foundation
import CoreBluetooth

/// BLEDevice UUID
fileprivate enum DeviceUUID: String {
    // Device infomation (Read)
    case deviceInfoService = "180A"
    case manufacturerCharacteristic = "2A29"
    case modelNumberCharacteristic = "2A24"
    case serialNumberCharacteristic = "2A25"
    case firmwareRevCharacteristic = "2A26"
    case hardwareRevCharacteristic = "2A27"
    case softwareRevCharacteristic = "2A28"
    // Battery (Read)
    case batteryService = "180F"
    case batteryCharacteristic = "2A19"
    // EEG
    case eegService = "0B79FFF0-1ED1-2840-A9C3-87C6F6186DB3"
    // Write
    case modeCharacteristic = "0B79FFA0-1ED1-2840-A9C3-87C6F6186DB3"
    // Notify
    case statusCharacteristic = "0B79FFB0-1ED1-2840-A9C3-87C6F6186DB3"
    case streamCharacteristic = "0B79FFF6-1ED1-2840-A9C3-87C6F6186DB3"
    
    var uuid: CBUUID {
        return CBUUID(string: self.rawValue)
    }
}


class BLEDevice: NSObject {
    
    static var shared = BLEDevice()
    
    var delegate: BLEDelegate?
    
    private var centralManager: CBCentralManager!
    
    // 接続されたペリフェラル
    private var connectedPeripheral: CBPeripheral?
    
    private var modeCharacteristic: CBCharacteristic?
    private var batteryCharacteristic: CBCharacteristic?
    
    // 脳波検出開始コード
    private let startBytes: [UInt8] = [
        0x77, 0x01, 0x01, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0xfd
    ]
    // 脳波検出停止コード
    private let stopBytes: [UInt8] = [
        0x77, 0x01, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0xfe
    ]
    
    let queue: DispatchQueue
    
    private override init() {
        queue = DispatchQueue(label: "BLEDevice.bleQueue")
        
        super.init()
        
        centralManager = CBCentralManager(delegate: self, queue: queue)
    }
    
    /// スキャン開始
    func scanDevice() {
        let services = [
            DeviceUUID.deviceInfoService.uuid,
            DeviceUUID.batteryService.uuid,
            DeviceUUID.eegService.uuid
        ]
        centralManager.scanForPeripherals(withServices: services, options: nil)
    }
    
    /// スキャン停止
    func stopScanDevice() {
        centralManager.stopScan()
    }
    
    /// 接続
    func connect(_ deviceID: String) {
        guard let lastUUID = UUID(uuidString: deviceID),
              let peripheral = centralManager.retrievePeripherals(withIdentifiers: [lastUUID]).first  else {
            return
        }
        // 強参照が必要なのでプロパティとして保持
        connectedPeripheral = peripheral
        centralManager.connect(peripheral,
                               options: [CBConnectPeripheralOptionEnableTransportBridgingKey : true])
    }
    
    /// 接続を解除
    func disconnectDevice() {
        guard let peripheral = connectedPeripheral else {
            return
        }

        for service in (peripheral.services ?? [] as [CBService]) {
            for characteristic in (service.characteristics ?? [] as [CBCharacteristic]) {
                if characteristic.uuid == DeviceUUID.statusCharacteristic.uuid && characteristic.isNotifying {
                    peripheral.setNotifyValue(false, for: characteristic)
                }
                if characteristic.uuid == DeviceUUID.modeCharacteristic.uuid && characteristic.isNotifying {
                    peripheral.setNotifyValue(false, for: characteristic)
                }
            }
        }
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    /// 脳波の検出を開始
    func start() {
        guard let peripheral = connectedPeripheral,
              let modeCharacteristic = modeCharacteristic else {
            return
        }
        
        peripheral.writeValue(Data(startBytes), for: modeCharacteristic, type: .withResponse)
    }
    
    /// 脳波の検出を停止
    func stop() {
        guard let peripheral = connectedPeripheral,
              let modeCharacteristic = modeCharacteristic else {
            return
        }
        
        peripheral.writeValue(Data(stopBytes), for: modeCharacteristic, type: .withResponse)
    }
}

extension BLEDevice: CBCentralManagerDelegate {
    /// ペリフェラルを発見した
    internal func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let deviceName = peripheral.name else {
            return
        }
        
        delegate?.deviceFound(devName: deviceName, mfgID: peripheral.identifier.uuidString, deviceID: peripheral.identifier.uuidString)
    }
    
    /// ペリフェラルに接続された
    internal func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([
            DeviceUUID.eegService.uuid,
            DeviceUUID.batteryService.uuid,
        ])
        connectedPeripheral = peripheral
        
        delegate?.didConnect()
    }
    
    /// ペリフェラルと接続が解除された
    internal func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        delegate?.didDisconnect()
        
        connectedPeripheral = nil
    }
    
    /// ペリフェラルとの接続に失敗した
    internal func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        delegate?.centralManager?(central, didFailToConnect: peripheral, error: error)
    }
    
    /// ペリフェラルとの接続イベントが発火した
    internal func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {
        delegate?.centralManager?(central, connectionEventDidOccur: event, for: peripheral)
    }
    
    /// 状態が変化した
    internal func centralManagerDidUpdateState(_ central: CBCentralManager) {
        delegate?.centralManagerDidUpdateState?(central)
        switch central.state {
        case .poweredOn:
            break
        case .poweredOff, .resetting, .unauthorized, .unknown, .unsupported:
            break
        default:
            break
        }
    }
}

// MARK: - Peripheral Delegate
extension BLEDevice: CBPeripheralDelegate {
    /// サービスを発見した
    internal func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: %s", error.localizedDescription)
            return
        }
        
        guard let peripheralServices = peripheral.services else { return }
        for service in peripheralServices {
            peripheral.discoverCharacteristics([
                DeviceUUID.modeCharacteristic.uuid,
                DeviceUUID.statusCharacteristic.uuid,
                DeviceUUID.streamCharacteristic.uuid,
                DeviceUUID.batteryCharacteristic.uuid,
            ], for: service)
        }
    }
    
    /// キャラクタリスティックを発見した
    internal func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: %s", error.localizedDescription)
            return
        }
        
        guard let serviceCharacteristics = service.characteristics else { return }
        for characteristic in serviceCharacteristics {
            if characteristic.uuid == DeviceUUID.statusCharacteristic.uuid {
                peripheral.setNotifyValue(true, for: characteristic)
            }
            if characteristic.uuid == DeviceUUID.modeCharacteristic.uuid {
                modeCharacteristic = characteristic
            }
            if characteristic.uuid == DeviceUUID.streamCharacteristic.uuid {
                peripheral.setNotifyValue(true, for: characteristic)
            }
            if characteristic.uuid == DeviceUUID.batteryCharacteristic.uuid {
                connectedPeripheral?.readValue(for: characteristic)
                batteryCharacteristic = characteristic
            }
        }
    }
    
    /// connectした時の呼ばれる
    internal func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }
    }
    
    /// Notify属性の値更新時に呼ばれる(ここの脳波データをハンドリング)
    internal func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }
        
        if characteristic.uuid == DeviceUUID.statusCharacteristic.uuid {
            // ステータス更新
            if let data = characteristic.value {
                handleEEGStatus(data: data)
            }
            
        } else if characteristic.uuid == DeviceUUID.streamCharacteristic.uuid {
            if let data = characteristic.value {
                handleEEGSignal(data: data)
            }
        } else if characteristic.uuid == DeviceUUID.batteryCharacteristic.uuid {
            handleBatteryStatus(characteristic: characteristic)
        }
    }
    
    /// 脳波データを送信
    private func handleEEGSignal(data: Data) {
        let index: UInt8 = data[0]
        let status: UInt8 = data[1]
        let leftData = data[2...41]
        let rightData = data[42...data.count-1]
        let leftValues = leftData.encodedInt16
        let rightValues = rightData.encodedInt16
        
        // 1秒ごとにステータスを送信
        if index == 0 {
            handleSensorStatus(status: Int(status))
            readBattery()
        }
        
        // 600fpsで脳波を送信 (30fps x 20data)
        for (leftValue, rightValue) in zip(leftValues, rightValues) {
            self.delegate?.eegSampleLeft(Int32(leftValue), right: Int32(rightValue))
        }
    }
    
    /// バッテリー容量の読み出し
    private func readBattery() {
        guard let peripheral = connectedPeripheral,
              let batteryCharacteristic = batteryCharacteristic else {
            return
        }
        peripheral.readValue(for: batteryCharacteristic)
    }
    
    /// バッテリー容量の読み出しのコールバック
    private func handleBatteryStatus(characteristic: CBCharacteristic) {
        guard let data = characteristic.value else {
            return
        }
        let batteryPercent = data.encodedUInt8[0]
        delegate?.battery(Int32(batteryPercent))
    }
    
    /// 脳波デバイスの装着ステータスを更新 [0 : ok, 1 : left-x, 2 : right-x, 3 : both-x]
    private func handleSensorStatus(status: Int) {
        delegate?.sensorStatus(Int32(status))
    }
    
    /// EEG取得開始、停止時のハンドリング
    private func handleEEGStatus(data: Data) {
//        print(data.encodedUInt8)
    }
}

fileprivate extension Data {
    /// Data to [UInt8]
    var encodedUInt8: [UInt8] {
        return self.withUnsafeBytes {
            Array($0.bindMemory(to: UInt8.self)).map(UInt8.init(bigEndian:))
        }
    }
    
    /// Data to [Int16]
    var encodedInt16: [Int16] {
        return self.withUnsafeBytes {
            Array($0.bindMemory(to: Int16.self)).map(Int16.init(bigEndian:))
        }
    }
}
