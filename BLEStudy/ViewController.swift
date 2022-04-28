//
//  ViewController.swift
//  BLEStudy
//
//  Created by mio kato on 2022/03/06.
//

import UIKit
import SpriteKit
import F53OSC
import BLEDevicePackage
import Analyze

class ViewController: UIViewController {
    
    @IBOutlet weak var leftGraphView: GraphView!
    @IBOutlet weak var rightGraphView: GraphView!
    
    @IBOutlet weak var scanBtn: UIButton!
    @IBOutlet weak var connectBtn: UIButton!
    @IBOutlet weak var startBtn: UIButton!
    @IBOutlet weak var recordBtn: UIButton!
    
    @IBOutlet weak var hpfSwitch: UISwitch!
    @IBOutlet weak var hpfPickerView: UIPickerView!
    let hpfValues: [Double] = Array(stride(from: 0.5, to: 20.5, by: 0.5))
    
    @IBOutlet weak var labelSwitch: UISwitch!
    @IBOutlet weak var labelLabel: UILabel!
    
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var batteryLabel: UILabel!
    @IBOutlet weak var leftValueLabel: UILabel!
    @IBOutlet weak var rightValueLabel: UILabel!
    @IBOutlet weak var leftSQLabel: UILabel!
    @IBOutlet weak var rightSQLabel: UILabel!
    @IBOutlet weak var recordingLabel: UILabel!
    
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
    var leftSQValue: Int32 = 200 {
        didSet {
            DispatchQueue.main.async {
                self.leftSQLabel.text = "LeftSQ : \(oldValue)"
            }
        }
    }
    var rightSQValue: Int32 = 200 {
        didSet {
            DispatchQueue.main.async {
                self.rightSQLabel.text = "RightSQ : \(oldValue)"
            }
        }
    }
    var labelLabelText: String = "Label0" {
        willSet {
            DispatchQueue.main.async {
                self.labelLabel.text = newValue
            }
        }
    }
    var trainLabelType: TrainLabelType = .zero {
        willSet {
            DispatchQueue.main.async {
                self.labelLabel.text = "Label\(newValue.rawValue)"
            }
        }
    }
    var isHpf: Bool = false
    var rightEEGSamples = [Int32](repeating: 0, count: 600)
    var leftEEGSamples = [Int32](repeating: 0, count: 600)
    
    // csvで書き出すようのオブジェクト
    let eegLogger = EEGLogger()
    
    let oscClient = F53OSCClient.init()
    let analyze = Analyze.sharedInstance()!
    
    // MARK: - View
    override func viewDidLoad() {
        super.viewDidLoad()
        
        BLEDevice.shared.setDelegate(delegate: self)
        analyze.delegate = self
        
        // Setup UI
        recordingLabel.isHidden = true
        startBtn.isEnabled = false
        recordBtn.isEnabled = false
        hpfPickerView.delegate = self
        hpfPickerView.dataSource = self
        isHpf = hpfSwitch.isOn
        
        // Setup eeg values
        let rightValues = rightEEGSamples.map { Float($0) }
        let leftValues = leftEEGSamples.map { Float($0) }
        leftGraphView.update(values: leftValues)
        rightGraphView.update(values: rightValues)
        
        // Handling to foreground, to background.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.willEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }
    
    /// Viewが表示される前
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("view controller will apppear")
    }
    
    /// Viewが表示された後
    override func viewDidAppear(_ animated: Bool) {
    }
    
    /// -> フォアグラウンド
    @objc func willEnterForeground() {
        print("will enter foreground")
        startOsc()
    }
    
    /// -> バックグラウンド
    @objc func didEnterBackground() {
        print("did enter background")
        stopOsc()
    }
    
    // MARK: - OSC
    /// setup OSC
    private func setupOsc() {
        guard let pcOscIP = UserDefaults.standard.string(forKey: "pcOscIP"),
              let pcOscPortStr = UserDefaults.standard.string(forKey: "pcOscPort"),
              let pcOscPort = UInt16(pcOscPortStr) else {
            print("You should setup osc address and port.")
            return
        }
        // osc client
        oscClient.host = pcOscIP
        oscClient.port = pcOscPort
        print("PC OSC IP : \(pcOscIP), Port: \(pcOscPort)")
    }
    
    private func startOsc() {
        setupOsc()
        if !oscClient.isConnected {
            oscClient.connect()
        }
    }
    
    private func stopOsc() {
        oscClient.disconnect()
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
        print("on tap connect")
        
        BLEManager.shared.toggleConnect()
    }
    
    /// スタートボタン押下
    @IBAction func onTapStartBtn(_ sender: UIButton) {
        print("on tap start")
        
        let isStarted = BLEManager.shared.toggleStart()
        if isStarted {
            startBtn.setTitle("Stop", for: .normal)
            recordBtn.isEnabled = true
        } else {
            startBtn.setTitle("Start", for: .normal)
            recordBtn.setTitle("Record", for: .normal)
            recordBtn.isEnabled = false
            stopRecording()
        }
    }
    
    /// ストップボタン押下
    @IBAction func onTapRecordBtn(_ sender: UIButton) {
        print("on tap Record")
        eegLogger.isRecord.toggle()
        if eegLogger.isRecord {
            startRecording()
            recordBtn.setTitle("Stop Record", for: .normal)
            recordBtn.setTitleShadowColor(.red, for: .normal)
        } else {
            stopRecording()
            recordBtn.setTitle("Record", for: .normal)
        }
    }
    
    @IBAction func toggleHpfSwitch(_ sender: UISwitch) {
        let selectedRow = hpfPickerView.selectedRow(inComponent: 0)
        let hpfValue = hpfValues[selectedRow]
        isHpf = sender.isOn
        if sender.isOn {
            setFilter(value: hpfValue)
            print("HPF ON Value : \(hpfValue)")
        } else {
            analyze.disableHPFFilter()
            print("HPF OFF")
        }
    }
    
    @IBAction func toggleLabelSwitch(_ sender: UISwitch) {
        if sender.isOn {
            trainLabelType = .one
        } else {
            trainLabelType = .zero
        }
    }
    
    // MARK: - Utils
    /// グラフを更新
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
    
    /// 右耳のサンプルリストの更新
    func updateRightSamples(value: Int32) {
        rightEEGSamples.removeFirst()
        rightEEGSamples.append(value)
    }
    
    /// フィルターをセット
    func setFilter(value: Double) {
        analyze.reset()
        analyze.enableHPFFilter(value)
    }
    
    /// 録音開始
    func startRecording() {
        eegLogger.startRecording()
        recordingLabel.isHidden = false
        print("start recording")
        
    }
    
    /// 録音停止
    func stopRecording() {
        eegLogger.stopRecording()
        recordingLabel.isHidden = true
        print("stop recording")
        
    }
}

// MARK: - BLEデバイスのコールバック
extension ViewController: BLEDelegate {
    /// アドバタイズしているデバイスを見つける
    func deviceFound(devName: String, mfgID: String, deviceID: String) {
        
        BLEManager.shared.update(name: devName, uuidStr: deviceID)
        
        print("name \(devName), mfgID: \(mfgID), deviceID: \(deviceID) found")
    }
    
    /// 接続された時のコールバック
    func didConnect() {
        print("did connect")
        
        BLEManager.shared.stopScan()
        BLEManager.shared.isConnected = true
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
        
        BLEManager.shared.stop()
        BLEManager.shared.isStarted = false
        BLEManager.shared.isConnected = false
        DispatchQueue.main.async {
            self.connectBtn.setTitle("Connect", for: .normal)
            self.scanBtn.isEnabled = true
            self.startBtn.setTitle("Start", for: .normal)
            self.startBtn.isEnabled = false
        }
    }
    
    /// 信号を受信
    func eegSampleLeft(_ left: Int32, right: Int32) {
        var leftValue = left
        var rightValue = right
        
        // Filter
        if isHpf {
            leftValue = analyze.doHpfLeft(leftValue)
            rightValue = analyze.doHpfRight(rightValue)
        }
        
        // update eegSamples
        leftValueLabelInt = leftValue
        rightValueLabelInt = rightValue
        updateLeftSamples(value: leftValue)
        updateRightSamples(value: rightValue)
        updateGraph()
        
        // send osc
        let message = F53OSCMessage(addressPattern: "/brain", arguments: [leftValue, rightValue, trainLabelType.rawValue])
        oscClient.send(message)
        
        // csv log update
        eegLogger.update(eegValue: EEGValue(left: leftValue, right: rightValue, label: trainLabelType))
        
        // Update analyze
        analyze.update(withRawDataLeft: Double(leftValue))
        analyze.update(withRawDataRight: Double(rightValue))
    }
    
    /// センサーの状態が変化した時のコールバック
    func sensorStatus(_ status: Int32) {
        var left: Int32 = 1
        var right: Int32 = 1
        switch (status) {
            case 0:
                left = 0
                right = 0
            case 1:
                right = 0;
            case 2:
                left = 0;
            case 3:
                break;
            default:
                break;
        }
        analyze.checkOffheadLeft(left)
        analyze.checkOffheadRight(right)
    }
    
    /// バッテリー
    func battery(_ percent: Int32) {
        batteryLabelText = "Battery : \(percent) [%]"
    }
}

// MARK: - Anaylize Delegate
extension ViewController: AnalyzeDelegate {
    func eSenseLeftSQ(_ poorSignal: Int32) {
        leftSQValue = poorSignal
    }
    
    func eSenseRightSQ(_ poorSignal: Int32) {
        rightSQValue = poorSignal
    }
    
    func frequencyLeft(_ index: UnsafeMutablePointer<Double>!, powerSpectrum power: UnsafeMutablePointer<Double>!) {
    }
    
    func frequencyRight(_ index: UnsafeMutablePointer<Double>!, powerSpectrum power: UnsafeMutablePointer<Double>!) {
    }
}

// MARK: - ModalView handle dismiss
extension ViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        print("dismiss")
    }
}

// MARK: - PickerView
extension ViewController: UIPickerViewDelegate {
    /// PickerViewにデータを入れる
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let hpfValueStr = String(hpfValues[row])
        return hpfValueStr
    }
        
    /// PickerViewで値を更新した時、HPFフィルタの値を更新
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if hpfSwitch.isOn {
            let hpfValue = hpfValues[row]
            setFilter(value: hpfValue)
        }
    }
}

extension ViewController: UIPickerViewDataSource {
    /// PickerViewのコンポーネント数
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    /// PickerViewのデータ数 (0.5 ~ 20.0 [0.5刻み])
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return hpfValues.count
    }
}
