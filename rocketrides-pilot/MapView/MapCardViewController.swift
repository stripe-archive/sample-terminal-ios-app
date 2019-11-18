//
//  MapCardViewController.swift
//  rocketrides-pilot
//
//  Created by James Little on 8/27/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

import UIKit
import MapKit
import StripeTerminal

class MapCardViewController: UIViewController {
    var currentLocation: CLLocation
    
    let cardPalette = UIView()
    
    let pickUpCard = PickUpCardViewController()
    let rideCard = RideCardViewController()
    let payCard = PayCardViewController()
    let payCompleteCard = PayCompleteCardViewController()
    
    let cards: [UIViewController]
    var currentCardIterator: IndexingIterator<[UIViewController]>
    
    var currentlyActiveViewController: UIViewController?
    var currentlyActiveConstraints: [NSLayoutConstraint] = []
    var paletteHeightConstraint: NSLayoutConstraint?
    var cardHeightConstraint: NSLayoutConstraint?
    
    init(location: CLLocation) {
        cards = [pickUpCard, rideCard, payCard, payCompleteCard]
        currentCardIterator = cards.makeIterator()
        self.currentLocation = location
        super.init(nibName: nil, bundle: nil)
        Ride.rideCycleDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.6
        view.layer.shadowRadius = 12.0
        view.layer.masksToBounds = false
        
        let blurEffect = UIBlurEffect(style: .regular)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.layer.cornerRadius = 24.0
        blurView.layer.masksToBounds = true
        view.insertSubview(blurView, at: 0)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.anchorToSuperviewAnchors()
        
        cardPalette.translatesAutoresizingMaskIntoConstraints = false
        cardPalette.layer.cornerRadius = 24.0
        cardPalette.layer.masksToBounds = true
        view.addSubview(cardPalette)
        
        NSLayoutConstraint.activate([
            cardPalette.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            cardPalette.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cardPalette.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        pickUpCard.cardCycleDelegate = self
        rideCard.cardCycleDelegate = self
        payCard.cardCycleDelegate = self
        payCompleteCard.cardCycleDelegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        advanceCard()
    }
    
    func updateLocation(_ location: CLLocation) {
        self.currentLocation = location
    }
    
    func advanceCard() {
        guard let next = (currentCardIterator.next() ?? { () -> UIViewController? in
            self.currentCardIterator = cards.makeIterator()
            return self.currentCardIterator.next()
        }()) else {
            return
        }
        
        cardPalette.addSubview(next.view)
        addChild(next)
        next.didMove(toParent: self)
        next.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            next.view.bottomAnchor.constraint(equalTo: cardPalette.bottomAnchor),
            next.view.leadingAnchor.constraint(equalTo: cardPalette.leadingAnchor),
            next.view.trailingAnchor.constraint(equalTo: cardPalette.trailingAnchor)
        ])
        
        view.layoutSubviews()
        next.view.layoutSubviews()
        cardPalette.layoutIfNeeded()
        
        let nextHeight = next.view.bounds.height
        
        if let prev = currentlyActiveViewController {
            prev.willMove(toParent: nil)

            let screenWidth = UIScreen.main.bounds.width

            next.view.alpha = 0
            next.view.transform = CGAffineTransform(translationX: screenWidth, y: 0)

            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
                prev.view.alpha = 0
            }, completion: nil)

            UIView.animate(withDuration: 0.25, delay: 0.4, options: .curveEaseInOut, animations: {
                next.view.alpha = 1
            }, completion: nil)

            self.cardHeightConstraint?.constant = nextHeight
            self.paletteHeightConstraint?.constant = nextHeight
            UIView.animate(withDuration: 0.7, delay: 0, options: .curveEaseInOut, animations: {
                prev.view.transform = CGAffineTransform(translationX: screenWidth * -1, y: 0)
                next.view.transform = CGAffineTransform(translationX: 0, y: 0)
                self.view.superview?.layoutIfNeeded()
            }, completion: { _ in
                prev.removeFromParent()
                prev.view.removeFromSuperview()
            })
        } else {
            cardHeightConstraint = view.heightAnchor.constraint(equalToConstant: nextHeight)
            paletteHeightConstraint = cardPalette.heightAnchor.constraint(equalToConstant: nextHeight)
            NSLayoutConstraint.activate([cardHeightConstraint!, paletteHeightConstraint!])
        }
        
        currentlyActiveViewController = next
    }
}

protocol CardCycleDelegate {
    func cycle()
    func cardHeightDidChange()
}

extension MapCardViewController: CardCycleDelegate {
    func cycle() {
        advanceCard()
    }
    
    func cardHeightDidChange() {
        if let cavc = currentlyActiveViewController {
            cardHeightConstraint?.constant = cavc.view.bounds.height
            cardPalette.layoutIfNeeded()
        }
    }
}
