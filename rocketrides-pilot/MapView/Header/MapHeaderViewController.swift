//
//  MapHeaderViewController.swift
//  rocketrides-pilot
//
//  Created by James Little on 8/27/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

import UIKit
import StripeTerminal

class MapHeaderViewController: UIViewController {
    let stackView = UIStackView()
    let profileImage = UIImageView()
    let logo = UIImageView()
    
    let settingsAnimation = CABasicAnimation(keyPath: "transform.rotation")
    let settingsButton = UIButton(type: .system)
    let settingsImage = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        RRTerminalDelegate.shared.connectionBackgroundDisplayDelegate = self
        
        profileImage.image = UIImage(named: "profile")
        profileImage.contentMode = .scaleAspectFit
        
        profileImage.layer.shadowColor = UIColor.black.cgColor
        profileImage.layer.shadowOpacity = 0.4
        profileImage.layer.shadowRadius = 12.0
        profileImage.layer.masksToBounds = false
        profileImage.layer.cornerRadius = 20 // magic number
        profileImage.layer.borderWidth = 2
        profileImage.layer.borderColor = UIColor.white.cgColor
        profileImage.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        logo.image = UIImage(named: "logo")
        logo.contentMode = .scaleAspectFit
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        settingsButton.setImage(UIImage(named: "spinner"), for: .normal)
        settingsButton.imageView?.contentMode = .scaleAspectFit
        settingsButton.tintColor = .white
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        settingsButton.imageEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
        stackView.addArrangedSubview(profileImage)
        stackView.addArrangedSubview(logo)
        stackView.addArrangedSubview(settingsButton)
        
        settingsAnimation.fromValue = 0.0
        settingsAnimation.toValue = Float.pi * 2.0
        settingsAnimation.duration = 1.25
        settingsAnimation.repeatCount = Float.infinity
        
        settingsButton.layer.add(settingsAnimation, forKey: nil)
        
        NSLayoutConstraint.activate([
            profileImage.heightAnchor.constraint(equalTo: stackView.heightAnchor),
            profileImage.widthAnchor.constraint(equalTo: stackView.heightAnchor),
            settingsButton.heightAnchor.constraint(equalTo: stackView.heightAnchor),
            settingsButton.widthAnchor.constraint(equalTo: stackView.heightAnchor),
            logo.widthAnchor.constraint(lessThanOrEqualToConstant: 230)
        ])
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 16
        stackView.distribution = .equalCentering
        
        view.addSubview(stackView)
        stackView.anchorToSuperviewAnchors(withInsets: UIEdgeInsets(top: 0, left: 28, bottom: 0, right: 28))
        
        settingsButton.addTarget(self, action: #selector(didRequestSettingsScreen), for: .touchUpInside)
    }
    
    @objc
    func didRequestSettingsScreen() {
        let navController = UINavigationController(rootViewController: ReaderConnectionViewController())
        self.present(navController, animated: true, completion: nil)
    }
}

/**
 The map header displays some information based on whether the app is connected
 to a reader, connecting to a reader, or could not automatically connect to a
 reader, in which case the user needs to perform actions.
 
 These delegate methods change the small icon in the upper right of the map view
 so that this state can be displayed.
 
 The `RRTerminalDelegate` is the class that calls these delegate methods.
 */
extension MapHeaderViewController: ConnectionBackgroundDisplayDelegate {
    func didConnectToReader(_ reader: Reader?) {
        settingsButton.setImage(UIImage(named: "gear"), for: .normal)
        settingsButton.layer.removeAllAnimations()
    }
    
    func startSpinner() {
        settingsButton.setImage(UIImage(named: "spinner"), for: .normal)
        settingsButton.layer.add(settingsAnimation, forKey: nil)
    }
    
    func failedAutoconnectingToReader() {
        settingsButton.setImage(UIImage(named: "gear-notif")?.withRenderingMode(.alwaysOriginal), for: .normal)
        settingsButton.layer.removeAllAnimations()
    }
}

protocol ConnectionBackgroundDisplayDelegate {
    func didConnectToReader(_ reader: Reader?)
    func startSpinner()
    func failedAutoconnectingToReader()
}
