//
//  FileExporter.swift
//  BLEStudy
//
//  Created by mio kato on 2022/04/28.
//

import Foundation


class FileExporter {
    static func export(fileName: String, body: String) {
        do {
            let fileManager = FileManager.default
            let docs = try fileManager.url(for: .documentDirectory,
                                           in: .userDomainMask,
                                           appropriateFor: nil, create: false)
            let path = docs.appendingPathComponent("\(fileName).csv")
            let data = body.data(using: .utf8)

            fileManager.createFile(atPath: path.path,
                                   contents: data, attributes: nil)
        } catch {
            print(error)
        }
    }
}
