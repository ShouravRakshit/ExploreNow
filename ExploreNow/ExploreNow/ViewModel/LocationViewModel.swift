//
//  LocationViewModel.swift
//  ExploreNow
//
//  Created by Saadman Rahman on 2024-12-13.
//


import SwiftUI
import Firebase
import CoreLocation
import MapKit

// MARK: - Data Models

/// Represents the essential details of a location
struct LocationDetails {
    let mainAddress: String  // Primary address (e.g., business name or street address)
    let fullAddress: String  // Complete address including city, state, and country
    let averageRating: Double  // Average user rating for this location
}

// MARK: - ViewModel

/// ViewModel responsible for managing location data and user interactions
class LocationViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Array of posts associated with this location
    @Published var locationPosts: [Post] = []
    
    /// Details about the current location (address and rating)
    @Published var locationDetails: LocationDetails?
    
    /// Loading state indicator for UI feedback
    @Published var isLoading = true
    
    /// URL for the header image, randomly selected from the first post's images
    @Published var headerImageUrl: String?
    
    // MARK: - Private Properties
    
    /// Reference to the Firestore document for this location
    private let locationRef: DocumentReference
    
    /// Reference to the Firestore database instance
    private let db = FirebaseManager.shared.firestore
    
    // MARK: - Initialization
    
    /// Initializes the ViewModel with a reference to a location document
    /// - Parameter locationRef: Firestore reference to the location document
    init(locationRef: DocumentReference) {
        self.locationRef = locationRef
    }
    
    // MARK: - Public Methods
    
    /// Fetches and processes location details from Firestore
    func fetchLocationDetails() {
        // Initiates the fetching of the location document from Firestore.
        locationRef.getDocument { [weak self] snapshot, error in
            // Checks if an error occurred during the document fetch.
            if let error = error {
                // Prints the error and exits the function.
                print("Error fetching location details: \(error)")
                return
            }
            
            // Verifies that the snapshot contains data.
            if let data = snapshot?.data() {
                // Retrieves the address, coordinates, and average rating from the Firestore document.
                let address = data["address"] as? String ?? ""
                let coordinates = data["location_coordinates"] as? [Double] ?? []
                let averageRating = data["average_rating"] as? Double ?? 0
                
                // Ensures that coordinates contain valid latitude and longitude values.
                if coordinates.count == 2 {
                    // Creates a `CLLocation` object using the retrieved coordinates.
                    let location = CLLocation(latitude: coordinates[0], longitude: coordinates[1])
                    let geocoder = CLGeocoder()
                    
                    // Initiates reverse geocoding to obtain an address from the coordinates.
                    geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
                        // Checks if an error occurred during reverse geocoding.
                        if let error = error {
                            // Prints the error and exits the function
                            print("Reverse geocoding error: \(error)")
                            return
                        }
                        
                        // Uses the first placemark if available.
                        if let placemark = placemarks?.first {
                            // Falls back to the Firestore address if the placemark's name is unavailable.
                            let mainAddress = placemark.name ?? address
                            var fullAddressComponents: [String] = []
                            
                            // Appends address components (e.g., street number, street name, city) if they exist.
                            if let streetNumber = placemark.subThoroughfare { fullAddressComponents.append(streetNumber) }
                            if let street = placemark.thoroughfare { fullAddressComponents.append(street) }
                            if let city = placemark.locality { fullAddressComponents.append(city) }
                            if let state = placemark.administrativeArea { fullAddressComponents.append(state) }
                            if let country = placemark.country { fullAddressComponents.append(country) }
                            
                            // Joins the address components into a complete address string
                            let fullAddress = fullAddressComponents.joined(separator: ", ")
                            
                            // Updates the UI on the main thread with the fetched data.
                            DispatchQueue.main.async {
                                self?.locationDetails = LocationDetails(
                                    mainAddress: mainAddress,
                                    fullAddress: fullAddress,
                                    averageRating: averageRating
                                )
                                self?.isLoading = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Fetches posts associated with this location and listens for updates
    func fetchLocationPosts() {
        // Create a query for posts with this location reference
        db.collection("user_posts")
        // Filter posts to include only those with a matching location reference
            .whereField("locationRef", isEqualTo: locationRef)
        // Sort the posts by timestamp in descending order (newest first)
            .order(by: "timestamp", descending: true)
        // Add a listener to monitor real-time updates to the query
            .addSnapshotListener { [weak self] querySnapshot, error in
                if let error = error {
                    // Check for and handle errors during the Firestore query
                    print("Error fetching posts: \(error)") // Log the error for debugging
                    return      // Exit the function if an error occurs
                }
                
                // Iterate over the document changes in the query snapshot
                querySnapshot?.documentChanges.forEach { change in
                    // Check if the document change type is "added" (new posts)
                    if change.type == .added {
                        // Process the newly added post
                        self?.handleNewPost(change.document)
                    }
                }
            }
    }
    
    // MARK: - Maps Integration Methods
    
    /// Opens the location in Maps app without directions
    func openInMaps() {
        // Fetch the location's coordinates asynchronously
        fetchLocationCoordinates { coordinates in
            // Ensure the coordinates are valid; exit if nil
            guard let coordinates = coordinates else { return }
            
            // Create a CLLocationCoordinate2D object from the fetched coordinates
            let coordinate = CLLocationCoordinate2D(
                latitude: coordinates[0],           // Latitude value from the array
                longitude: coordinates[1]           // Longitude value from the array
            )
            // Create an MKPlacemark object using the coordinates
            let placemark = MKPlacemark(coordinate: coordinate)
            // Create an MKMapItem object to represent the location in Maps
            let mapItem = MKMapItem(placemark: placemark)
            // Set the name of the map item to the main address of the location
            mapItem.name = self.locationDetails?.mainAddress
            // Open the location in the Maps app without additional options
            mapItem.openInMaps(launchOptions: nil)
        }
    }
    
    /// Opens the location in Maps app with driving directions
    func openInMapsWithDirections() {
        // Fetch the location's coordinates asynchronously
        fetchLocationCoordinates { coordinates in
            // Ensure the coordinates are valid; exit if nil
            guard let coordinates = coordinates else { return }
            
            // Create a CLLocationCoordinate2D object using the fetched coordinates
            let coordinate = CLLocationCoordinate2D(
                latitude: coordinates[0],           // Latitude value from the array
                longitude: coordinates[1]            // Longitude value from the array
            )
            // Create an MKPlacemark object to represent the location
            let placemark = MKPlacemark(coordinate: coordinate)
            // Create an MKMapItem object using the placemark to interact with Maps
            let mapItem = MKMapItem(placemark: placemark)
            // Assign the location's main address as the name of the map item
            mapItem.name = self.locationDetails?.mainAddress
            
            // Configure launch options to request driving directions
            let launchOptions = [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ]
            // Open the location in the Maps app with the specified options
            mapItem.openInMaps(launchOptions: launchOptions)
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Processes a new post document and adds it to the posts array
    private func handleNewPost(_ document: QueryDocumentSnapshot) {
        let data = document.data()           // Extracts the data from the document snapshot
        let postId = document.documentID     // Stores the post's unique document ID
        
        // Set header image if none exists and post has images
        // This checks if the post contains images and if no header image is set yet
        if let imageUrls = data["images"] as? [String],
           !imageUrls.isEmpty,
           headerImageUrl == nil {
            headerImageUrl = imageUrls.randomElement()   // Picks a random image URL from the post's images
        }
        
        guard let locationRef = data["locationRef"] as? DocumentReference else {
               // If the location reference is missing or invalid, return early from the function
               return
           }
        
        // Fetch additional details needed for the post, such as the location address
            fetchLocationDetails(for: locationRef) { [weak self] address in
                guard let address = address else {
                    // If fetching the address fails, exit early without processing the post further
                    return
                }
                
            // Check if the user ID exists in the post's data
            if let userId = data["uid"] as? String {
                // Fetch user details using the user ID
                self?.fetchUserDetails(userId: userId) { username, userProfileImageUrl in
                    // Create a Post object using all the fetched and existing details
                    let post = Post(
                        id: postId,          // Post ID
                        description: data["description"] as? String ?? "",   // Post description (defaulting to empty string if not available)
                        rating: data["rating"] as? Int ?? 0,        // Rating for the post (defaults to 0 if missing)
                        locationRef: locationRef,                   // Location reference (already validated)
                        locationAddress: address,                   // Fetched location address
                        imageUrls: data["images"] as? [String] ?? [],       // List of image URLs (defaults to empty array if missing)
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(), // Timestamp for the post (defaults to current date if missing)
                        uid: userId,        // User ID
                        username: username, // Fetched username
                        userProfileImageUrl: userProfileImageUrl    // Fetched user profile image URL
                    )
                    
                    // Update the posts array on the main thread
                    DispatchQueue.main.async {
                        // Check if the post is already in the array (to avoid duplicates)
                        if !(self?.locationPosts.contains(where: { $0.id == post.id }) ?? false) {
                            // Append the new post and sort the posts array by timestamp (most recent first)
                            self?.locationPosts.append(post)
                            self?.locationPosts.sort { $0.timestamp > $1.timestamp }
                        }
                    }
                }
            }
        }
    }
    
    /// Fetches the address for a given location reference
    private func fetchLocationDetails(for locationRef: DocumentReference, completion: @escaping (String?) -> Void) {
        // Fetch the document from the provided location reference
        locationRef.getDocument { snapshot, error in
            // Check if an error occurred while fetching the document
            if let error = error {
                print("Error fetching location: \(error)")      // Log the error for debugging
                completion(nil)                                  // Return nil via the completion handler to indicate failure
                return
            }
            
            // Check if the snapshot contains valid data and if the "address" key exists
            if let data = snapshot?.data(),
               let address = data["address"] as? String {
                completion(address)                             // Return the address via the completion handler
            } else {
                completion(nil)                                 // If the address is missing or invalid, return nil
            }
        }
    }
    
    /// Fetches user details for a given user ID
    private func fetchUserDetails(userId: String, completion: @escaping (String, String) -> Void) {
        // Access the "users" collection in the Firestore database and fetch the document for the given user ID
        db.collection("users")
            .document(userId)
            .getDocument { snapshot, error in
                // Check if an error occurred while fetching the document
                if let error = error {
                    print("Error fetching user details: \(error)")  // Log the error for debugging
                    completion("Unknown User", "")                  // Return default values ("Unknown User" and an empty string) via the completion handler
                    return
                }
                
                // Extract the user data from the document snapshot. If no data is found, use an empty dictionary as a fallback
                let userData = snapshot?.data() ?? [:]
                // Retrieve the "username" and "profileImageUrl" from the user data. Default to "Unknown User" and empty string if not found
                let username = userData["username"] as? String ?? "Unknown User"
                let userProfileImageUrl = userData["profileImageUrl"] as? String ?? ""
                // Return the username and profile image URL through the completion handler
                completion(username, userProfileImageUrl)
            }
    }
    
    /// Fetches coordinates for the current location
    private func fetchLocationCoordinates(completion: @escaping ([Double]?) -> Void) {
        // Fetch the document from the location reference
        locationRef.getDocument { snapshot, error in
            // Check if an error occurred while fetching the document
            if let error = error {
                print("Error fetching location: \(error)")       // Log the error for debugging purposes
                completion(nil)                                 // Return nil via the completion handler to indicate failure
                return
            }
            
            // Check if the snapshot contains valid data and if the "location_coordinates" key exists
            if let data = snapshot?.data(),
               let coordinates = data["location_coordinates"] as? [Double], // Attempt to cast the coordinates to an array of doubles
               coordinates.count == 2 {             // Ensure the coordinates contain exactly two values (latitude and longitude)
                completion(coordinates)             // Return the coordinates via the completion handler
            } else {
                completion(nil)                     // If the coordinates are missing or invalid, return nil
            }
        }
    }
}

