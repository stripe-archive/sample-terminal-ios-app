//
//  ViewController.swift
//  rocketrides-pilot
//
//  Created by James Little on 8/26/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

import UIKit
import StripeTerminal

/**
 This class, meant to be accessed through the static `.shared` instance, acts as
 a go-between for the Terminal SDK and the rest of the app. It manages the
 discovery lifecycle and connection status.
 */
class RRTerminalDelegate: NSObject {
    
    /**
     A list of possible actions a user might want to take while managing the
     reader connection. These actions ahave to be enabled & disabled at
     different times—this availability is managed in the `availableConnectionActions`
     dictionary.
     */
    enum PossibleConnectionActions {
        case disconnectAndSearch
        case forgetLastSeen
    }
    
    static let shared = RRTerminalDelegate()
    static let config = DiscoveryConfiguration(deviceType: .chipper2X,
                                               discoveryMethod: .bluetoothProximity,
                                               simulated: true)
    
    var payInterfaceDelegate: PayInterfaceDelegate?
    var connectionBackgroundDisplayDelegate: ConnectionBackgroundDisplayDelegate?
    weak var connectionDelegate: ConnectionViewDelegate?
    
    var readerStatusText = "" {
        didSet {
            connectionDelegate?.didChangeConnectionData()
        }
    }
    
    var readers: [Reader] = [] {
        didSet {
            connectionDelegate?.didChangeConnectionData()
        }
    }
    
    var discoverCancelable: Cancelable?
    
    /// The number of in-progress actions currently blocking you from calling
    /// the SDK discovery method.
    ///
    /// The Terminal SDK won't let you perform reader discovery in one of two
    /// situations: if the SDK is currently disconnecting or if the SDK is
    /// currently working on another discover operation. We track whether both
    /// of these things are happening, incrementing this integer when either
    /// process starts and decrementing it when it ends. Only when this
    /// is zero can we ask the SDK to discover readers.
    var discoveryBlockers = 0
    
    /// We want to keep track of whether we _can_ perform discovery, but we
    /// also want to keep track of whether we _should_ perform discovery, since
    /// the actual `performDiscovery` function should only be called via the
    /// `safelyPerformDiscovery` function so we can safely disconnect from
    /// any connected readers first.
    var shouldPerformDiscovery = false
    
    /// A dictionary connecting the possible connection actions with the
    /// availability of each action.
    ///
    /// Whenever this variable is changed, `connectionDelegate.didChangeConnectionData()`
    /// should be called so the table view updates its data.
    /// These default values are meant to be the defaults on app start;
    /// since this is a singleton, they get updated throughout the lifecycle of the app.
    var availableConnectionActions: [PossibleConnectionActions: Bool] = [
        .disconnectAndSearch: true,
        .forgetLastSeen: UserDefaults.standard.string(forKey: "terminal.lastReaderConnected") != nil
    ]
    
    /**
     This function ends existing discovery actions and disconnects from any
     connected readers, while keeping track of the `discoveryBlockers` and
     `shouldPerformDiscovery` variables. This function will then call
     `performDiscoveryIfPossible()` in three different async locations.
     This ensures that discovery can always happen, and that we're not going
     to hit a case where the SDK isn't expecting us to call its discovery method.
     */
    func safelyPerformDiscovery() {
        shouldPerformDiscovery = true
        disableReaderDisconnect()
        connectionBackgroundDisplayDelegate?.startSpinner()
        
        if Terminal.shared.connectionStatus == .connected {
            discoveryBlockers += 1
            print(Terminal.shared.connectionStatus.rawValue)
            Terminal.shared.disconnectReader({ error in
                if error != nil {
                    print(error?.localizedDescription ?? "Error disconnecting")
                } else {
                    self.discoveryBlockers -= 1
                    print(Terminal.shared.connectionStatus.rawValue)
                    self.performDiscoveryIfPossible()
                }
            })
            return
        }
        
        if let discoverCancelable = self.discoverCancelable, !discoverCancelable.completed {
            discoveryBlockers += 1
            discoverCancelable.cancel({error in
                if(error != nil) {
                    print(error?.localizedDescription ?? "Error canceling discovery")
                } else {
                    self.discoveryBlockers -= 1
                }
            })
            return
        }
        
        performDiscoveryIfPossible()
    }
    
    /**
     Called in `safelyPerformDiscovery` synchronously, and then in the completion
     handler of `disconnectReader` and `discoverCancelable.cancel`. Will only
     let the SDK's discovery function be called if it is safe to do so.
     */
    private func performDiscoveryIfPossible() {
        if discoveryBlockers == 0 && shouldPerformDiscovery {
            shouldPerformDiscovery = false
            self.performDiscovery()
        }
    }
    
    private func performDiscovery() {
        self.updateReaderStatusLabel(withText: "Discovering readers...")
        
        DispatchQueue.main.async {
            self.discoverCancelable = Terminal.shared.discoverReaders(RRTerminalDelegate.config, delegate: RRTerminalDelegate.shared, completion: { error in
                if let error = error {
                    self.updateReaderStatusLabel(withText: "Error searching.")
                    UIApplication.shared.presentTerminalError(title: "Error searching for readers.", description: error.localizedDescription)
                    self.connectionBackgroundDisplayDelegate?.failedAutoconnectingToReader()
                }
                
                self.performDiscoveryIfPossible()
            })
        }
    }
    
    func updateReaderStatusLabel(withText text: String?) {
        if let text = text {
            readerStatusText = text
            return
        }
        
        if let r = Terminal.shared.connectedReader {
            var batteryLevelString = "??%"
            if let batteryLevel = r.batteryLevel as? Double {
                batteryLevelString = "\(String(format: "%.1f", batteryLevel * 100))%"
            }
            readerStatusText = "Connected to reader:\n\(r.serialNumber) \(batteryLevelString) \(r.simulated ? "(S)" : "")"
        } else {
            readerStatusText = "Reader connection error."
        }
    }
    
    
    func disableReaderDisconnect() {
        availableConnectionActions[.disconnectAndSearch] = false
        connectionDelegate?.didChangeConnectionData()
    }
    
    func enableReaderDisconnect() {
        availableConnectionActions[.disconnectAndSearch] = true
        connectionDelegate?.didChangeConnectionData()
    }
}
    
// MARK: - DiscoveryDelegate
extension RRTerminalDelegate: DiscoveryDelegate {
    func terminal(_ terminal: Terminal, didUpdateDiscoveredReaders readers: [Reader]) {
        guard terminal.connectionStatus == .notConnected else { return }

        if (readers.count == 0) {
            self.connectionBackgroundDisplayDelegate?.failedAutoconnectingToReader()
            self.updateReaderStatusLabel(withText: "No readers found.")
        }

        else if let lastSeenReader = readers.filter({ reader in
            return reader.serialNumber == UserDefaults.standard.string(forKey: "terminal.lastReaderConnected")
        }).first {
            self.updateReaderStatusLabel(withText: "Found last-seen reader. Connecting...")
            Terminal.shared.connectReader(lastSeenReader) { reader, error in
                self.connectToReader(reader, error)
            }
        }
        
        else {
            self.updateReaderStatusLabel(withText: "\(readers.count) reader\(readers.count == 1 ? "" : "s") found...")
            self.readers = readers
            self.connectionBackgroundDisplayDelegate?.failedAutoconnectingToReader()
            availableConnectionActions[.disconnectAndSearch] = true
            connectionDelegate?.didChangeConnectionData()
        }
    }
}
    
// MARK: - TerminalDelegate
extension RRTerminalDelegate: TerminalDelegate {
    func connectToReader(_ reader: Reader?, _ error: Error?) {
        self.updateReaderStatusLabel(withText: "Connecting...")
        self.readers = []
        discoverCancelable = nil
        if let reader = reader {
            UserDefaults.standard.set(reader.serialNumber, forKey: "terminal.lastReaderConnected")
            self.connectionBackgroundDisplayDelegate?.didConnectToReader(reader)
            self.payInterfaceDelegate?.restartPaymentFlowIfNecessary()
            self.updateReaderStatusLabel(withText: nil)
            
            availableConnectionActions[.forgetLastSeen] = true
            availableConnectionActions[.disconnectAndSearch] = true
            connectionDelegate?.didChangeConnectionData()
        }

        else if let error = error {
            UIApplication.shared.presentTerminalError(title: "Connection error", description: error.localizedDescription)
        }
    }
    
    func terminal(_ terminal: Terminal, didReportUnexpectedReaderDisconnect reader: Reader) {
        UIApplication.shared.presentTerminalError(title: "Reader unexpectedly disconnected.", description: "Please try searching and reconnecting.")
        self.connectionBackgroundDisplayDelegate?.failedAutoconnectingToReader()
    }
}

