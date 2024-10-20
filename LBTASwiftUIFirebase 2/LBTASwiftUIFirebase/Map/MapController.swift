//
//  MapController.swift
//  LBTASwiftUIFirebase
//
//  Created by Saadman Rahman on 2024-10-18.
//

import MapKit
import UIKit

class MapController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    private let mapView = MKMapView() // Initialize map view programmatically
    private let searchBar = UISearchBar()
    private let containerView = UIView()  // Container for SearchBar + MapView

    private let locationManager = CLLocationManager()
    private var userTrackingButton: MKUserTrackingButton!
    private var scaleView: MKScaleView!

    // Hardcoded event locations
    private let eventLocations = [
        CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // San Francisco
        CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437), // Los Angeles
        CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),  // New York
        CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),   // London
        CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)     // Paris
    ]

    private lazy var mapSearchController: MapSearchController = {
        let controller = MapSearchController(mapView: mapView)
        controller.delegate = self
        return controller
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCompassButton()
        setupUserTrackingButtonAndScaleView()
        registerAnnotationViewClasses()

        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        loadLocationAnnotations()
    }

    private func setupUI() {
        view.addSubview(containerView)
        containerView.addSubview(searchBar)
        containerView.addSubview(mapView)

        searchBar.delegate = mapSearchController
        searchBar.placeholder = "Search for places"

        // Use Auto Layout to position containerView
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Use Auto Layout to position searchBar and mapView within containerView
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        mapView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: containerView.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            mapView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
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
        userTrackingButton.isHidden = true
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
        mapView.register(LocationAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.register(ClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
    }

    // Load event locations and add them as annotations
    private func loadLocationAnnotations() {
        let locationAnnotations = eventLocations.map { Location(coordinate: $0) }
        mapView.addAnnotations(locationAnnotations)
    }
}

// MARK: - MapSearchControllerDelegate
extension MapController: MapSearchControllerDelegate {
    func didSelectSearchResult(_ coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
//        mapView.addAnnotation(annotation)

        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: true)
    }
}

// MARK: - MKMapViewDelegate
extension MapController {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? Location else { return nil }
        
        return LocationAnnotationView(annotation: annotation, reuseIdentifier: LocationAnnotationView.ReuseID)
    }
}

// MARK: - CLLocationManagerDelegate
extension MapController {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let locationAuthorized = status == .authorizedWhenInUse
        userTrackingButton.isHidden = !locationAuthorized
    }
}
