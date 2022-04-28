//
//  Utils.swift
//  BLEStudy
//
//  Created by mio kato on 2022/04/15.
//

import Foundation

extension String {
    var prefix8: String {
        if self.count < 8 {
            return self
        }
        
        return String(self[...self.index(self.startIndex, offsetBy: 7)])
    }
}

extension DateFormatter {
    static var basic: DateFormatter {
        let f = DateFormatter()
        f.timeStyle = .medium
        f.dateStyle = .short
        f.locale = Locale(identifier: "ja_JP")
        return f
    }
    
    static var fileName: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd_HHmmss"
        return f
    }
}
