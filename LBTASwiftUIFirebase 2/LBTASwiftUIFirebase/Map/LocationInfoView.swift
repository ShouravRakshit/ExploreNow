
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

import UIKit
import MapKit
import SwiftUI
import Firebase
import FirebaseFirestore

//this class is the little location information cards that pop up when an annotation or cluster is clicked

class LocationInfoView: UIView {
    private let locationLabel = UILabel() // Label to display location name
    private let ratingLabel = UILabel() // Label to display rating of the location
    private let postCountLabel = UILabel() // Label to display the number of posts related to the location
    private var loadingIndicator: UIActivityIndicatorView? // Activity indicator for showing loading state
    private var currentLocation: Location? // Holds the current location data
    private weak var userManager: UserManager? // Reference to the UserManager for managing user-related data
    
    // MARK: - Custom Colors
    private let primaryPurple = UIColor(red: 140/255, green: 82/255, blue: 255/255, alpha: 1.0) // Custom purple color used in the UI
    private let lightPurple = UIColor(red: 140/255, green: 82/255, blue: 255/255, alpha: 0.1) // Lighter shade of purple for UI elements
    
    // MARK: - Initialization
    // Custom initializer to set up the view with a frame and a reference to UserManager
    init(frame: CGRect, userManager: UserManager) {
        self.userManager = userManager // Assign the userManager to handle user data
        super.init(frame: frame) // Call the superclass initializer
        setupUI() // Call method to set up the UI elements
        setupGesture() // Call method to set up gesture recognizers for interaction
    }
    
    // Required initializer for when the view is loaded from a storyboard or nib
    required init?(coder: NSCoder) {
        self.userManager = nil // If loaded from storyboard, userManager won't be available
        super.init(coder: coder)  // Call the superclass initializer
        setupUI()  // Set up the UI elements
        setupGesture() // Set up gesture recognizers for interaction
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // Main Container Setup
        backgroundColor = .white // Set the background color of the view to white
        layer.cornerRadius = 16 // Apply a corner radius to make the view's corners rounded
        layer.masksToBounds = false // Allow content to overflow the view's bounds (for shadow effect)
        layer.shadowColor = UIColor.black.cgColor // Set the shadow color to black
        layer.shadowOpacity = 0.08 // Set the shadow's opacity (how transparent the shadow is)
        layer.shadowOffset = CGSize(width: 0, height: 2)  // Set the shadow's offset (distance from the view)
        layer.shadowRadius = 8 // Set the blur radius of the shadow (controls the shadow's spread)
        
        // Location Container
        let locationContainer = UIView() // Create a new container view for the location section
        locationContainer.backgroundColor = .clear // Set the container's background color to clear (transparent)
        locationContainer.translatesAutoresizingMaskIntoConstraints = false  // Disable autoresizing mask translation for layout constraints
        
        // Location Icon
        let locationIcon = UIImageView(image: UIImage(systemName: "mappin.circle.fill")) // Create an image view with a location icon
        locationIcon.tintColor = primaryPurple // Apply the primary purple color as the tint for the icon
        locationIcon.contentMode = .scaleAspectFit // Ensure the image is scaled to fit the available space without distortion
        locationIcon.translatesAutoresizingMaskIntoConstraints = false  // Disable autoresizing mask translation for layout constraints
        
        // Location Label Setup
        locationLabel.font = .systemFont(ofSize: 16, weight: .semibold)  // Set the font size and weight for the location label
        locationLabel.textColor = .black // Set the text color for the label to black
        locationLabel.numberOfLines = 2 // Allow the label to display up to 2 lines of text
        locationLabel.translatesAutoresizingMaskIntoConstraints = false // Disable autoresizing mask translation for layout constraints
        
        // Post Count Label Setup
        postCountLabel.font = .systemFont(ofSize: 14) // Set the font size for the post count label
        postCountLabel.textColor = .gray // Set the text color to gray for the post count label
        postCountLabel.translatesAutoresizingMaskIntoConstraints = false // Disable autoresizing mask translation for layout constraints
        
        // Rating Container
        let ratingContainer = UIView() // Create a container view for the rating section
        ratingContainer.backgroundColor = lightPurple // Set the background color of the rating container to a light purple
        ratingContainer.layer.cornerRadius = 12 // Round the corners of the rating container
        ratingContainer.translatesAutoresizingMaskIntoConstraints = false // Disable autoresizing mask translation for layout constraints
        
        // Rating Icon
        let ratingIcon = UIImageView(image: UIImage(systemName: "star.fill"))  // Create an image view with a filled star icon for rating
        ratingIcon.tintColor = .systemYellow // Set the tint color to yellow for the star icon
        ratingIcon.contentMode = .scaleAspectFit // Ensure the star image is scaled to fit the container without distortion
        ratingIcon.translatesAutoresizingMaskIntoConstraints = false  // Disable autoresizing mask translation for layout constraints
        
        // Rating Label Setup
        ratingLabel.font = .systemFont(ofSize: 14, weight: .medium) // Set the font size and weight for the rating label
        ratingLabel.textColor = primaryPurple // Set the text color of the rating label to primary purple
        ratingLabel.translatesAutoresizingMaskIntoConstraints = false // Disable autoresizing mask translation for layout constraints
        
        // Add subviews
        addSubview(locationContainer) // Add the location container as a subview to the main view
        locationContainer.addSubview(locationIcon) // Add the location icon to the location container
        locationContainer.addSubview(locationLabel) // Add the location label to the location container
        locationContainer.addSubview(postCountLabel) // Add the post count label to the location container
        
        addSubview(ratingContainer) // Add the rating container as a subview to the main view
        ratingContainer.addSubview(ratingIcon) // Add the rating icon to the rating container
        ratingContainer.addSubview(ratingLabel) // Add the rating label to the rating container
        
        // Loading Indicator Setup
        loadingIndicator = UIActivityIndicatorView(style: .medium) // Initialize the loading indicator with a medium style
        loadingIndicator?.hidesWhenStopped = true // Set the loading indicator to hide when it stops animating
        loadingIndicator?.translatesAutoresizingMaskIntoConstraints = false  // Disable autoresizing mask translation for layout constraints
        if let loadingIndicator = loadingIndicator {
            addSubview(loadingIndicator)  // Add the loading indicator to the main view if it's not nil
        }
        
        // Setup Constraints
        NSLayoutConstraint.activate([
            // Location Container
            locationContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16), // Place the location container 16 points from the left edge of the view
            locationContainer.topAnchor.constraint(equalTo: topAnchor, constant: 12), // Place the location container 12 points from the top edge of the view
            locationContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12), // Place the location container 12 points from the bottom edge of the view
            
            // Location Icon
            locationIcon.leadingAnchor.constraint(equalTo: locationContainer.leadingAnchor),  // Align the location icon with the leading edge of the location container
            locationIcon.centerYAnchor.constraint(equalTo: locationContainer.centerYAnchor), // Vertically center the location icon within the location container
            locationIcon.widthAnchor.constraint(equalToConstant: 24),// Set the width of the location icon to 24 points
            locationIcon.heightAnchor.constraint(equalToConstant: 24),// Set the height of the location icon to 24 points
            
            // Location Label
            locationLabel.leadingAnchor.constraint(equalTo: locationIcon.trailingAnchor, constant: 8), // Place the location label 8 points to the right of the location icon
            locationLabel.topAnchor.constraint(equalTo: locationContainer.topAnchor),// Align the top of the location label with the top of the location container
            
            // Post Count Label
            postCountLabel.leadingAnchor.constraint(equalTo: locationIcon.trailingAnchor, constant: 8), // Place the post count label 8 points to the right of the location icon
            postCountLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 2), // Place the post count label 2 points below the location label
            postCountLabel.bottomAnchor.constraint(equalTo: locationContainer.bottomAnchor),
            // Align the bottom of the post count label with the bottom of the location container
            
            // Rating Container
            ratingContainer.leadingAnchor.constraint(greaterThanOrEqualTo: locationLabel.trailingAnchor, constant: 12), // Ensure the rating container is at least 12 points to the right of the location label
            ratingContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),// Place the rating container 16 points from the right edge of the view
            ratingContainer.centerYAnchor.constraint(equalTo: centerYAnchor), // Vertically center the rating container within the main view
            ratingContainer.heightAnchor.constraint(equalToConstant: 32), // Set the height of the rating container to 32 points

            
            // Rating Icon
            ratingIcon.leadingAnchor.constraint(equalTo: ratingContainer.leadingAnchor, constant: 12), // Place the rating icon 12 points from the left edge of the rating container
            ratingIcon.centerYAnchor.constraint(equalTo: ratingContainer.centerYAnchor), // Vertically center the rating icon within the rating container
            ratingIcon.widthAnchor.constraint(equalToConstant: 16),  // Set the width of the rating icon to 16 points
            ratingIcon.heightAnchor.constraint(equalToConstant: 16), // Set the height of the rating icon to 16 points
            
            // Rating Label
            ratingLabel.leadingAnchor.constraint(equalTo: ratingIcon.trailingAnchor, constant: 4),  // Place the rating label 4 points to the right of the rating icon
            ratingLabel.trailingAnchor.constraint(equalTo: ratingContainer.trailingAnchor, constant: -12),  // Place the rating label 12 points from the right edge of the rating container
            ratingLabel.centerYAnchor.constraint(equalTo: ratingContainer.centerYAnchor),
            // Vertically center the rating label within the rating container
            
            // Loading Indicator
            loadingIndicator!.centerXAnchor.constraint(equalTo: centerXAnchor),  // Horizontally center the loading indicator within the main view
            loadingIndicator!.centerYAnchor.constraint(equalTo: centerYAnchor) // Vertically center the loading indicator within the main view
        ])
    }
    
    // MARK: - Configuration
    
    // Configure the view with the provided Location object
    func configure(with location: Location) {
        self.currentLocation = location // Store the passed location object for later use
        ratingLabel.text = String(format: "%.1f", location.rating) // Format and set the location's rating as a string with one decimal place
        let coordinate = location.coordinate // Extract the coordinate (latitude, longitude) of the location
        getPointOfInterest(for: coordinate)  // Fetch additional information about points of interest using the coordinate
        fetchPostCount(for: coordinate)  // Fetch the post count related to the location based on the coordinate
    }
    
    // Update the location and post count labels with new data
    private func updateLocationLabel(name: String, postCount: Int) {
        locationLabel.text = name // Update the location label with the name of the location
        postCountLabel.text = "\(postCount) posts" // Update the post count label with the number of posts at the location, formatted as "X posts"
    }

    // Fetch the count of posts for a specific location, based on coordinates
    private func fetchPostCount(for coordinate: CLLocationCoordinate2D) {
        let db = FirebaseManager.shared.firestore // Access Firestore instance via the shared FirebaseManager
        
        // Query the "locations" collection to find the document corresponding to the provided coordinates
        db.collection("locations")
            .whereField("location_coordinates", isEqualTo: [coordinate.latitude, coordinate.longitude])
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return } // Ensure that 'self' is still available (prevents retain cycles)
                
                // If the location document is found in the snapshot
                if let locationDoc = snapshot?.documents.first {
                    let locationRef = locationDoc.reference // Get the reference to the location document
                    
                    // Fetch the posts associated with this location using the location reference
                    db.collection("user_posts")
                        .whereField("locationRef", isEqualTo: locationRef)
                        .getDocuments { snapshot, error in
                            // Perform UI updates on the main thread
                            DispatchQueue.main.async {
                                let count = snapshot?.documents.count ?? 0  // Count the number of documents (posts)
                                
                                // Update the location label and post count with the fetched data
                                // The currentName is the text of the location label, excluding any suffix like "(X posts)"
                                if let currentName = self.locationLabel.text?.components(separatedBy: " (").first {
                                    self.updateLocationLabel(name: currentName, postCount: count) // Update labels
                                }
                            }
                        }
                }
            }
    }
    
    // Fetch the point of interest (location address) for the given coordinates
    private func getPointOfInterest(for coordinate: CLLocationCoordinate2D) {
        // Get a reference to Firestore database
        let db = FirebaseManager.shared.firestore
        
        // Query the 'locations' collection to find the document that matches the coordinates
        db.collection("locations")
            .whereField("location_coordinates", isEqualTo: [coordinate.latitude, coordinate.longitude])
            .getDocuments { [weak self] snapshot, error in
                // Safely unwrap the reference to self to avoid retain cycles
                guard let self = self else { return }
                
                // Switch to the main thread for UI updates
                DispatchQueue.main.async {
                    // Handle any errors during the fetch
                    if let error = error {
                        print("Error fetching location: \(error.localizedDescription)")
                        self.locationLabel.text = "Location not found"
                        return
                    }
                    
                    // If a location document is found, retrieve the address
                    if let locationDoc = snapshot?.documents.first,
                       let address = locationDoc.data()["address"] as? String {
                        // Extract the location name (before the first comma) from the address string
                        let locationName = address.components(separatedBy: ",")[0].trimmingCharacters(in: .whitespaces)
                        // Set the location label to the extracted location name
                        self.locationLabel.text = locationName
                        // Fetch the post count for this location after setting the location name
                        self.fetchPostCount(for: coordinate)
                    } else {
                        // If no address is found, set the label to indicate an unknown location
                        self.locationLabel.text = "Unknown location"
                    }
                }
            }
    }


    // Setup tap gesture recognizer for the view
    private func setupGesture() {
        // Create a UITapGestureRecognizer that triggers the handleTap method when tapped
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        
        // Add the gesture recognizer to the view, so it can listen for tap events
        self.addGestureRecognizer(tapGesture)
        
        // Enable user interaction for the view, allowing it to receive gesture events
        self.isUserInteractionEnabled = true
    }
        
    @objc private func handleTap() {
        // Ensure that the current location is available
        guard let location = currentLocation else { return }
        
        // Ensure that the userManager is available before proceeding
        guard let userManager = self.userManager else { // Unwrap userManager
            print("DEBUG: UserManager not available")
            return
        }

        // Show a loading indicator while fetching data
        showLoading()
        
        // Firebase database reference
        let db = FirebaseManager.shared.firestore
        db.collection("locations")
            .whereField("location_coordinates", isEqualTo: [location.coordinate.latitude, location.coordinate.longitude])
            .getDocuments { [weak self] snapshot, error in
                // Handle memory management by using [weak self] to avoid retain cycles
                guard let self = self else { return }
                // Hide loading indicator once the network call is done
                self.hideLoading()
                
                // Handle any error that occurred while fetching the location data
                if let error = error {
                    print("Error fetching location: \(error.localizedDescription)")
                    return
                }
                
                // Check if a location document exists in the snapshot
                if let locationDoc = snapshot?.documents.first {
                    let locationRef = locationDoc.reference
                    // Create a UIHostingController to present a SwiftUI view with the location's posts
                    let locationPostsPage = UIHostingController(rootView:
                        LocationPostsPage(locationRef: locationRef)
                            .environmentObject(userManager) // Pass userManager as an environment object
                    )

                    // Attempt to find and present the parent view controller
                    if let parentVC = self.parentViewController {
                        parentVC.present(locationPostsPage, animated: true, completion: nil)
                    } else {
                        print("No parent view controller found!")
                    }
                } else {
                    print("Location not found in database!")
                }
            }
    }

    // MARK: - Show Loading Indicator
    private func showLoading() {
        // Check if the loading indicator is not already initialized
        if loadingIndicator == nil {
            // If not initialized, create a new loading indicator with a medium style
            loadingIndicator = UIActivityIndicatorView(style: .medium)
            // Disable the autoresizing mask and set up constraints manually
            loadingIndicator?.translatesAutoresizingMaskIntoConstraints = false
            // Add the loading indicator as a subview to the current view
            addSubview(loadingIndicator!)
            
            // Activate the constraints to center the loading indicator within the parent view
            NSLayoutConstraint.activate([
                loadingIndicator!.centerXAnchor.constraint(equalTo: centerXAnchor),
                loadingIndicator!.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        }
        // Start animating the loading indicator to show the loading state
        loadingIndicator?.startAnimating()
        
        // Disable user interaction while the loading indicator is active
        isUserInteractionEnabled = false
    }
    
    // MARK: - Hide Loading Indicator
    private func hideLoading() {
        // Stop the loading indicator animation when the task is complete
        loadingIndicator?.stopAnimating()
        
        // Re-enable user interaction, allowing the user to interact with the UI again
        isUserInteractionEnabled = true
    }

}

// MARK: - UIView Extension for Parent View Controller
extension UIView {
    // A computed property that retrieves the parent view controller of the view
    var parentViewController: UIViewController? {
        // Start with the current view's responder
        var responder: UIResponder? = self
        // Traverse the responder chain until a UIViewController is found
        while responder != nil {
            responder = responder?.next
            // If a UIViewController is found in the responder chain, return it
            if let viewController = responder as? UIViewController {
                return viewController
            }
        }
        // If no UIViewController is found in the responder chain, return nil
        return nil
    }
}
