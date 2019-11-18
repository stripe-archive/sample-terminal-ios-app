//
//  Ride.swift
//  rocketrides-pilot
//
//  Created by James Little on 8/28/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

import Foundation
import MapKit

struct Ride {
    private static let list = [
        Ride(lat: 37.809896, long: -122.4791287, label: "Golden Gate Bridge"),
        Ride(lat: 37.8266418, long: -122.423427, label: "Alcatraz Island"),
        Ride(lat: 37.8020445, long: -122.4210071, label: "Lombard Street"),
        Ride(lat: 37.17159, long: -122.22203, label: "Big Basin Redwoods State Park"),
        Ride(lat: 37.7804369, long: -122.5158822, label: "Sutro Baths"),
        Ride(lat: 37.8201484, long: -122.3777418, label: "Treasure Island"),
        Ride(lat: 37.7620333, long: -122.4369478, label: "Castro Theater"),
        Ride(lat: 37.7762593, long: -122.4349467, label: "The Painted Ladies"),
        Ride(lat: 37.7693884, long: -122.4510155, label: "Haight-Ashbury")
    ]
    
    private static var iterator = Ride.list.makeIterator()
    
    static var current: Ride = Ride.iterator.next() ?? Ride.list[0] {
        didSet {
            mapViewDelegate?.destinationPlacemark = Ride.current.destination
        }
    }
    
    static var progress: RideProgressViewModel {
        get {
            guard let rideCycleDelegate = rideCycleDelegate else {
                fatalError("Ride struct couldn't find its cycle delegate.")
            }
            return RideProgressViewModel(
                ride: Ride.current,
                location: rideCycleDelegate.currentLocation
            )
        }
    }

    static var mapViewDelegate: MapViewController?
    static var rideCycleDelegate: MapCardViewController?
    
    static func iterate() {
        Ride.current = Ride.iterator.next() ?? { () -> Ride in
            Ride.iterator = Ride.list.makeIterator()
            return Ride.iterator.next() ?? Ride.list[0]
        }()
    }
    
    static func resetIterator() {
        Ride.iterator = Ride.list.makeIterator()
    }
    
    let destination: MKPlacemark
    let destinationLabel: String
    
    init(lat: Double, long: Double, label: String) {
        self.destination = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: long))
        self.destinationLabel = label
    }
}
