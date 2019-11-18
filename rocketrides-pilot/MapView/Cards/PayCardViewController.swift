//
//  PayCardViewController.swift
//  rocketrides-pilot
//
//  Created by James Little on 8/27/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

import UIKit
import StripeTerminal

/**
 This view controller manages the entire payment lifecycle: it calls to the merchant backend to create a
 PaymentIntent, then collects a payment method, processes the PaymentIntent, then captures it.
 This view controller also manages the reader UI delegate methods, displaying them to the operator
 as necessary.
 */
class PayCardViewController: UIViewController {
    let outerStackView = UIStackView()
    let collectPaymentLabel = UILabel()
    let collectPaymentAmount = UILabel()
    let cardImage = UIImageView()
    
    /// The card reader itself will display its status through the ReaderDisplayDelegate methods.
    /// We want to be able to display those statuses; we have a label set up to do so.
    let statusLabel = UILabel()
    
    /// The instructions label is distinct from the status label: it displays what the
    /// cardholder should be doing in any given situation, rather than displaying
    /// the reader, payment, or app status. This dual-label method helps separate
    /// the concepts of "what is the reader doing" vs. "what should the humans be doing".
    let instructionsLabel = UILabel()
    
    let retryButton = UIButton()
    
    var cardCycleDelegate: CardCycleDelegate?
    
    /**
     Used in `restartPaymentFlowIfNecessary`, which gets called when we've
     connected to a reader, to determine whether or not to actually kick off
     the payment flow. If we connect to a reader in the "happy path" (e.g.
     on app launch), we don't want to automatically launch into a payment flow.
     However, if the view controller is loaded and *then* we connect to a reader,
     we do want to kick off the payment flow at that point.
     */
    var needsToRestartPaymentProcess = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.translatesAutoresizingMaskIntoConstraints = false
        RRTerminalDelegate.shared.payInterfaceDelegate = self
        
        retryButton.setTitleColor(.red, for: .normal)
        retryButton.setTitle("Retry payment", for: .normal)
        retryButton.addTarget(self, action: #selector(startPaymentFlow), for: .touchUpInside)
        
        statusLabel.text = "Connecting..."
        statusLabel.textColor = .secondaryLabel
        statusLabel.font = UIFont.boldSystemFont(ofSize: 17)
        
        instructionsLabel.text = "Please wait until reader is ready."
        instructionsLabel.textColor = .secondaryLabel
        instructionsLabel.font = UIFont.systemFont(ofSize: 14)
        instructionsLabel.numberOfLines = 0
        
        collectPaymentLabel.text = "Collect payment from Claire"
        collectPaymentLabel.textColor = .secondaryLabel
        
        collectPaymentAmount.textColor = .label
        collectPaymentAmount.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        
        cardImage.image = UIImage(named: "card")
        
        outerStackView.axis = .vertical
        outerStackView.alignment = .center
        outerStackView.spacing = 4
        
        outerStackView.addArrangedSubview(collectPaymentLabel)
        outerStackView.addArrangedSubview(collectPaymentAmount)
        outerStackView.addArrangedSubview(cardImage)
        outerStackView.addArrangedSubview(statusLabel)
        outerStackView.addArrangedSubview(instructionsLabel)

        outerStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(outerStackView)
        outerStackView.anchorToSuperviewAnchors(withInsets: UIEdgeInsets(top: 52, left: 0, bottom: 32, right: 0))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setLabelsFromReaderConnectionStatus()
        collectPaymentAmount.text = Ride.progress.priceString
        startPaymentFlow()
    }
    
    /**
     Unlike other cards, this card needs to prevent the payment flow from happening
     unless the app is connected to a reader. This method is called if the
     card loads and we're *not* connected -- the payment flow will hold us here
     and refresh (with `setLabelsFromReaderConnectionStatus`) when we get a call to
     `TerminalDelegate.connectToReader`.
     */
    func setLabelsAsNotConnectedToReader() {
        statusLabel.text = "Please connect a reader to continue."
        statusLabel.textColor = .red
        
        instructionsLabel.text = "Use the settings screen to pick a reader."
        instructionsLabel.textColor = .secondaryLabel
    }
    
    func setLabelsAsConnectedToReader() {
        statusLabel.text = "Connected to reader."
        statusLabel.textColor = .label
        
        instructionsLabel.text = " "
        instructionsLabel.textColor = .secondaryLabel
    }
    
    func setLabelsFromReaderConnectionStatus() {
        if Terminal.shared.connectionStatus != .connected {
            setLabelsAsNotConnectedToReader()
        } else if Terminal.shared.connectedReader != nil {
            setLabelsAsConnectedToReader()
        }
    }
    
    /**
     The payment flow is made up of four steps, each of which can have an error
     in its completion handler. Instead of handling these different errors
     differently, this app treats the payment flow as a synchronous process and
     stops that process if it encounters an error. The UI is updated and the
     user can manually retry the payment.
     
     Note that this might not be the best choice for your app -- if you want
     to build something more robust, you might try different behavior based
     on the different errors you can encounter.
     */
    func stopPaymentFlowWithError(_ error: Error) {
        DispatchQueue.main.async {
            self.statusLabel.text = "Couldn't finish payment"
            self.instructionsLabel.text = error.localizedDescription
            self.outerStackView.addArrangedSubview(self.retryButton)
            self.cardCycleDelegate?.cardHeightDidChange()
        }
    }
    
    /**
     All the payment logic is encapsulated in this view controller: we want the entire payment process to
     kick off automatically when this controller appears, but we also might want to force-restart the process sometimes
     (e.g. if we connect to a new reader).
     */
    @objc
    func startPaymentFlow() {
        outerStackView.removeArrangedSubview(retryButton)
        retryButton.removeFromSuperview()
        cardCycleDelegate?.cardHeightDidChange()
        
        /// If we can't find a reader, we stop the payment flow and allow the
        /// `connectToReader` delegate method to retry it later.
        guard Terminal.shared.connectedReader != nil else {
            needsToRestartPaymentProcess = true
            return
        }
        
        let params = PaymentIntentParameters(amount: UInt(Ride.progress.price), currency: "usd")
        Terminal.shared.createPaymentIntent(params) { pi, err in
            if let err = err {
                self.stopPaymentFlowWithError(err)
                return
            }
            
            guard let pi = pi else { fatalError() }
            
            /// The Stripe Terminal SDK will not let you disconnect from a reader
            /// while the `collectPaymentMethod` or `processPayment` commands
            /// are taking place. With this method, I disable the disconnect
            /// button in the UI while in these parts of the payment flow.
            RRTerminalDelegate.shared.disableReaderDisconnect()
            
            /// The `didRequestReaderDisplayMessages` will be called around
            /// this point.
            Terminal.shared.collectPaymentMethod(pi, delegate: self) { pi, err in
                
                if let err = err {
                    self.stopPaymentFlowWithError(err)
                    self.stopPaymentFlowWithError(NSError(domain: "", code: 0, userInfo: nil))
                    return
                }
                
                guard let collectedPaymentIntent = pi else { fatalError() }
                
                self.statusLabel.text = "Processing payment..."
                self.instructionsLabel.text = "Please wait."
                
                Terminal.shared.processPayment(collectedPaymentIntent) { pi, err in
                    if let err = err {
                        self.stopPaymentFlowWithError(err)
                        return
                    }
                    
                    guard let processedPaymentIntent = pi else { fatalError() }
                    
                    /// Once we've gotten here, it's safe to let users
                    /// disconnect from the card reader.
                    RRTerminalDelegate.shared.enableReaderDisconnect()
                    APIClient.shared.capturePaymentIntent(processedPaymentIntent.stripeId) { err in
                        if let err = err {
                            self.stopPaymentFlowWithError(err)
                            return
                        }
                        
                        DispatchQueue.main.async {
                            self.cardCycleDelegate?.cycle()
                        }
                    }
                }
            }
        }
    }
}

extension PayCardViewController: ReaderDisplayDelegate {
    func terminal(_ terminal: Terminal, didRequestReaderInput inputOptions: ReaderInputOptions = []) {
        if(!inputOptions.isEmpty) {
            statusLabel.text = "Reader is ready for card."
            instructionsLabel.text = "Tap, insert, or swipe to pay."
        }
    }
    
    func terminal(_ terminal: Terminal, didRequestReaderDisplayMessage displayMessage: ReaderDisplayMessage) {
        switch displayMessage {
        case .insertCard:
            statusLabel.text = "Insert card"
        case .insertOrSwipeCard:
            statusLabel.text = "Insert or swipe card"
        case .multipleContactlessCardsDetected:
            statusLabel.text = "Multiple cards detected"
        case .removeCard:
            statusLabel.text = "Please remove card"
        case .retryCard:
            statusLabel.text = "Retry card"
        case .swipeCard:
            statusLabel.text = "Swipe card"
        case .tryAnotherCard:
            statusLabel.text = "Try another card"
        case .tryAnotherReadMethod:
            statusLabel.text = "Try another read method"
        @unknown default:
            fatalError("Unknown reader status encountered.")
        }
    }
}

extension PayCardViewController: PayInterfaceDelegate {
    /**
     Called when we connect to a reader.
     */
    func restartPaymentFlowIfNecessary() {
        if needsToRestartPaymentProcess {
            needsToRestartPaymentProcess = false
            setLabelsFromReaderConnectionStatus()
            startPaymentFlow()
        }
    }
}

protocol PayInterfaceDelegate {
    func restartPaymentFlowIfNecessary()
}
