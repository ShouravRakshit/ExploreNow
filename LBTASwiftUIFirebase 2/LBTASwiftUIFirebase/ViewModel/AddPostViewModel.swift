//
//  AddPostViewModel.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

import Foundation
import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import CoreLocation
import MapKit

// ViewModel for adding a post, conforming to the ObservableObject protocol for data binding
class AddPostViewModel: ObservableObject {
    
    // MARK: - Published Properties
    // @Published attributes automatically notify views that are observing them when their values change.
       
    // The description text of the post (e.g., user input for post details)
    @Published var descriptionText: String = ""
    // Rating for the post (e.g., a numerical value indicating user rating)
    @Published var rating: Int = 0
    // The selected location for the post (could be a place name or coordinates)
    @Published var selectedLocation: String = ""
    // List of images associated with the post
    @Published var images: [UIImage] = []
    // Latitude of the location of the post (used for geographical data)
    @Published var latitude: Double = 0.0
    // Longitude of the location of the post (used for geographical data)
    @Published var longitude: Double = 0.0
    // A flag indicating whether the post is currently being submitted or loaded
    @Published var isLoading = false
    // Status message to display feedback to the user, e.g., success or error message
    @Published var addPostStatusMessage: String = ""
    
    // MARK: - Dependency Injection
    @Published var userManager: UserManager // Manages user-related logic and actions.
    @Published var locationManager = CustomLocationManager() // Manages user-related logic and actions.
    
    init() {
    // Initialize with default instances
    self.userManager = UserManager() // Default instance, replace as needed
    self.locationManager = CustomLocationManager() // Default instance, replace as needed
    }
    
    // Function to add a new post
    func addPost() {
        // Validate input before proceeding (e.g., check for required fields)
        guard validateInput() else { return }
        // Ensure that the user is authenticated by checking if a user ID exists
        guard let userID = FirebaseManager.shared.auth.currentUser?.uid else {
            // If the user is not authenticated, set an error message and exit
            addPostStatusMessage = "User not authenticated"
            return
        }
        
        // Set the loading state to true and display a status message while uploading the post
        isLoading = true
        addPostStatusMessage = "Uploading post..."
        // Handle the location-related logic (e.g., get the location reference), and upload the post once location is retrieved
        handleLocation { [weak self] locationRef in
            // Call the uploadPost function to actually upload the post once the location reference is available
            self?.uploadPost(userID: userID, locationRef: locationRef)
        }
    }
    
    // Function to validate the input for adding a post
    private func validateInput() -> Bool {
        // Check if the description is empty
        if descriptionText.isEmpty {
            // Set a status message indicating the description is missing
            addPostStatusMessage = "Please enter a description for your post"
            return false        // Return false to indicate validation failed
        }
        // Check if a location has been selected
        if selectedLocation.isEmpty {
            // Set a status message indicating the location is missing
            addPostStatusMessage = "Please select a location for your post"
            return false            // Return false to indicate validation failed
        }
        // Check if images have been added
        if images.isEmpty {
            // Set a status message indicating no images were added
            addPostStatusMessage = "Please add some images for your post"
            return false                    // Return false to indicate validation failed
        }
        // Return true if all inputs are valid
        return true
    }
    
    
    // Function to handle the location-related operations
    // It checks if the location already exists in the database and returns its reference or creates a new one
    private func handleLocation(completion: @escaping (DocumentReference) -> Void) {
        // Get the Firestore database reference from the Firebase manager
        let db = FirebaseManager.shared.firestore
        // Query the "locations" collection to check if a location with the selected address exists
        db.collection("locations")
            .whereField("address", isEqualTo: selectedLocation)     // Search for the location with the same address as selectedLocation
            .getDocuments { [weak self] snapshot, error in
                // Check if there was an error during the Firestore request
                if let error = error {
                    // If there's an error, set the status message and stop loading
                    self?.addPostStatusMessage = "Error checking location: \(error.localizedDescription)"
                    self?.isLoading = false             // Stop the loading indicator
                    return                              // Exit the function if there was an error
                }
                
                // If the location already exists in Firestore (i.e., a document is found)
                if let existingLocation = snapshot?.documents.first {
                    // Return the reference to the existing location document
                    completion(existingLocation.reference)
                } else {
                    // Return the reference to the existing location document
                    self?.createNewLocation(completion: completion)
                }
            }
    }
    
    // Function to create a new location in Firestore and return its document reference via completion handler
    private func createNewLocation(completion: @escaping (DocumentReference) -> Void) {
        // Get the Firestore database reference from FirebaseManager
        let db = FirebaseManager.shared.firestore
        // Define the location data to be added to Firestore
        let locationData: [String: Any] = [
            "address": selectedLocation,                        // The address of the location
            "location_coordinates": [latitude, longitude],      // Coordinates of the location (latitude, longitude)
            "average_rating": rating                            // The average rating for the location
        ]
        
        // Add the location data to the "locations" collection in Firestore
        db.collection("locations").addDocument(data: locationData) { [weak self] error in
            // Check if there was an error while adding the document
            if let error = error {
                // If there is an error, set the status message and stop the loading indicator
                self?.addPostStatusMessage = "Error creating location: \(error.localizedDescription)"
                self?.isLoading = false             // Stop the loading spinner
                return                              // Exit the function if there was an error
            }
            
            // If location was added successfully, query Firestore to get the reference to the newly added location
            db.collection("locations")
                .whereField("address", isEqualTo: self?.selectedLocation ?? "")     // Search for the document with the same address as the selected location
                .getDocuments { snapshot, _ in
                    // Check if the query returned any documents
                    if let newLocationRef = snapshot?.documents.first?.reference {
                        // If a document is found, pass its reference to the completion handler
                        completion(newLocationRef)
                    }
                }
        }
    }
    
    // Function to add the newly created post to the Firebase database
    private func uploadPost(userID: String, locationRef: DocumentReference) {
        // Upload the images associated with the post
        uploadImages(userID: userID) { [weak self] imageURLs in
            // Once the images are uploaded and image URLs are available, create the post in the database
            self?.createPost(userID: userID, locationRef: locationRef, imageURLs: imageURLs)
        }
    }

    
    private func uploadImages(userID: String, completion: @escaping ([String]) -> Void) {
        // Upload images first
        var imageURLs: [String] = []                        // Initialize an empty array to hold the URLs of the uploaded images
        let group = DispatchGroup()                         // Create a DispatchGroup to track the completion of all image uploads
        
        // Loop through all the images to upload each one
        for (index, image) in images.enumerated() {
            group.enter()                            // Enter the dispatch group for each image upload
            // Create a unique path for each image in Firebase Storage based on userID and a unique UUID
            let imageRef = FirebaseManager.shared.storage.reference(withPath: "posts/\(userID)/\(UUID().uuidString).jpg")
            // Convert the UIImage to JPEG data with 0.7 compression quality
            guard let imageData = image.jpegData(compressionQuality: 0.7) else {
                group.leave()            // Leave the group if the image data conversion fails
                continue                // Skip this image and continue with the next one
            }
            
            // Upload the image data to Firebase Storage at the specified reference
            imageRef.putData(imageData, metadata: nil) { [weak self] _, err in
                // Check for any error during the image upload
                if let err = err {
                    self?.addPostStatusMessage = "Failed to upload image: \(err.localizedDescription)"
                    self?.isLoading = false             // Leave the group if there's an error
                    group.leave()
                    return
                }
                
                // Once the image is uploaded successfully, get the download URL
                imageRef.downloadURL { [weak self] url, err in
                    // Check for any error while fetching the download URL
                    if let err = err {
                        self?.addPostStatusMessage = "Failed to get download URL: \(err.localizedDescription)"
                        self?.isLoading = false
                        group.leave()               // Leave the group if there's an error fetching the URL
                        return
                    }
                    // Append the successfully retrieved URL to the imageURLs array
                    if let url = url {
                        imageURLs.append(url.absoluteString)            // If the URL was successfully retrieved, append its string representation to the imageURLs array.
                        // Update the status message to indicate which image is being uploaded
                        self?.addPostStatusMessage = "Uploading image \(index + 1) of \(self?.images.count ?? 0)..."
                    }
                    // Leave the group when the download URL is fetched
                    group.leave()                // Notify the DispatchGroup that the task for this particular image (fetching the download URL) is complete.
                }
            }
        }
        
        // After all images are uploaded, create the post with location reference
        group.notify(queue: .main) {
            completion(imageURLs)
        }
    }
    
    // Function to reate post with location reference
    private func createPost(userID: String, locationRef: DocumentReference, imageURLs: [String]) {
        let db = FirebaseManager.shared.firestore           // Access the Firestore database using the FirebaseManager
        // Prepare the post data to be added to Firestore
        let postData: [String: Any] = [
            "uid": userID,                              // User ID of the person creating the post
            "rating": rating,                           // Rating given by the user for the post
            "description": descriptionText,             // Description text entered by the user for the post
            "locationRef": locationRef,                 // Reference to the location associated with the post
            "images": imageURLs,                        // URLs of the images associated with the post
            "timestamp": FieldValue.serverTimestamp()  // Timestamp for when the post is created, using Firestore's server timestamp
        ]
        // Add the post data to the "user_posts" collection in Firestore
        db.collection("user_posts").addDocument(data: postData) { [weak self] err in
            if let err = err {                      // If an error occurs during the document creation
                self?.addPostStatusMessage = "Failed to create post: \(err.localizedDescription)"       // Set the error message

                self?.isLoading = false             // Stop the loading indicator
                return                              // Exit the function if there's an error
            }
            
            // Update location's average rating if the post creation is successful
            self?.updateLocationAverageRating(locationRef: locationRef)
            
            // Display a success message and reset the form
            self?.addPostStatusMessage = "Post uploaded successfully!"  // Success message
            self?.clearForm()                       // Clear the form data after the post is uploaded
            self?.isLoading = false                 // Stop the loading indicator
        }
    }
    
    // Function to update the average rating of the location depending the new reating added
    private func updateLocationAverageRating(locationRef: DocumentReference) {
        let db = FirebaseManager.shared.firestore               // Access the Firestore database
        
        // Get all posts for this location to calculate new average rating
        db.collection("user_posts")
            .whereField("locationRef", isEqualTo: locationRef)          // Filter the posts by the specific location reference
            .getDocuments { [weak self] snapshot, error in              // Fetch all documents related to the location
                if let error = error {                                  // Handle any error that occurs during document fetching
                    print("Error getting posts for rating update: \(error.localizedDescription)")               // Log the error
                    return                       // Exit the function if an error occurs
                }
                
                // Initialize variables for calculating the average rating
                var totalRating = 0                 // Total sum of ratings
                var count = 0                       // Counter for the number of posts with ratings
                
                // Iterate over the documents (posts) to accumulate the ratings
                snapshot?.documents.forEach { doc in
                    if let rating = doc.data()["rating"] as? Int {          // Ensure that the rating is an integer
                        totalRating += rating                               // Add the rating to the total
                        count += 1                                          // Increment the count
                    }
                }
                
                // Calculate the new average rating
                let newAverageRating = count > 0 ? Double(totalRating) / Double(count) : Double(self?.rating ?? 0)
                
                // Update the location's average rating in Firestore
                locationRef.updateData(["average_rating": newAverageRating]) { error in
                    if let error = error {                  // Handle any error that occurs during the update
                        print("Error updating location average rating: \(error.localizedDescription)")          // Log the error
                    }
                }
            }
    }
    
    // Function to clear the add post form once the new post information is added into the database
    private func clearForm() {
        descriptionText = ""                     // Clears the text from the description field
        selectedLocation = ""                   // Resets the selected location to an empty string
        images = []                             // Clears the images array, effectively removing any selected images
        rating = 0                              // Resets the rating to its default value of 0
        latitude = 0                            // Resets the latitude to 0 (assuming it’s used for location)
        longitude = 0                           // Resets the longitude to 0 (assuming it’s used for location)
        addPostStatusMessage = ""               // Clears any status messages related to adding the post
    }
}

