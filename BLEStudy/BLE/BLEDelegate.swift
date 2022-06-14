//
//  BLEDelegate.swift
//  CoreBluetoothStudy
//
//  Created by mio kato on 2022/04/21.
//

import Foundation
import CoreBluetooth

@objc public protocol BLEDelegate {
    func deviceFound(devName: String, mfgID: String, deviceID: String)
    func didConnect()
    func didDisconnect()
    func eegSampleLeft(_ left: Int32, right: Int32)
    func sensorStatus(_ status: Int32)
    func battery(_ percent: Int32)
    @objc optional func centralManagerDidUpdateState(_ central: CBCentralManager)
    @objc optional func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?)
}
