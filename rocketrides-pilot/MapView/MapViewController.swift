//
//  MapViewController.swift
//  rocketrides-pilot
//
//  Created by James Little on 8/27/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import StripeTerminal

class MapViewController: UIViewController, MKMapViewDelegate {
    
    let header = MapHeaderViewController()
    let gradientView = MapHeaderGradientView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    var cardViewController: MapCardViewController? = nil {
        didSet {
            if oldValue == nil {
                setupCardViewController(cardViewController!)
            }
        }
    }
    let mapView = MKMapView()

    let locationManager = CLLocationManager()
    
    static var backupLocation: CLLocation {
        get {
            let backupCoordinates = CLLocationCoordinate2DMake(37.775871, -122.424388)
            return CLLocation(coordinate: backupCoordinates, altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: Date())
        }
    }
    var myLocation: CLLocation? {
        didSet {
            guard let myLocation = myLocation else {
                return
            }
            
            if let oldValue = oldValue, myLocation.coordinate != oldValue.coordinate {
                    cardViewController?.updateLocation(myLocation)
            } else {
                cardViewController = MapCardViewController(location: myLocation)
            }
        }
    }
    
    private var pickupPlacemark: MKPlacemark? {
        didSet {
            reloadMapViewContent()
        }
    }
    
    var destinationPlacemark: MKPlacemark? = Ride.current.destination {
        didSet {
            reloadMapViewContent()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(mapView)
        mapView.delegate = self
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.anchorToSuperviewAnchors()
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = false
        mapView.showsUserLocation = true //  As long as this property is true, the map view continues to track the user’s location and update it periodically.
        
        Ride.mapViewDelegate = self
        
        view.addSubview(gradientView)
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: view.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: UIScreen.main.bounds.height / 3)
        ])
        gradientView.isUserInteractionEnabled = false
        
        view.addSubview(header.view)
        header.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            header.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            header.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.view.heightAnchor.constraint(equalToConstant: 40)
        ])
        addChild(header)
        header.didMove(toParent: self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(animateActiveRide), name: NSNotification.Name(rawValue: "ride.didStartAnimation"), object: nil)
        
        RRTerminalDelegate.shared.safelyPerformDiscovery()
    }
    
    func setupCardViewController(_ cardViewController: MapCardViewController) {
        view.addSubview(cardViewController.view)
        cardViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        let safeAreaInsetTouchesEdge = UIApplication.shared.delegate?.window??.safeAreaInsets.bottom ?? 0 == 0
        let bottomConstraintConstant: CGFloat = safeAreaInsetTouchesEdge ? -36 : 0
        let bottomConstraint = cardViewController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: bottomConstraintConstant)
        bottomConstraint.priority = .defaultHigh
        
        NSLayoutConstraint.activate([
            bottomConstraint,
            cardViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            cardViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])
        addChild(cardViewController)
        cardViewController.didMove(toParent: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func reloadMapViewContent() {
        // Adjust map view region
        if let pickupLocation = pickupPlacemark?.location, let destinationLocation = destinationPlacemark?.location {
            let centerLatitude = (pickupLocation.coordinate.latitude + destinationLocation.coordinate.latitude) / 2.0       // Approximation
            let centerLongitude = (pickupLocation.coordinate.longitude + destinationLocation.coordinate.longitude) / 2.0    // Approximation
            
            let centerCoordinate = CLLocationCoordinate2D(latitude: centerLatitude,longitude: centerLongitude)
            let distance = destinationLocation.distance(from: pickupLocation)
            
            let region = MKCoordinateRegion(center: centerCoordinate, latitudinalMeters: 1.5 * distance, longitudinalMeters: 1.5 * distance)
            mapView.setRegion(region, animated: true)
        }
        else if let singleLocation = pickupPlacemark?.location ?? destinationPlacemark?.location {
            // Show either pickup or destination location in map
            let distance: CLLocationDistance = 1000.0 // 1km
            let region = MKCoordinateRegion(center: singleLocation.coordinate, latitudinalMeters: distance, longitudinalMeters: distance)
            mapView.setRegion(region, animated: true)
        }
        else {
            // Do nothing
        }
        
        // Clear existing annotations and overlays in map view
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
        // Add destination annotation to map view
        if let destinationPlacemark = destinationPlacemark {
            let destinationAnnotation = MKPointAnnotation()
            destinationAnnotation.coordinate = destinationPlacemark.coordinate

            mapView.addAnnotation(destinationAnnotation)
        }
        
        if let pickupPlacemark = pickupPlacemark {
            let pickupAnnotation = MKPointAnnotation()
            pickupAnnotation.coordinate = pickupPlacemark.coordinate
            
            if(pickupPlacemark.coordinate == MapViewController.backupLocation.coordinate) {
                // We only want to draw our own custom placemark if the map can't find
                // the user's location (and has to resort to the backup location)
                mapView.addAnnotation(pickupAnnotation)
            }
        }
        
        // Show rocket path in map view
        if let pickupCoordinate = pickupPlacemark?.coordinate, let destinationCoordinate = destinationPlacemark?.coordinate {
            let rocketPathOverlay = RocketPathOverlay(start: pickupCoordinate, end: destinationCoordinate)
            mapView.addOverlay(rocketPathOverlay, level: .aboveLabels)
        }
    }
    
    // MARK: MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard let location = userLocation.location else {
            fatalError("Could not get location from user location object")
        }

        myLocation = location
        pickupPlacemark = MKPlacemark(coordinate: location.coordinate)
    }
    
    func mapView(_ mapView: MKMapView, didFailToLocateUserWithError error: Error) {
        print("Failed to locate device, using backup value")
        pickupPlacemark = MKPlacemark(coordinate: MapViewController.backupLocation.coordinate)
        myLocation = MapViewController.backupLocation
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let rocketPathOverlay = overlay as? RocketPathOverlay {
            // Use styled rocket path overlay renderer
            let renderer = RocketPathOverlayRenderer(rocketPathOverlay: rocketPathOverlay)
            renderer.strokeColor = UIColor(named: "RRGreen")

            return renderer
        }
        
        // Use default renderer
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKind(of: MKUserLocation.self) {
            return nil
        }
        
        if let destinationCoordinate = destinationPlacemark?.coordinate,
            annotation.coordinate == destinationCoordinate {
            // Use pin for destination annotation
            let identifier = "pin"
            
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) ?? MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView.image = UIImage(named: "pin")
            
            return annotationView
        } else if annotation.coordinate == MapViewController.backupLocation.coordinate && annotation.title != "riderMarker" {
            let identifier = "myPin"
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) ?? MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView.image = UIImage(named: "pin")
            return annotationView
        } else {
            // Use rocket annotation
            let identifier = "rocketPointAnnotation"
            
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) ?? MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView.image = UIImage(named: "rocketeer")
            return annotationView
        }
    }
    
    @objc func animateActiveRide() {
        // Animate traveling on rocket path
        let numberOfPoints = 1000
        let animationDuration = 2.0
        let delay = 1.0

        guard let rocketPathOverlay = mapView.overlays.first(where: { $0 is RocketPathOverlay}) as? RocketPathOverlay else {
            print("[ERROR] Missing expected `rocketPathOverlay`")
            return
        }

        let rocketRiderAnnotation = MKPointAnnotation()
        rocketRiderAnnotation.title = "riderMarker"
        mapView.addAnnotation(rocketRiderAnnotation)

        let rocketPathMapPoints = RocketPathOverlayRenderer(rocketPathOverlay: rocketPathOverlay).points(count: numberOfPoints)
        var currentMapPointIdx = 0

        func moveToNextPoint() {
            // Move annotation to latest map point
            let mapPoint = rocketPathMapPoints[currentMapPointIdx]
            rocketRiderAnnotation.coordinate = mapPoint.coordinate

            // Iterate to next map point
            currentMapPointIdx += 1

            if currentMapPointIdx < rocketPathMapPoints.count {
                // Schedule next animation step
                let deadline = DispatchTime.now() + (animationDuration / Double(numberOfPoints))
                DispatchQueue.main.asyncAfter(deadline: deadline) {
                    moveToNextPoint()
                }
            }
            else {
                mapView.removeAnnotation(rocketRiderAnnotation)
            }
        }

        // Kickoff animation loop
        let deadline = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            moveToNextPoint()
        }
    }
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return (lhs.longitude == rhs.longitude) && (lhs.latitude == rhs.latitude)
    }
}
