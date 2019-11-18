//
//  RideProgress.swift
//  rocketrides-pilot
//
//  Created by James Little on 9/3/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

import UIKit
import MapKit

struct RideProgressViewModel {
    static var prices = [4242, 5556, 4444, 3222, 8210, 5100, 1117, 9424]
    
    init(ride: Ride, location: CLLocation) {
        let lat = ride.destination.coordinate.latitude
        let long = ride.destination.coordinate.longitude
        
        self.milesLeft = CLLocation.init(latitude: lat, longitude: long).distance(from: location) / 1609.344
        self.minutesRemaining = Int(self.milesLeft * 1.2766)
        self.price = RideProgressViewModel.prices.randomElement() ?? RideProgressViewModel.prices[0]
    }
    
    var minutesRemaining: Int
    var milesLeft: Double
    var price: Int
    
    var priceString: String? {
        get {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .currency
            return numberFormatter.string(from: NSNumber(value: (Double(Ride.progress.price))/100.0))
        }
    }
}

class RideProgressLineItemView: UIView {
    var vm: RideProgressViewModel? {
        didSet {
            self.refreshValues()
        }
    }
    
    let arrivalTimeKey = UILabel()
    let arrivalTimeValue = UILabel()
    let minutesRemainingKey = UILabel()
    let minutesRemainingValue = UILabel()
    let distanceLeftKey = UILabel()
    let distanceLeftValue = UILabel()
    
    let arrivalTimeVstack = UIStackView()
    let minutesRemainingVstack = UIStackView()
    let distanceLeftVstack = UIStackView()
    
    let outerStackView = UIStackView()
    
    init(viewModel: RideProgressViewModel?) {
        self.vm = viewModel
        super.init(frame: CGRect.null)
        
        arrivalTimeKey.font = UIFont.systemFont(ofSize: 15)
        arrivalTimeKey.textColor = .secondaryLabel
        arrivalTimeKey.text = "Arrival"
        
        minutesRemainingKey.font = UIFont.systemFont(ofSize: 15)
        minutesRemainingKey.textColor = .secondaryLabel
        minutesRemainingKey.text = "min"
        
        distanceLeftKey.font = UIFont.systemFont(ofSize: 15)
        distanceLeftKey.textColor = .secondaryLabel
        distanceLeftKey.text = "mi"
        
        arrivalTimeValue.font = UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .regular)
        arrivalTimeValue.textColor = .label
        
        minutesRemainingValue.font = UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .regular)
        minutesRemainingValue.textColor = .label
        
        distanceLeftValue.font = UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .regular)
        distanceLeftValue.textColor = .label
        
        arrivalTimeVstack.axis = .vertical
        arrivalTimeVstack.alignment = .center
        arrivalTimeVstack.addArrangedSubview(arrivalTimeValue)
        arrivalTimeVstack.addArrangedSubview(arrivalTimeKey)
        
        minutesRemainingVstack.axis = .vertical
        minutesRemainingVstack.alignment = .center
        minutesRemainingVstack.addArrangedSubview(minutesRemainingValue)
        minutesRemainingVstack.addArrangedSubview(minutesRemainingKey)
        
        distanceLeftVstack.axis = .vertical
        distanceLeftVstack.alignment = .center
        distanceLeftVstack.addArrangedSubview(distanceLeftValue)
        distanceLeftVstack.addArrangedSubview(distanceLeftKey)
        
        outerStackView.spacing = 12
        outerStackView.alignment = .center
        outerStackView.distribution = .equalCentering
        
        outerStackView.addArrangedSubview(arrivalTimeVstack)
        outerStackView.addArrangedSubview(minutesRemainingVstack)
        outerStackView.addArrangedSubview(distanceLeftVstack)
        
        self.refreshValues()
        
        outerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(outerStackView)
        NSLayoutConstraint.activate([
            outerStackView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            outerStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            outerStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            outerStackView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5)
        ])
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func refreshValues() {
        guard let vm = vm else {
            arrivalTimeValue.text = "??"
            minutesRemainingValue.text = "??"
            distanceLeftValue.text = "??"
            return
        }
        
        let arrivalTime = Date().addingTimeInterval(TimeInterval(vm.minutesRemaining * 60))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm";
        arrivalTimeValue.text = dateFormatter.string(from: arrivalTime)
        minutesRemainingValue.text = "\(vm.minutesRemaining)"
        distanceLeftValue.text = String(format: "%.1f", vm.milesLeft)
    }
    
    func animateToZero(duration: Double, delay: Double) {
        guard let vm = vm else {
            return
        }
        
        let animationPeriod_seconds = duration
        let usPerUpdate: Int = 50_000
        let usPerSecond: Int = 1_000_000
        
        let initialDistanceValue: Double = vm.milesLeft
        let m_distance = (-1 * initialDistanceValue) / (animationPeriod_seconds * Double(usPerSecond))
        
        let initialTimeValue: Double = Double(vm.minutesRemaining)
        let m_time = (-1 * initialTimeValue) / (animationPeriod_seconds * Double(usPerSecond))
        
        var currentTimeValue_us = 0
        
        DispatchQueue.global(qos: .default).async {
            usleep(useconds_t(delay * Double(usPerSecond)))
            
            while(currentTimeValue_us < Int(animationPeriod_seconds * Double(usPerSecond))) {
                let currentDistanceValue = m_distance * Double(currentTimeValue_us) + initialDistanceValue
                let currentTimeValue = m_time * Double(currentTimeValue_us) + initialTimeValue
                
                DispatchQueue.main.sync {
                    self.distanceLeftValue.text = String(format: "%.1f", currentDistanceValue)
                    self.minutesRemainingValue.text = String(format: "%.0f", currentTimeValue)
                }
                
                currentTimeValue_us += usPerUpdate
                usleep(useconds_t(usPerUpdate))
            }
            
            DispatchQueue.main.sync {
                self.distanceLeftValue.text = String(format: "%.1f", 0.0)
                self.minutesRemainingValue.text = String(format: "%.0f", 0.0)
            }
        }
    }
}

