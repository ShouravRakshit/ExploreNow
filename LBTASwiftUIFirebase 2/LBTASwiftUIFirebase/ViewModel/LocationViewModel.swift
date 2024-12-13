//
//  LocationViewModel.swift
//  LBTASwiftUIFirebase
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
        locationRef.getDocument { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching location details: \(error)")
                return
            }
            
            if let data = snapshot?.data() {
                // Extract basic location data from Firestore
                let address = data["address"] as? String ?? ""
                let coordinates = data["location_coordinates"] as? [Double] ?? []
                let averageRating = data["average_rating"] as? Double ?? 0
                
                // If valid coordinates exist, perform reverse geocoding
                if coordinates.count == 2 {
                    let location = CLLocation(latitude: coordinates[0], longitude: coordinates[1])
                    let geocoder = CLGeocoder()
                    
                    // Convert coordinates to human-readable address
                    geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
                        if let error = error {
                            print("Reverse geocoding error: \(error)")
                            return
                        }
                        
                        if let placemark = placemarks?.first {
                            // Use location name or fallback to stored address
                            let mainAddress = placemark.name ?? address
                            var fullAddressComponents: [String] = []
                            
                            // Build complete address from address components
                            if let streetNumber = placemark.subThoroughfare { fullAddressComponents.append(streetNumber) }
                            if let street = placemark.thoroughfare { fullAddressComponents.append(street) }
                            if let city = placemark.locality { fullAddressComponents.append(city) }
                            if let state = placemark.administrativeArea { fullAddressComponents.append(state) }
                            if let country = placemark.country { fullAddressComponents.append(country) }
                            
                            let fullAddress = fullAddressComponents.joined(separator: ", ")
                            
                            // Update UI on main thread
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
            .whereField("locationRef", isEqualTo: locationRef)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                if let error = error {
                    print("Error fetching posts: \(error)")
                    return
                }
                
                // Process only newly added posts
                querySnapshot?.documentChanges.forEach { change in
                    if change.type == .added {
                        self?.handleNewPost(change.document)
                    }
                }
            }
    }
    
    // MARK: - Maps Integration Methods
    
    /// Opens the location in Maps app without directions
    func openInMaps() {
        fetchLocationCoordinates { coordinates in
            guard let coordinates = coordinates else { return }
            
            // Create and configure map item
            let coordinate = CLLocationCoordinate2D(
                latitude: coordinates[0],
                longitude: coordinates[1]
            )
            let placemark = MKPlacemark(coordinate: coordinate)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = self.locationDetails?.mainAddress
            mapItem.openInMaps(launchOptions: nil)
        }
    }
    
    /// Opens the location in Maps app with driving directions
    func openInMapsWithDirections() {
        fetchLocationCoordinates { coordinates in
            guard let coordinates = coordinates else { return }
            
            // Create and configure map item
            let coordinate = CLLocationCoordinate2D(
                latitude: coordinates[0],
                longitude: coordinates[1]
            )
            let placemark = MKPlacemark(coordinate: coordinate)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = self.locationDetails?.mainAddress
            
            // Configure for driving directions
            let launchOptions = [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ]
            mapItem.openInMaps(launchOptions: launchOptions)
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Processes a new post document and adds it to the posts array
    private func handleNewPost(_ document: QueryDocumentSnapshot) {
        let data = document.data()
        let postId = document.documentID
        
        // Set header image if none exists and post has images
        if let imageUrls = data["images"] as? [String],
           !imageUrls.isEmpty,
           headerImageUrl == nil {
            headerImageUrl = imageUrls.randomElement()
        }
        
        guard let locationRef = data["locationRef"] as? DocumentReference else { return }
        
        // Fetch additional details needed for the post
        fetchLocationDetails(for: locationRef) { [weak self] address in
            guard let address = address else { return }
            
            if let userId = data["uid"] as? String {
                self?.fetchUserDetails(userId: userId) { username, userProfileImageUrl in
                    // Create post object with all fetched details
                    let post = Post(
                        id: postId,
                        description: data["description"] as? String ?? "",
                        rating: data["rating"] as? Int ?? 0,
                        locationRef: locationRef,
                        locationAddress: address,
                        imageUrls: data["images"] as? [String] ?? [],
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                        uid: userId,
                        username: username,
                        userProfileImageUrl: userProfileImageUrl
                    )
                    
                    // Update posts array on main thread
                    DispatchQueue.main.async {
                        if !(self?.locationPosts.contains(where: { $0.id == post.id }) ?? false) {
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
        locationRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching location: \(error)")
                completion(nil)
                return
            }
            
            if let data = snapshot?.data(),
               let address = data["address"] as? String {
                completion(address)
            } else {
                completion(nil)
            }
        }
    }
    
    /// Fetches user details for a given user ID
    private func fetchUserDetails(userId: String, completion: @escaping (String, String) -> Void) {
        db.collection("users")
            .document(userId)
            .getDocument { snapshot, error in
                if let error = error {
                    print("Error fetching user details: \(error)")
                    completion("Unknown User", "")
                    return
                }
                
                let userData = snapshot?.data() ?? [:]
                let username = userData["username"] as? String ?? "Unknown User"
                let userProfileImageUrl = userData["profileImageUrl"] as? String ?? ""
                completion(username, userProfileImageUrl)
            }
    }
    
    /// Fetches coordinates for the current location
    private func fetchLocationCoordinates(completion: @escaping ([Double]?) -> Void) {
        locationRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching location: \(error)")
                completion(nil)
                return
            }
            
            if let data = snapshot?.data(),
               let coordinates = data["location_coordinates"] as? [Double],
               coordinates.count == 2 {
                completion(coordinates)
            } else {
                completion(nil)
            }
        }
    }
}
