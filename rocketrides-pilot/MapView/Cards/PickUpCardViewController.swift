//
//  RideCardViewController.swift
//  rocketrides-pilot
//
//  Created by James Little on 8/27/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

import UIKit

class PickUpCardViewController: UIViewController {
    
    let outerStackView = UIStackView()
    let takeToLabel = UILabel()
    let destinationLabel = UILabel()
    var rideProgressStats = RideProgressLineItemView(viewModel: nil)
    let cardAdvanceButton = CardAdvanceButton()
    
    var cardCycleDelegate: CardCycleDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        takeToLabel.text = "Taking Claire to"
        takeToLabel.textColor = .secondaryLabel
        takeToLabel.font = UIFont.systemFont(ofSize: 15)
        takeToLabel.textAlignment = .center
        
        destinationLabel.textColor = .label
        destinationLabel.textAlignment = .center
        destinationLabel.font = UIFont.boldSystemFont(ofSize: 21)
        
        cardAdvanceButton.setTitle("Begin Ride", for: .normal)
        cardAdvanceButton.addTarget(self, action: #selector(advanceCard), for: .touchUpInside)
        
        outerStackView.axis = .vertical
        outerStackView.spacing = 6
        outerStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(outerStackView)
        outerStackView.anchorToSuperviewAnchors(withInsets: UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0))
        
        outerStackView.addArrangedSubview(takeToLabel)
        outerStackView.addArrangedSubview(destinationLabel)
        outerStackView.addArrangedSubview(rideProgressStats)
        outerStackView.addArrangedSubview(cardAdvanceButton)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        destinationLabel.text = Ride.current.destinationLabel
        rideProgressStats.vm = Ride.progress
    }
    
    @objc
    func advanceCard() {
        guard let delegate = cardCycleDelegate else {
            return
        }
        
        delegate.cycle()
    }
}
