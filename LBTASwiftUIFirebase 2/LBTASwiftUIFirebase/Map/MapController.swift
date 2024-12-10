//
//  MapController.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 


// THE MAP FUNCTIONALITY HAS BEEN TAKEN WITH ADVICE FROM THE FOLLOWING DOCUMENTATION:
// https://developer.apple.com/documentation/mapkit/mkannotationview/decluttering_a_map_with_mapkit_annotation_clustering

// this is the git repository that has inspired the implementation of this:

// https://github.com/johnantoni/mapkit-clustering




import MapKit
import UIKit
import SwiftUI

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

    // MARK: - Properties
    // Core map components and managers
    private let mapView = MKMapView()
    private let searchBar = UISearchBar()
    private let containerView = UIView()
    private let userManager = UserManager()
    private let locationManager = CLLocationManager()
    private let locationDataManager = LocationManager.shared
    
    // Data storage
    private var eventLocations: [(String, Double, CLLocationCoordinate2D)] = []
    private var allAnnotations: [Location] = []
    
    // UI Components
    private var userTrackingButton: MKUserTrackingButton!
    private var scaleView: MKScaleView!
    private let locationInfoScrollView = UIScrollView()
    private var locationInfoViews: [LocationInfoView] = []
    private var hotspotButtonBottomConstraint: NSLayoutConstraint?

        
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
        adjustHotspotButtonPosition(show: false)
    }
    
    private let hotspotButton: UIButton = {
        let button = UIButton(type: .system)
                
        let attributedString = NSMutableAttributedString(string: "Hotspots ")
        let flameAttachment = NSTextAttachment()
        flameAttachment.image = UIImage(systemName: "flame.fill")?.withTintColor(.black)
        attributedString.append(NSAttributedString(attachment: flameAttachment))

        button.setAttributedTitle(attributedString, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.setTitleColor(.black, for: .normal)
        
        // Configure appearance
        button.backgroundColor = UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1.0)
        button.layer.cornerRadius = 20
        
        // shadow
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.2
        
        // highlight state
        button.addTarget(self, action: #selector(buttonTouchDown), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp), for: [.touchUpInside, .touchUpOutside])
        
        return button
    }()

    @objc private func buttonTouchDown() {
        UIView.animate(withDuration: 0.1) {
            self.hotspotButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.hotspotButton.backgroundColor = UIColor(red: 255/255, green: 200/255, blue: 0/255, alpha: 1.0)
        }
    }

    @objc private func buttonTouchUp() {
        UIView.animate(withDuration: 0.1) {
            self.hotspotButton.transform = .identity
            self.hotspotButton.backgroundColor = UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1.0)
        }
    }

    // MARK: - View Lifecycle Methods
    
    /// Initial setup of the map view and its components

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCompassButton()
        setupUserTrackingButtonAndScaleView()
        registerAnnotationViewClasses()
        setupLocationInfoScrollView()
        setupHotspotButton()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        // listening for location updates
        startListeningToLocations()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(mapTapped))
        mapView.addGestureRecognizer(tapGesture)
    }

    /// Ensures proper view hierarchy for overlays
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        view.bringSubviewToFront(dimmingView)
        view.bringSubviewToFront(searchBar)
    }
    
    /// Cleanup when view disappears
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        locationManager.stopUpdatingLocation()
        searchBar.resignFirstResponder()
        mapSearchController.hideSuggestions()
    }

    // MARK: - Setup Methods
    
    /// Configures main UI components including map and search bar
    private func setupUI() {
        view.addSubview(mapView)
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dimmingView)


        // delegate and search bar properties
        searchBar.delegate = mapSearchController
        searchBar.placeholder = "Search for places"

        // Customize the search bar
        searchBar.backgroundImage = UIImage()
        searchBar.layer.cornerRadius = 20
        searchBar.clipsToBounds = true
        searchBar.backgroundColor = UIColor.clear
        searchBar.showsCancelButton = true


        // Adjust the text field appearance
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.layer.cornerRadius = 20
            textField.clipsToBounds = true
            textField.backgroundColor = UIColor.white.withAlphaComponent(0.8)
            textField.borderStyle = .roundedRect
            textField.textColor = .black
        }

        // Use Auto Layout to position the search bar
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
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

    /// Sets up the compass button in navigation bar
    private func setupCompassButton() {
        let compass = MKCompassButton(mapView: mapView)
        compass.compassVisibility = .visible
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: compass)
        mapView.showsCompass = false
    }

    /// Configures user tracking button and map scale view
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
    /// Initializes the scroll view for location information
    private func setupLocationInfoScrollView() {
        locationInfoScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(locationInfoScrollView)

        // Set constraints for the scroll view
        NSLayoutConstraint.activate([
            locationInfoScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            locationInfoScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            locationInfoScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            locationInfoScrollView.heightAnchor.constraint(equalToConstant: 100)
        ])

        locationInfoScrollView.isHidden = true // Initially hidden
    }
    
    /// Sets up the hotspot button with animations
    private func setupHotspotButton() {
        view.addSubview(hotspotButton)
        hotspotButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Get safe area bottom inset
        let window = UIApplication.shared.windows.first
        let bottomPadding = window?.safeAreaInsets.bottom ?? 0
        
        // Store the bottom constraint so we can modify it later
        let bottomConstraint = hotspotButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(bottomPadding + 100))
        
        NSLayoutConstraint.activate([
            hotspotButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hotspotButton.widthAnchor.constraint(equalToConstant: 140),
            hotspotButton.heightAnchor.constraint(equalToConstant: 40),
            bottomConstraint
        ])
        
        hotspotButtonBottomConstraint = bottomConstraint
        hotspotButton.addTarget(self, action: #selector(hotspotButtonTapped), for: .touchUpInside)
    }

    @objc private func hotspotButtonTapped() {
        print("Hotspot button tapped!")
        // Create the Hotspots SwiftUI view
        let hotspotsView = Hotspots()
            
        // Wrap the SwiftUI view in a UIHostingController
        let hostingController = UIHostingController(rootView: hotspotsView)
            
        // Push the UIHostingController onto the navigation stack
        self.navigationController?.pushViewController(hostingController, animated: true)
    }
    



    // MARK: - Location and Annotation Methods
    
    /// Registers custom annotation view classes with the map
    private func registerAnnotationViewClasses() {
        mapView.register(LocationAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.register(ClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
    }
    
    /// Starts listening for location updates from Firebase
    private func startListeningToLocations() {
        LocationManager.shared.startListeningToLocations { [weak self] locations in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.eventLocations = locations
                self.loadLocationAnnotations()
            }
        }
    }

    /// Loads location annotations onto the map
    private func loadLocationAnnotations() {
        let existingAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(existingAnnotations)
        
        let locationAnnotations = eventLocations.map { Location(name: $0, rating: $1, coordinate: $2) }
        allAnnotations = locationAnnotations
        mapView.addAnnotations(locationAnnotations)
    }
    
    /// Resets all annotations on the map
    func resetAnnotationViews() {
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        
        loadLocationAnnotations()
    }

    // MARK: - UI Update Methods
    
    /// Adjusts the position of the hotspot button based on info view visibility
    private func adjustHotspotButtonPosition(show: Bool) {
        let window = UIApplication.shared.windows.first
        let bottomPadding = window?.safeAreaInsets.bottom ?? 0
        
        view.bringSubviewToFront(hotspotButton)
        
        // Animate the position change
        UIView.animate(withDuration: 0.3) {
            if show {
                self.hotspotButtonBottomConstraint?.constant = -(bottomPadding + 100 + self.locationInfoScrollView.frame.height)
            } else {
                self.hotspotButtonBottomConstraint?.constant = -(bottomPadding + 100)
            }
            self.view.layoutIfNeeded()
        }
    }
    
    /// Displays information for a cluster of locations
    private func showClusterInfo(for cluster: MKClusterAnnotation) {
        for infoView in locationInfoViews {
            infoView.removeFromSuperview()
        }
        locationInfoViews.removeAll()

        let clusterLocations = cluster.memberAnnotations.compactMap { $0 as? Location }
        var previousInfoView: LocationInfoView?

        for location in clusterLocations {
            let infoView = LocationInfoView(frame: .zero, userManager: userManager)
            infoView.configure(with: location)
            infoView.translatesAutoresizingMaskIntoConstraints = false
            locationInfoScrollView.addSubview(infoView)
            locationInfoViews.append(infoView)

            NSLayoutConstraint.activate([
                infoView.topAnchor.constraint(equalTo: locationInfoScrollView.topAnchor),
                infoView.bottomAnchor.constraint(equalTo: locationInfoScrollView.bottomAnchor),
                infoView.widthAnchor.constraint(equalTo: locationInfoScrollView.widthAnchor, multiplier: 1) // Width for each info view
            ])

            if let previous = previousInfoView {
                infoView.leadingAnchor.constraint(equalTo: previous.trailingAnchor, constant: 16).isActive = true
            } else {
                infoView.leadingAnchor.constraint(equalTo: locationInfoScrollView.leadingAnchor).isActive = true
            }
            
            previousInfoView = infoView
        }

        if let lastInfoView = locationInfoViews.last {
            lastInfoView.trailingAnchor.constraint(equalTo: locationInfoScrollView.trailingAnchor).isActive = true
        }

        locationInfoScrollView.contentSize = CGSize(width: (UIScreen.main.bounds.width - 32) * 0.8 * CGFloat(locationInfoViews.count) + CGFloat(16 * (locationInfoViews.count - 1)), height: 100) // Update content size
        locationInfoScrollView.isHidden = false // Show the scroll view
    }
    
    /// Displays information for a single location
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
        
        NSLayoutConstraint.activate([
            infoView.topAnchor.constraint(equalTo: locationInfoScrollView.topAnchor),
            infoView.bottomAnchor.constraint(equalTo: locationInfoScrollView.bottomAnchor),
            infoView.leadingAnchor.constraint(equalTo: locationInfoScrollView.leadingAnchor),
            infoView.trailingAnchor.constraint(equalTo: locationInfoScrollView.trailingAnchor),
            infoView.widthAnchor.constraint(equalTo: locationInfoScrollView.widthAnchor, multiplier: 1)
        ])
        
        locationInfoScrollView.contentSize = CGSize(width: UIScreen.main.bounds.width - 32, height: 100)
        locationInfoScrollView.isHidden = false
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let cluster = view.annotation as? MKClusterAnnotation {
            showClusterInfo(for: cluster)
            adjustHotspotButtonPosition(show: true)
        } else if let locationAnnotation = view.annotation as? Location {
            showLocationInfo(for: locationAnnotation)
            adjustHotspotButtonPosition(show: true)
        }
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        locationInfoScrollView.isHidden = true
        adjustHotspotButtonPosition(show: false)
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
                        view.isEnabled = hasVisibleMembers
                    }
                } else if let location = annotation as? Location {
                    let isInRegion = annotationsInRegion.contains(location)
                    view.isEnabled = isInRegion
                }
            }
        }

        UIView.animate(withDuration: 0.3) {
            self.dimmingView.alpha = 0
        }

        
    }
    
    func didStartSearch() {
        UIView.animate(withDuration: 0.3) {
            self.dimmingView.alpha = 1
        }
    }
    
    func didEndSearch() {
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
        mapSearchController.searchBarCancelButtonClicked(searchBar)
        
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        loadLocationAnnotations()
        
        searchBar.resignFirstResponder()
    }

}

