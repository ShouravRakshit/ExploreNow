//
//  MapController.swift
//  LBTASwiftUIFirebase
//
//  Created by Saadman Rahman on 2024-10-18.
//


import MapKit
import UIKit

class MapController: UIViewController {

//    @IBOutlet private weak var mapView: MKMapView!
    private let mapView = MKMapView() // Initialize map view programmatically

    private var userTrackingButton: MKUserTrackingButton!
    private var scaleView: MKScaleView!
    
    // Create a location manager to trigger user tracking
    private let locationManager = CLLocationManager()
    
    // Hardcoded event locations
    private let eventLocations = [
        CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // San Francisco
        CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437), // Los Angeles
        CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),  // New York
        CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),   // London
        CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)     // Paris
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()     // Has been added for after removing IBOutlet
        setupCompassButton()
        setupUserTrackingButtonAndScaleView()
        registerAnnotationViewClasses()
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        loadEventAnnotations()
    }
    
    private func setupMapView() {
        view.addSubview(mapView) // Add map view to the main view

        // Configure the map view's appearance and behavior
        mapView.delegate = self
        mapView.showsUserLocation = true

        // Use Auto Layout constraints to position the map view
        mapView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    


    
    private func setupCompassButton() {
        let compass = MKCompassButton(mapView: mapView)
        compass.compassVisibility = .visible
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: compass)
        mapView.showsCompass = false
    }

    private func setupUserTrackingButtonAndScaleView() {
        mapView.showsUserLocation = true
        
        userTrackingButton = MKUserTrackingButton(mapView: mapView)
        userTrackingButton.isHidden = true // Unhides when location authorization is given.
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: userTrackingButton)
        
        scaleView = MKScaleView(mapView: mapView)
        scaleView.legendAlignment = .trailing
        view.addSubview(scaleView)
        
        let stackView = UIStackView(arrangedSubviews: [scaleView, userTrackingButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 10
        view.addSubview(stackView)

        
        NSLayoutConstraint.activate([
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10)
        ])
    }

    private func registerAnnotationViewClasses() {
        mapView.register(EventAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.register(ClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
    }

    // Load event locations and add them as annotations
    private func loadEventAnnotations() {
//        might need to add map.region
        let eventAnnotations = eventLocations.map { Event(coordinate: $0) }
        mapView.addAnnotations(eventAnnotations)
    }
}

extension MapController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard let annotation = annotation as? Event else { return nil }
        
        return EventAnnotationView(annotation: annotation, reuseIdentifier: EventAnnotationView.ReuseID)
    }
        
        
    
}

extension MapController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let locationAuthorized = status == .authorizedWhenInUse
        userTrackingButton.isHidden = !locationAuthorized
    }
}
