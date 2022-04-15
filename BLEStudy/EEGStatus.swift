//
//  EEGStatus.swift
//  CoreBluetoothStudy
//
//  Created by mio kato on 2022/04/14.
//

import Foundation

enum EEGStatus: Int {
    case connected = 0
    case leftNotConnected = 1
    case rightNotConnected = 2
    case notConnected = 3
    
    static func get(rawValue: UInt8) -> Self {
        switch rawValue {
        case 0:
            return EEGStatus.connected
        case 1:
            return EEGStatus.leftNotConnected
        case 2:
            return EEGStatus.rightNotConnected
        case 3:
            return EEGStatus.notConnected
        default:
            fatalError("Unknown value")
        }
    }
    
    var description: String {
        switch self {
        case .notConnected:
            return "x [Both]"
        case .leftNotConnected:
            return "x [Left]"
        case .rightNotConnected:
            return "x [Right]"
        case .connected:
            return "Connected"
        }
    }
}
