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
