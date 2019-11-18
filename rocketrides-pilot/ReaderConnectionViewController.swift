//
//  ReaderConnectionViewController.swift
//  rocketrides-pilot
//
//  Created by James Little on 8/29/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

import UIKit
import StripeTerminal

/**
 The TableViewController that is presented over the map. This view controller
 provides the UI for connecting to, disconnecting from, and managing readers.
 */
class ReaderConnectionViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView = UITableView(frame: CGRect.zero, style: .grouped)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(didSelectCloseButton))
        navigationItem.title = "Readers"
        
        RRTerminalDelegate.shared.connectionDelegate = self
        
        self.becomeFirstResponder()
    }
    
    @objc
    func didSelectCloseButton() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - TableView
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            // How many rows should we show in the "Connection Actions" section?
            // Depends on how many connection actions are available right now,
            // as determined by the RRTerminalDelegate singleton.
            return RRTerminalDelegate.shared.availableConnectionActions.values.reduce(0) { sum, value in
                return sum + (value ? 1 : 0)
            }
        case 2:
            return RRTerminalDelegate.shared.readers.count
        default:
            fatalError()
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        switch indexPath.section {
        case 0:
            cell.textLabel?.text = RRTerminalDelegate.shared.readerStatusText
            cell.textLabel?.numberOfLines = 0
        case 1:
            let actions = RRTerminalDelegate.shared.availableConnectionActions.compactMap { (action, isAvailable) in
                return isAvailable ? action : nil
            }
            
            switch actions[indexPath.row] {
            case .disconnectAndSearch:
                cell.textLabel?.text = "Disconnect and search..."
            case .forgetLastSeen:
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
                cell.textLabel?.text = "Forget last seen reader"
                cell.detailTextLabel?.text = UserDefaults.standard.string(forKey: "terminal.lastReaderConnected")
            }
            cell.accessoryType = .disclosureIndicator
        case 2:
            cell.textLabel?.text = RRTerminalDelegate.shared.readers[indexPath.row].serialNumber
            cell.accessoryType = .disclosureIndicator
        default:
            fatalError()
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 1:
            tableView.deselectRow(at: indexPath, animated: true)
            let actions = RRTerminalDelegate.shared.availableConnectionActions.compactMap { (action, isAvailable) in
                return isAvailable ? action : nil
            }
            
            switch actions[indexPath.row] {
            case .disconnectAndSearch:
                RRTerminalDelegate.shared.updateReaderStatusLabel(withText: "Disconnecting...")
                RRTerminalDelegate.shared.safelyPerformDiscovery()
                
            case .forgetLastSeen:
                UserDefaults.standard.set(nil, forKey: "terminal.lastReaderConnected")
                RRTerminalDelegate.shared.availableConnectionActions[.forgetLastSeen] = false
                tableView.reloadData()
            }
        case 2:
            Terminal.shared.connectReader(RRTerminalDelegate.shared.readers[indexPath.row]) { reader, error in
                RRTerminalDelegate.shared.connectToReader(reader, error)
            }
            
            // We don't want users to be able to mash this cell and call
            // connect more than once, so we clear out the list of readers
            // once the user has selected one.
            RRTerminalDelegate.shared.readers = []
            tableView.reloadData()
        default:
            return
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return nil
        case 1:
            // This trickery here is just hiding the title if there aren't any
            // available actions.
            let numberOfAvailableActions = RRTerminalDelegate.shared.availableConnectionActions.values.reduce(0) { sum, value in
                return sum + (value ? 1 : 0)
            }
            return numberOfAvailableActions > 0 ? "Connection Actions" : ""
        case 2:
            return !RRTerminalDelegate.shared.readers.isEmpty ? "Discovered reader" : ""
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 2:
            return !RRTerminalDelegate.shared.readers.isEmpty ? "Bluetooth Proximity filters search results to return the closest available reader. The reader it finds flashes multicolored lights." : ""
        default:
            return nil
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }
}

protocol ConnectionViewDelegate : class {
    func didChangeConnectionData()
}

extension ReaderConnectionViewController: ConnectionViewDelegate {
    func didChangeConnectionData() {
        tableView.reloadData()
    }
}
