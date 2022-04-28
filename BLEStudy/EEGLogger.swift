//
//  EEGLogger.swift
//  BLEStudy
//
//  Created by mio kato on 2022/04/28.
//

import Foundation

class EEGLogger {
    
    private var eegValues: [EEGValue]
    var isRecord: Bool = false
    
    init() {
        eegValues = [EEGValue]()
    }
    
    /// 開始
    func startRecording() {
        clear()
        isRecord = true
    }
    
    /// 停止
    func stopRecording() {
        if eegValues.count > 0 {
            let text = getCSVText()
            let fileName = DateFormatter.fileName.string(from: Date())
            FileExporter.export(fileName: fileName, body: text)
        }
        isRecord = false
        clear()
    }
    
    /// 録音中はデータを追加する
    func update(eegValue: EEGValue) {
        guard isRecord else {
            return
        }
        eegValues.append(eegValue)
    }
    
    /// 全部削除
    private func clear() {
        eegValues.removeAll()
    }
    
    /// CSVフォーマットのテキストを作成
    private func getCSVText() -> String {
        var text = ""
        let header = "left,right,label\n"
        text += header
        for eegValue in eegValues {
            text += String(eegValue.left)
            text += ","
            text += String(eegValue.right)
            text += ","
            text += String(eegValue.label.rawValue)
            text += "\n"
        }
        
        return text
    }
    
}
