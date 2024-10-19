//
//  MapController.swift
//  LBTASwiftUIFirebase
//
//  Created by Saadman Rahman on 2024-10-18.
//


import MapKit
import UIKit

class MapController: UIViewController {

    @IBOutlet private weak var mapView: MKMapView!
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
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupCompassButton()
//        setupUserTrackingButtonAndScaleView()
//        registerAnnotationViewClasses()
//        
//        locationManager.delegate = self
//        locationManager.requestWhenInUseAuthorization()
//        locationManager.startUpdatingLocation()
//
//        loadEventAnnotations()
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMapView()
        setupConstraints()
    }

    private func setupMapView() {
//        mapView = MKMapView()
//        view.addSubview(mapView)

        setupCompassButton()
        setupUserTrackingButtonAndScaleView()
        registerAnnotationViewClasses()
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        loadEventAnnotations()
    }
    
    private func setupConstraints() {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
        //        if let cluster = annotation as? MKClusterAnnotation {
        //            print("Cluster annotation detected")
        //
        //            let identifier = MKMapViewDefaultClusterAnnotationViewReuseIdentifier
        //            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? ClusterAnnotationView
        //            if view == nil {
        //                view = ClusterAnnotationView(annotation: cluster, reuseIdentifier: identifier)
        //            }
        //            return view
        //        } else if annotation is EventAnnotation {
        //            let identifier = "event"
        //            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
        //            if view == nil {
        //                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        //                view?.markerTintColor = UIColor(red: 140/255, green: 82/255, blue: 255/255, alpha: 0.81)
        //            }
        //            return view
        //        }
        //        return nil
        
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
