//
//  MapController.swift
//  LBTASwiftUIFirebase
//
//  Created by Saadman Rahman on 2024-10-18.
//

import MapKit
import UIKit

class LocationManager {
    static let shared = LocationManager()
    @Published var eventLocations: [(String, Double, CLLocationCoordinate2D)] = []
        
    func startListeningToLocations(completion: @escaping ([(String, Double, CLLocationCoordinate2D)]) -> Void) {
        FirebaseManager.shared.firestore.collection("locations")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching locations: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                var locations: [(String, Double, CLLocationCoordinate2D)] = []
                
                snapshot?.documents.forEach { document in
                    let data = document.data()
                    
                    if let address = data["address"] as? String,
                       let averageRating = data["average_rating"] as? Double,
                       let coordinates = data["location_coordinates"] as? [Double],
                       coordinates.count == 2 {
                        
                        let coordinate = CLLocationCoordinate2D(
                            latitude: coordinates[0],
                            longitude: coordinates[1]
                        )
                        
                        locations.append((address, averageRating, coordinate))
                    }
                }
                
                self.eventLocations = locations
                completion(locations)
            }
    }

}

class MapController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    private let mapView = MKMapView()
    private let searchBar = UISearchBar()
    private let containerView = UIView()
    private let userManager = UserManager()
    private let locationManager = CLLocationManager()
    private let locationDataManager = LocationManager.shared
    private var eventLocations: [(String, Double, CLLocationCoordinate2D)] = []
    private var allAnnotations: [Location] = []
    private var userTrackingButton: MKUserTrackingButton!
    private var scaleView: MKScaleView!
    private let locationInfoScrollView = UIScrollView()
    private var locationInfoViews: [LocationInfoView] = [] // To hold instances

        
    private lazy var dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.alpha = 0
        return view
    }()


    private lazy var mapSearchController: MapSearchController = {
        let controller = MapSearchController(mapView: mapView, searchBar: searchBar)
        controller.delegate = self
        return controller
    }()
        
    @objc private func mapTapped() {
        locationInfoScrollView.isHidden = true 
    }



    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCompassButton()
        setupUserTrackingButtonAndScaleView()
        registerAnnotationViewClasses()
        setupLocationInfoScrollView()

        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        // Start listening for location updates
        startListeningToLocations()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(mapTapped))
        mapView.addGestureRecognizer(tapGesture)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Ensure search bar is always on top
        view.bringSubviewToFront(dimmingView)
        view.bringSubviewToFront(searchBar)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        locationManager.stopUpdatingLocation()
        searchBar.resignFirstResponder()
        mapSearchController.hideSuggestions()
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
    
    private func setupLocationInfoScrollView() {
        locationInfoScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(locationInfoScrollView)

        // Set constraints for the scroll view
        NSLayoutConstraint.activate([
            locationInfoScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            locationInfoScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            locationInfoScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            locationInfoScrollView.heightAnchor.constraint(equalToConstant: 100) // Adjust height as needed
        ])

        locationInfoScrollView.isHidden = true // Initially hidden
    }


    private func registerAnnotationViewClasses() {
        mapView.register(LocationAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.register(ClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
    }
    
    private func startListeningToLocations() {
        LocationManager.shared.startListeningToLocations { [weak self] locations in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.eventLocations = locations
                self.loadLocationAnnotations()
            }
        }
    }

    private func loadLocationAnnotations() {
        // Remove existing annotations except user location
        let existingAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(existingAnnotations)
        
        // Create and add new annotations
        let locationAnnotations = eventLocations.map { Location(name: $0, rating: $1, coordinate: $2) }
        allAnnotations = locationAnnotations
        mapView.addAnnotations(locationAnnotations)
    }

    func resetAnnotationViews() {
        // Remove all annotations except user location
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        
        // Re-add all annotations
        loadLocationAnnotations()
    }


    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let cluster = view.annotation as? MKClusterAnnotation {
            showClusterInfo(for: cluster)
        } else if let locationAnnotation = view.annotation as? Location {
            showLocationInfo(for: locationAnnotation)
        }
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        locationInfoScrollView.isHidden = true // Hide the info view when deselecting
    }
    
    private func showClusterInfo(for cluster: MKClusterAnnotation) {
        // Remove any existing info views
        for infoView in locationInfoViews {
            infoView.removeFromSuperview()
        }
        locationInfoViews.removeAll()

        // Create and configure a LocationInfoView for each member in the cluster
        let clusterLocations = cluster.memberAnnotations.compactMap { $0 as? Location }
        var previousInfoView: LocationInfoView?

        for location in clusterLocations {
            let infoView = LocationInfoView(frame: .zero, userManager: userManager)
            infoView.configure(with: location)
            infoView.translatesAutoresizingMaskIntoConstraints = false
            locationInfoScrollView.addSubview(infoView)
            locationInfoViews.append(infoView)

            // Set constraints for each info view
            NSLayoutConstraint.activate([
                infoView.topAnchor.constraint(equalTo: locationInfoScrollView.topAnchor),
                infoView.bottomAnchor.constraint(equalTo: locationInfoScrollView.bottomAnchor),
                infoView.widthAnchor.constraint(equalTo: locationInfoScrollView.widthAnchor, multiplier: 1) // Width for each info view
            ])

            // Position the info views horizontally
            if let previous = previousInfoView {
                infoView.leadingAnchor.constraint(equalTo: previous.trailingAnchor, constant: 16).isActive = true
            } else {
                infoView.leadingAnchor.constraint(equalTo: locationInfoScrollView.leadingAnchor).isActive = true
            }
            
            previousInfoView = infoView
        }

        // Set the trailing constraint for the last info view
        if let lastInfoView = locationInfoViews.last {
            lastInfoView.trailingAnchor.constraint(equalTo: locationInfoScrollView.trailingAnchor).isActive = true
        }

        locationInfoScrollView.contentSize = CGSize(width: (UIScreen.main.bounds.width - 32) * 0.8 * CGFloat(locationInfoViews.count) + CGFloat(16 * (locationInfoViews.count - 1)), height: 100) // Update content size
        locationInfoScrollView.isHidden = false // Show the scroll view
    }
    
    private func showLocationInfo(for location: Location) {
        for infoView in locationInfoViews {
            infoView.removeFromSuperview()
        }
        locationInfoViews.removeAll()
        
        let infoView = LocationInfoView(frame: .zero, userManager: userManager)
        infoView.configure(with: location)
        locationInfoScrollView.addSubview(infoView)
        locationInfoViews.append(infoView)
        
        infoView.translatesAutoresizingMaskIntoConstraints = false
        
        // Set constraints for single info view
        NSLayoutConstraint.activate([
            infoView.topAnchor.constraint(equalTo: locationInfoScrollView.topAnchor),
            infoView.bottomAnchor.constraint(equalTo: locationInfoScrollView.bottomAnchor),
            infoView.leadingAnchor.constraint(equalTo: locationInfoScrollView.leadingAnchor),
            infoView.trailingAnchor.constraint(equalTo: locationInfoScrollView.trailingAnchor),
            infoView.widthAnchor.constraint(equalTo: locationInfoScrollView.widthAnchor, multiplier: 1) // Width for each info view
        ])
        
        locationInfoScrollView.contentSize = CGSize(width: UIScreen.main.bounds.width - 32, height: 100)
        locationInfoScrollView.isHidden = false // Show the scroll view
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

