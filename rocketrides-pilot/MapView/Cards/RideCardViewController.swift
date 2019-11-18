//
//  RideCardViewController.swift
//  rocketrides-pilot
//
//  Created by James Little on 8/27/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

import UIKit

class RideCardViewController: UIViewController {
    let outerStackView = UIStackView()
    var rideProgressStats = RideProgressLineItemView(viewModel: nil)
    let cardAdvanceButton = CardAdvanceButton()
    
    var cardCycleDelegate: CardCycleDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        cardAdvanceButton.setTitle("Drop off Claire", for: .normal)
        cardAdvanceButton.addTarget(self, action: #selector(advanceCard), for: .touchUpInside)
        
        outerStackView.axis = .vertical
        outerStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(outerStackView)
        outerStackView.anchorToSuperviewAnchors()
        
        outerStackView.addArrangedSubview(rideProgressStats)
        outerStackView.addArrangedSubview(cardAdvanceButton)
        
        cardAdvanceButton.isUserInteractionEnabled = false
        cardAdvanceButton.alpha = 0.4
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.rideProgressStats.vm = Ride.progress
        
        cardAdvanceButton.isUserInteractionEnabled = false
        cardAdvanceButton.alpha = 0.4
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        rideProgressStats.animateToZero(duration: 2.0, delay: 1.0)
        NotificationCenter.default.post(Notification(name: Notification.Name("ride.didStartAnimation")))
        
        UIView.animate(withDuration: 0.4, delay: 2.8, options: .curveEaseInOut, animations: {
            self.cardAdvanceButton.alpha = 1.0
        }, completion: { _ in
            self.cardAdvanceButton.isUserInteractionEnabled = true
        })
    }
    
    @objc
    func advanceCard() {
        guard let delegate = cardCycleDelegate else {
            return
        }
        
        delegate.cycle()
    }
}
