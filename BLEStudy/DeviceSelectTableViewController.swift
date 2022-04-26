//
//  DeviceSelectTableViewController.swift
//  BLEStudy
//
//  Created by mio kato on 2022/04/12.
//

import UIKit

class DeviceSelectTableViewController: UITableViewController {
    
    var discoverDevices = [String]()
    
    var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] _ in
            self?.tableView.reloadData()
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        BLEManager.shared.stopScan()
        timer?.invalidate()
        timer = nil
    }

    deinit {
        print("deinit device select vc")
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let deviceID = BLEManager.shared.discoverDeivices[indexPath.row]
        // 一度disconnectしてからつないでみる
        BLEManager.shared.selectedDeviceID = deviceID
        BLEManager.shared.connect()
        tableView.deselectRow(at: indexPath, animated: true)
        dismiss(animated: true)
    }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return BLEManager.shared.discoverDeivices.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let deviceID = BLEManager.shared.discoverDeivices[indexPath.row]
        let deviceName = "VIE-10004 [\(deviceID.prefix8)]"
        cell.textLabel?.text = deviceName

        return cell
    }

}
