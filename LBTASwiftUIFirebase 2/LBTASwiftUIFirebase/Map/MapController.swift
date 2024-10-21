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
        CLLocationCoordinate2D(latitude: 37.7755, longitude: -122.4200), // San Francisco

        CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437), // Los Angeles
        CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),  // New York
        CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),   // London
        CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)     // Paris
    ]
    
    private var allAnnotations: [Location] = [] // Add this to store all annotations
    
    private lazy var dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.alpha = 0
        return view
    }()


    private func loadLocationAnnotations() {
        let locationAnnotations = eventLocations.map { Location(coordinate: $0) }
        allAnnotations = locationAnnotations
        mapView.addAnnotations(locationAnnotations)
    }

    private lazy var mapSearchController: MapSearchController = {
        let controller = MapSearchController(mapView: mapView)
        controller.delegate = self
        return controller
    }()
    
    func resetAnnotationViews() {
        
        // Remove all annotations except user location
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        
        // Re-add all original annotations to restore clustering
//        mapView.addAnnotations(allAnnotations)
        loadLocationAnnotations()
    }


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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Ensure search bar is always on top
        view.bringSubviewToFront(dimmingView)
        view.bringSubviewToFront(searchBar)
    }


    private func setupUI() {
        view.addSubview(mapView) // Add only the map view to fill the entire screen
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dimmingView)


        // Set the delegate and search bar properties
        searchBar.delegate = mapSearchController
        searchBar.placeholder = "Search for places"

        // Customize the search bar
        searchBar.backgroundImage = UIImage() // Remove the default background
        searchBar.layer.cornerRadius = 20 // Rounded edges
        searchBar.clipsToBounds = true // Ensure the rounded corners are applied
        searchBar.backgroundColor = UIColor.clear // Make background transparent
        searchBar.showsCancelButton = true  // Add this line


        // Adjust the text field appearance
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.layer.cornerRadius = 20 // Rounded edges
            textField.clipsToBounds = true // Ensure the corners are applied
            textField.backgroundColor = UIColor.white.withAlphaComponent(0.8) // Optional: semi-transparent
            textField.borderStyle = .roundedRect // Add rounded borders
            textField.textColor = .black // Set text color
        }

        // Use Auto Layout to position the search bar
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar) // Add search bar on top of the map view

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16), // Add some padding
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            dimmingView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

        ])

        // Use Auto Layout for the map view to fill the entire screen
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
        

}

// MARK: - MapSearchControllerDelegate
extension MapController: MapSearchControllerDelegate {
    func didSelectSearchResult(region: MKCoordinateRegion) {
        // Set the map region to show the entire city
        mapView.setRegion(region, animated: true)
        
        // Get annotations within the region
        let annotationsInRegion = allAnnotations.filter { annotation in
            return region.contains(coordinate: annotation.coordinate)
        }
        
        for annotation in mapView.annotations {
            if let view = mapView.view(for: annotation) {
                // Skip user location annotation
                if annotation is MKUserLocation {
                    continue
                }
                
                // Handle cluster annotations differently
                if annotation is MKClusterAnnotation {
                    // Keep clusters visible but update their member annotations
                    if let cluster = annotation as? MKClusterAnnotation {
                        let hasVisibleMembers = cluster.memberAnnotations.contains { member in
                            if let location = member as? Location {
                                return annotationsInRegion.contains(location)
                            }
                            return false
                        }
//                        view.alpha = hasVisibleMembers ? 1.0 : 0.2
                        view.isEnabled = hasVisibleMembers
                    }
                } else if let location = annotation as? Location {
                    // Handle regular location annotations
                    let isInRegion = annotationsInRegion.contains(location)
//                    view.alpha = isInRegion ? 1.0 : 0.2
                    view.isEnabled = isInRegion
                }
            }
        }

        UIView.animate(withDuration: 0.3) {
            self.dimmingView.alpha = 0
        }

        
    }
    
    func didStartSearch() {
        // Called when search begins
        UIView.animate(withDuration: 0.3) {
            self.dimmingView.alpha = 1
        }
    }
    
    func didEndSearch() {
        // Called when search ends (e.g., when cancel is tapped)
        UIView.animate(withDuration: 0.3) {
            self.dimmingView.alpha = 0
        }
        resetAnnotationViews()
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

extension MKCoordinateRegion {
    func contains(coordinate: CLLocationCoordinate2D) -> Bool {
        let center = self.center
        let span = self.span
        
        let latDelta = span.latitudeDelta / 2.0
        let lngDelta = span.longitudeDelta / 2.0
        
        let minLat = center.latitude - latDelta
        let maxLat = center.latitude + latDelta
        let minLng = center.longitude - lngDelta
        let maxLng = center.longitude + lngDelta
        
        return coordinate.latitude >= minLat &&
               coordinate.latitude <= maxLat &&
               coordinate.longitude >= minLng &&
               coordinate.longitude <= maxLng
    }
}

extension MapController: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = true
        return true
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = false
        return true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Let the search controller handle its UI cleanup
        mapSearchController.searchBarCancelButtonClicked(searchBar)
        
        // Reset map view's annotations without modifying them
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
//        mapView.addAnnotations(allAnnotations)
        loadLocationAnnotations()
        
        searchBar.resignFirstResponder()
    }

}
