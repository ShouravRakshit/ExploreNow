//
//  MapController.swift
//  ExploreNow
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
    // Singleton pattern to ensure there's only one instance of LocationManager throughout the app
    static let shared = LocationManager()
    // Published property to store and observe the event locations
    @Published var eventLocations: [(String, Double, CLLocationCoordinate2D)] = []
        
    // Method to start listening for location updates from Firebase
    func startListeningToLocations(completion: @escaping ([(String, Double, CLLocationCoordinate2D)]) -> Void) {
        // Listening to changes in the "locations" collection in Firestore
        FirebaseManager.shared.firestore.collection("locations")
            .addSnapshotListener { snapshot, error in
                // Handle any errors during the fetching of data
                if let error = error {
                    print("Error fetching locations: \(error.localizedDescription)")
                    completion([]) // Return empty list if an error occurs
                    return
                }
                
                // Initialize an array to store locations
                var locations: [(String, Double, CLLocationCoordinate2D)] = []
                
                // Iterate over the documents in the snapshot
                snapshot?.documents.forEach { document in
                    let data = document.data()
                    
                    // Extract relevant data from the document
                    if let address = data["address"] as? String,
                       let averageRating = data["average_rating"] as? Double,
                       let coordinates = data["location_coordinates"] as? [Double],
                       coordinates.count == 2 { // Check if coordinates have exactly 2 values (latitude and longitude)
                        
                        // Create a CLLocationCoordinate2D object using the extracted coordinates
                        let coordinate = CLLocationCoordinate2D(
                            latitude: coordinates[0],
                            longitude: coordinates[1]
                        )
                        // Append the location data (address, average rating, and coordinate) to the array
                        locations.append((address, averageRating, coordinate))
                    }
                }
                // Update the published eventLocations property
                self.eventLocations = locations
                // Return the locations array via the completion handler
                completion(locations)
            }
    }

}

class MapController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    // MARK: - Properties
    // Core map components and managers
    private let mapView = MKMapView()
    // MKMapView is a map component that displays a map and allows annotations, overlays, and user interactions.
    private let searchBar = UISearchBar()
    // UISearchBar allows the user to search for locations or places on the map.
    private let containerView = UIView()
    // Container for other UI components, used to organize layout within the view.
    private let userManager = UserManager()
    // UserManager handles user-related functionality, potentially for managing user-specific data.
    private let locationManager = CLLocationManager()
    // CLLocationManager is used for tracking the user's location and asking for location permissions.
    private let locationDataManager = LocationManager.shared
    // Singleton instance of LocationManager that handles location data from Firestore.
    
    // Data storage
    private var eventLocations: [(String, Double, CLLocationCoordinate2D)] = []
    // Array to store event locations with the address, rating, and coordinates.
    private var allAnnotations: [Location] = []
    // Array to store all location annotations on the map.
    
    // UI Components
    private var userTrackingButton: MKUserTrackingButton!
    // MKUserTrackingButton allows the user to toggle tracking of their current location on the map.
    private var scaleView: MKScaleView!
    // MKScaleView displays the scale of the map, giving the user context of the map's zoom level.
    private let locationInfoScrollView = UIScrollView()
    // UIScrollView holds the information views of locations, allowing scrolling through various locations.
    private var locationInfoViews: [LocationInfoView] = []
    // Array to hold custom views that display detailed location information (e.g., address, rating).
    private var hotspotButtonBottomConstraint: NSLayoutConstraint?
    // A layout constraint that may be used to control the position of a "hotspot" button on the map.
        
    // MARK: - Dimming View
    private lazy var dimmingView: UIView = {
        let view = UIView()  // Create a new UIView instance for dimming
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)  // Set the background color to black with 30% opacity, creating a dim effect
        view.alpha = 0 // Set the initial alpha to 0, making the view invisible by default
        return view  // Return the configured dimming view
    }()


    private lazy var mapSearchController: MapSearchController = {
        let controller = MapSearchController(mapView: mapView, searchBar: searchBar) // Initialize the map search controller with the map view and search bar
        controller.delegate = self // Set the MapController as the delegate for the search controller, allowing it to receive search events
        return controller // Return the fully configured map search controller
    }()
        
    @objc private func mapTapped() {
        locationInfoScrollView.isHidden = true // Hide the location info scroll view when the map is tapped
        adjustHotspotButtonPosition(show: false) // Adjust the position of the hotspot button, likely hiding or repositioning it
    }
    
    // MARK: - Hotspot Button Setup
    private let hotspotButton: UIButton = {
        // Initialize a UIButton with a system type, which comes with default styles for touch events
        let button = UIButton(type: .system)
                
        // Create an attributed string for the button's title that includes both text and an image (flame symbol)
        let attributedString = NSMutableAttributedString(string: "Hotspots ")
        
        // Create a NSTextAttachment to embed an image (flame symbol) into the attributed string
        let flameAttachment = NSTextAttachment()
        flameAttachment.image = UIImage(systemName: "flame.fill")?.withTintColor(.black)
        
        // Append the flame image to the existing string
        attributedString.append(NSAttributedString(attachment: flameAttachment))

        // Set the created attributed string as the title of the button for the normal state
        button.setAttributedTitle(attributedString, for: .normal)
        // Customize the font of the button's title to system font, size 16, and semibold weight
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        // Set the color of the button's title to black for the normal state
        button.setTitleColor(.black, for: .normal)
        
        // Configure the appearance of the button
        button.backgroundColor = UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1.0) // Set a custom yellow color for the background
        button.layer.cornerRadius = 20 // Round the button's corners with a radius of 20 points
        
        // Add shadow effects to the button to make it stand out visually
        button.layer.shadowColor = UIColor.black.cgColor // Set the shadow color to black
        button.layer.shadowOffset = CGSize(width: 0, height: 2) // Set the shadow's offset
        button.layer.shadowRadius = 4 // Set the blur radius of the shadow
        button.layer.shadowOpacity = 0.2 // Set the opacity of the shadow
        
        // Configure highlight effects: change button appearance when it's pressed
        button.addTarget(self, action: #selector(buttonTouchDown), for: .touchDown) // Handle button touch down event
        button.addTarget(self, action: #selector(buttonTouchUp), for: [.touchUpInside, .touchUpOutside]) // Handle touch up events (either inside or outside the button)
        
        return button  // Return the fully configured button
    }()

    // MARK: - Button Touch Down and Up Animation

    // Called when the button is pressed down (touch begins)
    @objc private func buttonTouchDown() {
        // Animate changes with a short duration (0.1 seconds)
        UIView.animate(withDuration: 0.1) {
            // Scale down the button slightly when it's pressed to provide visual feedback
            self.hotspotButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            // Change the button's background color to a slightly darker yellow during press
            self.hotspotButton.backgroundColor = UIColor(red: 255/255, green: 200/255, blue: 0/255, alpha: 1.0)
        }
    }

    // Called when the button is released (touch ends), either inside or outside the button
    @objc private func buttonTouchUp() {
        // Animate changes back to the default state with a short duration (0.1 seconds)
        UIView.animate(withDuration: 0.1) {
            // Reset the button's scale back to its original size
            self.hotspotButton.transform = .identity
            // Restore the original background color (lighter yellow)
            self.hotspotButton.backgroundColor = UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1.0)
        }
    }

    // MARK: - View Lifecycle Methods

    /// Initial setup of the map view and its components

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set up user interface components like search bar, buttons, and map view
        setupUI()
        // Set up compass button for map orientation control
        setupCompassButton()
        // Set up the user tracking button and scale view for tracking location
        setupUserTrackingButtonAndScaleView()
        // Register annotation view classes to display custom annotations on the map
        registerAnnotationViewClasses()
        // Set up scroll view for displaying location information when selected
        setupLocationInfoScrollView()
        // Set up a button that interacts with hotspots
        setupHotspotButton()
        // Set location manager delegate to self to handle location updates
        locationManager.delegate = self
        // Request permission to access the user's location when in use
        locationManager.requestWhenInUseAuthorization()
        // Start updating the user's location
        locationManager.startUpdatingLocation()

        // Start listening for location updates from Firebase (event locations)
        startListeningToLocations()
        // Add gesture recognizer to detect taps on the map
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(mapTapped))
        mapView.addGestureRecognizer(tapGesture)
    }

    /// Ensures proper view hierarchy for overlays
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure dimming view is in front of other views
        view.bringSubviewToFront(dimmingView)
        // Ensure search bar is in front of other views
        view.bringSubviewToFront(searchBar)
    }
    
    /// Cleanup when view disappears
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Stop updating the user's location when the view is about to disappear
        locationManager.stopUpdatingLocation()
        // Resign first responder from the search bar (hides the keyboard if visible)
        searchBar.resignFirstResponder()
        // Hide the search suggestions from the map search controller when the view disappears
        mapSearchController.hideSuggestions()
    }

    // MARK: - Setup Methods
    
    /// Configures main UI components including map and search bar
    private func setupUI() {
        // Add the map view to the view hierarchy
        view.addSubview(mapView)
        mapView.delegate = self
        mapView.showsUserLocation = true  // Show user's location on the map
        
        // Setup the dimming view that will be used for UI overlays
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dimmingView)


        // Set up the search bar delegate and placeholder text
        searchBar.delegate = mapSearchController
        searchBar.placeholder = "Search for places"

        // Customize the search bar's appearance
        searchBar.backgroundImage = UIImage() // Remove default background image
        searchBar.layer.cornerRadius = 20 // Apply rounded corners
        searchBar.clipsToBounds = true // Ensure the rounded corners are visible
        searchBar.backgroundColor = UIColor.clear // Set a clear background
        searchBar.showsCancelButton = true // Show the cancel button on the search bar


        // Customize the search field within the search bar (i.e., the text input area)
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.layer.cornerRadius = 20  // Apply rounded corners to the text field
            textField.clipsToBounds = true // Ensure rounded corners are applied
            textField.backgroundColor = UIColor.white.withAlphaComponent(0.8) // Set a light white background with some transparency
            textField.borderStyle = .roundedRect // Apply a rounded rectangle border style
            textField.textColor = .black // Set the text color to black
        }

        // Use Auto Layout to position the search bar
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)

        // Activate Auto Layout constraints for the search bar
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Activate Auto Layout constraints for the search bar
            dimmingView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

        ])

        // Use Auto Layout for the map view to fill the entire screen
        mapView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor), // Pin the top of the map view to the top of the parent view
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor), // Pin the left side of the map view to the left side of the parent view
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor), // Pin the right side of the map view to the right side of the parent view
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor) // Pin the bottom of the map view to the bottom of the parent view
        ])
    }

    /// Sets up the compass button in navigation bar
    private func setupCompassButton() {
        // Create a MKCompassButton that will be linked to the mapView
        let compass = MKCompassButton(mapView: mapView)
        compass.compassVisibility = .visible // Make sure the compass button is visible
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: compass) // Add the compass button to the navigation bar's right side
        mapView.showsCompass = false  // Disable the default compass view in the map, as the button is handling it
    }

    /// Configures user tracking button and map scale view
    private func setupUserTrackingButtonAndScaleView() {
        // Enable user location tracking on the map
        mapView.showsUserLocation = true
        // Create a user tracking button that allows users to center the map on their location
        userTrackingButton = MKUserTrackingButton(mapView: mapView)
        userTrackingButton.isHidden = true // Initially hide the user tracking button
        // Add the user tracking button to the navigation bar's left side
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: userTrackingButton)

        // Create a map scale view that shows the scale of the map
        scaleView = MKScaleView(mapView: mapView)
        scaleView.legendAlignment = .trailing // Align the scale view legend to the right
        view.addSubview(scaleView) // Add the scale view to the view hierarchy
        
        // Create a horizontal stack view to hold the scale view and user tracking button
        let stackView = UIStackView(arrangedSubviews: [scaleView, userTrackingButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal // Arrange the elements horizontally
        stackView.alignment = .center // Center the elements within the stack view
        stackView.spacing = 10   // Add some spacing between the elements
        view.addSubview(stackView)  // Add the stack view to the view hierarchy

        // Apply Auto Layout constraints to position the stack view at the bottom-right corner
        NSLayoutConstraint.activate([
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10), // Pin the stack view 10 points above the bottom safe area
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10)  // Pin the stack view 10 points from the right safe area
        ])
    }
    
    /// Initializes the scroll view for location information
    private func setupLocationInfoScrollView() {
        // Disable autoresizing mask to use Auto Layout
        locationInfoScrollView.translatesAutoresizingMaskIntoConstraints = false
        // Add the scroll view to the main view
        view.addSubview(locationInfoScrollView)

        // Set constraints for the scroll view to position it within the view
        NSLayoutConstraint.activate([
            locationInfoScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16), // 16 points from the left edge
            locationInfoScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16), // 16 points from the right edge
            locationInfoScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16), // 16 points above the bottom safe area
            locationInfoScrollView.heightAnchor.constraint(equalToConstant: 100) // Fixed height of 100 points
        ])

        // Initially hide the scroll view; this can be updated later based on the context
        locationInfoScrollView.isHidden = true // Initially hidden
    }
    
    /// Sets up the hotspot button with animations
    private func setupHotspotButton() {
        // Add the hotspot button to the view hierarchy
        view.addSubview(hotspotButton)
        // Disable autoresizing mask and use Auto Layout constraints instead
        hotspotButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Get the safe area bottom inset for devices with a home indicator (e.g., iPhone X and newer)
        let window = UIApplication.shared.windows.first
        let bottomPadding = window?.safeAreaInsets.bottom ?? 0
        
        // Create a bottom constraint for the hotspot button, with additional padding from the safe area
        // This will ensure the button is placed above the system home indicator (if any)
        let bottomConstraint = hotspotButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(bottomPadding + 100))
        
        // Activate the Auto Layout constraints for the hotspot button
        NSLayoutConstraint.activate([
            // Center the button horizontally in the view
            hotspotButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            // Set a fixed width and height for the hotspot button
            hotspotButton.widthAnchor.constraint(equalToConstant: 140),
            hotspotButton.heightAnchor.constraint(equalToConstant: 40),
            // Add the previously created bottom constraint to the button
            bottomConstraint
        ])
        // Store the bottom constraint as an instance property so we can adjust it later
        hotspotButtonBottomConstraint = bottomConstraint
        // Add target action to the button: when it is tapped, the method `hotspotButtonTapped` will be triggered
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
        // Register the custom annotation view class for location annotations with a default identifier
        mapView.register(LocationAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        // Register the custom annotation view class for cluster annotations with a default identifier
        mapView.register(ClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
    }
    
    /// Starts listening for location updates from Firebase
    private func startListeningToLocations() {
        // Start listening for location updates via the LocationManager (which is shared across the app)
        LocationManager.shared.startListeningToLocations { [weak self] locations in
            // Safely unwrap the self reference to avoid retain cycles
            guard let self = self else { return }
            // Once location updates are received, update the eventLocations and reload annotations on the main thread
            DispatchQueue.main.async {
                // Update the locations data
                self.eventLocations = locations
                // Load and update the annotations on the map based on the new location data
                self.loadLocationAnnotations()
            }
        }
    }

    /// Loads location annotations onto the map
    private func loadLocationAnnotations() {
        // Remove any existing annotations that are not the user's location
        let existingAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(existingAnnotations)
        
        // Create new annotations based on the eventLocations data and add them to the map
        let locationAnnotations = eventLocations.map { Location(name: $0, rating: $1, coordinate: $2) }
        // Store all annotations for potential future use
        allAnnotations = locationAnnotations
        // Add the newly created annotations to the map view
        mapView.addAnnotations(locationAnnotations)
    }
    
    /// Resets all annotations on the map
    func resetAnnotationViews() {
        // Remove all existing annotations from the map (excluding the user's location)
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        // Reload and add new location annotations to the map
        loadLocationAnnotations()
    }

    // MARK: - UI Update Methods
    
    /// Adjusts the position of the hotspot button based on info view visibility
    private func adjustHotspotButtonPosition(show: Bool) {
        // Get the bottom safe area inset of the window to adjust the button position
        let window = UIApplication.shared.windows.first
        let bottomPadding = window?.safeAreaInsets.bottom ?? 0
        // Bring the hotspot button to the front to ensure it's visible when adjusting its position
        view.bringSubviewToFront(hotspotButton)
        
        // Animate the position change of the hotspot button based on whether the info view is shown or hidden
        UIView.animate(withDuration: 0.3) {
            // Adjust the bottom constraint of the hotspot button based on visibility of the location info view
            if show {
                // If the info view is visible, move the hotspot button upwards to avoid overlap
                self.hotspotButtonBottomConstraint?.constant = -(bottomPadding + 100 + self.locationInfoScrollView.frame.height)
            } else {
                // If the info view is hidden, return the hotspot button to its default position
                self.hotspotButtonBottomConstraint?.constant = -(bottomPadding + 100)
            }
            // Apply the layout changes
            self.view.layoutIfNeeded()
        }
    }
    
    /// Displays information for a cluster of locations
    private func showClusterInfo(for cluster: MKClusterAnnotation) {
        // Remove any existing info views from the locationInfoViews array and the scroll view
        for infoView in locationInfoViews {
            infoView.removeFromSuperview()
        }
        locationInfoViews.removeAll()

        // Extract the member annotations (locations) from the cluster
        let clusterLocations = cluster.memberAnnotations.compactMap { $0 as? Location }
        var previousInfoView: LocationInfoView?

        // Loop through each location in the cluster and create a corresponding info view
        for location in clusterLocations {
            // Create a new LocationInfoView and configure it with the location's data
            let infoView = LocationInfoView(frame: .zero, userManager: userManager)
            infoView.configure(with: location)
            infoView.translatesAutoresizingMaskIntoConstraints = false
            
            // Add the info view to the scroll view and append it to the locationInfoViews array
            locationInfoScrollView.addSubview(infoView)
            locationInfoViews.append(infoView)

            // Set constraints for each info view
            NSLayoutConstraint.activate([
                // Ensure that the top and bottom edges of the info view are anchored to the scroll view's edges
                infoView.topAnchor.constraint(equalTo: locationInfoScrollView.topAnchor),
                infoView.bottomAnchor.constraint(equalTo: locationInfoScrollView.bottomAnchor),
                // Set the width of each info view to 80% of the scroll view's width
                infoView.widthAnchor.constraint(equalTo: locationInfoScrollView.widthAnchor, multiplier: 1) // Width for each info view
            ])

            // Set the leading anchor for the first info view or align it to the previous info view for subsequent ones
            if let previous = previousInfoView {
                infoView.leadingAnchor.constraint(equalTo: previous.trailingAnchor, constant: 16).isActive = true
            } else {
                infoView.leadingAnchor.constraint(equalTo: locationInfoScrollView.leadingAnchor).isActive = true
            }
            
            // Update the previousInfoView to the current infoView for the next iteration
            previousInfoView = infoView
        }
        
        // Ensure that the last info view's trailing anchor is aligned with the scroll view's trailing edge
        if let lastInfoView = locationInfoViews.last {
            lastInfoView.trailingAnchor.constraint(equalTo: locationInfoScrollView.trailingAnchor).isActive = true
        }

        // Update the content size of the scroll view based on the number of info views
        locationInfoScrollView.contentSize = CGSize(width: (UIScreen.main.bounds.width - 32) * 0.8 * CGFloat(locationInfoViews.count) + CGFloat(16 * (locationInfoViews.count - 1)), height: 100) // Set a fixed height for the scroll view content
        // Make the scroll view visible after it has been updated
        locationInfoScrollView.isHidden = false
    }
    
    /// Displays information for a single location
    private func showLocationInfo(for location: Location) {
        // Remove any existing info views from the locationInfoViews array and the scroll view
        for infoView in locationInfoViews {
            infoView.removeFromSuperview()
        }
        locationInfoViews.removeAll()
        
        // Create a new LocationInfoView for the specified location
        let infoView = LocationInfoView(frame: .zero, userManager: userManager)
        infoView.configure(with: location) // Configure the info view with the location data
        
        // Add the newly created info view to the scroll view and append it to the locationInfoViews array
        locationInfoScrollView.addSubview(infoView)
        locationInfoViews.append(infoView)
        
        // Disable the auto-resizing mask for the info view and enable Auto Layout
        infoView.translatesAutoresizingMaskIntoConstraints = false
        
        // Set the constraints for the info view within the scroll view
        NSLayoutConstraint.activate([
            // Pin the top and bottom of the info view to the top and bottom of the scroll view
            infoView.topAnchor.constraint(equalTo: locationInfoScrollView.topAnchor),
            infoView.bottomAnchor.constraint(equalTo: locationInfoScrollView.bottomAnchor),
            // Pin the left and right edges of the info view to the left and right edges of the scroll view
            infoView.leadingAnchor.constraint(equalTo: locationInfoScrollView.leadingAnchor),
            infoView.trailingAnchor.constraint(equalTo: locationInfoScrollView.trailingAnchor),
            // Set the width of the info view to be the same as the scroll view's width
            infoView.widthAnchor.constraint(equalTo: locationInfoScrollView.widthAnchor, multiplier: 1)
        ])
        // Update the content size of the scroll view based on the width of the screen
        locationInfoScrollView.contentSize = CGSize(width: UIScreen.main.bounds.width - 32, height: 100)
        // Make the scroll view visible after it has been updated
        locationInfoScrollView.isHidden = false
    }

    /// Handles the selection of an annotation view on the map
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // Check if the selected annotation is a cluster annotation
        if let cluster = view.annotation as? MKClusterAnnotation {
            // Show information for the selected cluster
            showClusterInfo(for: cluster)
            // Adjust the hotspot button position to accommodate the information view
            adjustHotspotButtonPosition(show: true)
        } // Check if the selected annotation is a location annotation
        else if let locationAnnotation = view.annotation as? Location {
            // Show information for the selected location
            showLocationInfo(for: locationAnnotation)
            // Adjust the hotspot button position to accommodate the information view
            adjustHotspotButtonPosition(show: true)
        }
    }
    
    /// Handles the deselection of an annotation view on the map
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        // Hide the location information scroll view when an annotation is deselected
        locationInfoScrollView.isHidden = true
        // Adjust the hotspot button position back to its initial state
        adjustHotspotButtonPosition(show: false)
    }

    
    



        

}

// MARK: - MapSearchControllerDelegate
extension MapController: MapSearchControllerDelegate {
    /// Handles the selection of a search result and updates the map region and annotation visibility
    func didSelectSearchResult(region: MKCoordinateRegion) {
        // Set the map region to the selected search result region and animate the transition
        // This updates the map's visible area to the new region passed from the search result
        mapView.setRegion(region, animated: true)
        
        // Filter annotations to find those within the selected region
        // This creates a list of all annotations that are inside the selected map region
        let annotationsInRegion = allAnnotations.filter { annotation in
            return region.contains(coordinate: annotation.coordinate)
        }
        
        // Iterate through all the annotations on the map
        for annotation in mapView.annotations {
            // Skip the user's location annotation since it's not relevant here
            if let view = mapView.view(for: annotation) {
                // Skip the user's location annotation as it doesn't need to be processed
                if annotation is MKUserLocation {
                    continue
                }
                
                // Handle cluster annotations differently
                // If the annotation is a cluster, update its member annotations' visibility based on the region
                if annotation is MKClusterAnnotation {
                    // Keep clusters visible but update their member annotations
                    if let cluster = annotation as? MKClusterAnnotation {
                        // Check if any member of the cluster is within the selected region
                        let hasVisibleMembers = cluster.memberAnnotations.contains { member in
                            if let location = member as? Location {
                                // Return true if the member is in the selected region
                                return annotationsInRegion.contains(location)
                            }
                            return false
                        }
                        // Enable or disable the cluster view based on the visibility of its members
                        view.isEnabled = hasVisibleMembers
                    }
                } else if let location = annotation as? Location {
                    // For non-cluster annotations (i.e., individual locations), check if the location is in the region
                    let isInRegion = annotationsInRegion.contains(location)
                    // Enable or disable the location's annotation view based on whether it's in the region
                    view.isEnabled = isInRegion
                }
            }
        }

        // Animate the dimming view to fade out, making it less distracting after the region is updated
        UIView.animate(withDuration: 0.3) {
            self.dimmingView.alpha = 0 // Fades out the dimming view to indicate that the region change is complete
        }

        
    }
    
    // This function is called when the search process begins
    func didStartSearch() {
        // Animate the alpha value of the dimmingView to 1 over 0.3 seconds to show it
        UIView.animate(withDuration: 0.3) {
            self.dimmingView.alpha = 1
        }
    }
    
    // This function is called when the search process ends
    func didEndSearch() {
        // Animate the alpha value of the dimmingView to 0 over 0.3 seconds to hide it
        UIView.animate(withDuration: 0.3) {
            self.dimmingView.alpha = 0
        }
        // Reset any annotation views on the map
        resetAnnotationViews()
    }

    
}



// MARK: - MKMapViewDelegate
extension MapController {
    // MARK: - MKMapViewDelegate
        
    // This method provides a custom annotation view for a specific annotation type.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Safely casting the annotation to a custom type 'Location'.
        guard let annotation = annotation as? Location else { return nil }
        // Return a custom annotation view of type LocationAnnotationView with a reuse identifier.
        return LocationAnnotationView(annotation: annotation, reuseIdentifier: LocationAnnotationView.ReuseID)
    }
    

}

// MARK: - CLLocationManagerDelegate
extension MapController {
    // MARK: - CLLocationManagerDelegate
       
    // Called when the location authorization status changes.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // Check if the location authorization status is 'authorizedWhenInUse'.
        let locationAuthorized = status == .authorizedWhenInUse
        // If the location is authorized, show the user tracking button, otherwise hide it.
        userTrackingButton.isHidden = !locationAuthorized
    }
}

// This extension adds a method to MKCoordinateRegion to check whether a given coordinate
// is within the region's bounds.
extension MKCoordinateRegion {
    // Method to check if a coordinate is inside the MKCoordinateRegion
    func contains(coordinate: CLLocationCoordinate2D) -> Bool {
        // The center of the region (latitude and longitude)
        let center = self.center
        // The span of the region (how much latitude and longitude it covers)
        let span = self.span
        
        // Calculating half the latitude and longitude delta to define the region's boundaries
        let latDelta = span.latitudeDelta / 2.0
        let lngDelta = span.longitudeDelta / 2.0
        
        // Defining the minimum and maximum latitude and longitude values for the region
        let minLat = center.latitude - latDelta
        let maxLat = center.latitude + latDelta
        let minLng = center.longitude - lngDelta
        let maxLng = center.longitude + lngDelta
        
        // Checking if the provided coordinate is within the bounds of the region
        return coordinate.latitude >= minLat &&
               coordinate.latitude <= maxLat &&
               coordinate.longitude >= minLng &&
               coordinate.longitude <= maxLng
    }
}


extension MapController: UISearchBarDelegate {
    
    // MARK: - UISearchBarDelegate Methods
        
    // Called when the user begins editing the search bar.
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        // Show the cancel button in the search bar when editing begins.
        searchBar.showsCancelButton = true
        return true
    }
    
    // Called when the user finishes editing the search bar.
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        // Hide the cancel button when editing ends.
        searchBar.showsCancelButton = false
        return true
    }
    
    // Called when the user taps the cancel button in the search bar.
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Handle the cancel button click event in the `MapSearchController`.
        mapSearchController.searchBarCancelButtonClicked(searchBar)
        // Remove all annotations from the map except for the user's location.
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        // Reload the location annotations (presumably a default set of annotations).
        loadLocationAnnotations()
        // Resign the first responder status from the search bar, dismissing the keyboard.
        searchBar.resignFirstResponder()
    }

}


