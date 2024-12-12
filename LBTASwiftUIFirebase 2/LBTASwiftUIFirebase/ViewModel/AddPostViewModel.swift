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

class AddPostViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var descriptionText: String = ""
    @Published var rating: Int = 0
    @Published var selectedLocation: String = ""
    @Published var images: [UIImage] = []
    @Published var latitude: Double = 0.0
    @Published var longitude: Double = 0.0
    @Published var isLoading = false
    @Published var addPostStatusMessage: String = ""
    
    // MARK: - Dependency Injection
    @Published var userManager: UserManager // Manages user-related logic and actions.
    @Published var locationManager = CustomLocationManager() // Manages user-related logic and actions.
    
    init() {
    // Initialize with default instances
    self.userManager = UserManager() // Default instance, replace as needed
    self.locationManager = CustomLocationManager() // Default instance, replace as needed
    }
    
    // Function to check if all the necessary fields in Add post view are filled before uploading
    func addPost() {
        guard validateInput() else { return }
        guard let userID = FirebaseManager.shared.auth.currentUser?.uid else {
            addPostStatusMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        addPostStatusMessage = "Uploading post..."
        
        handleLocation { [weak self] locationRef in
            self?.uploadPost(userID: userID, locationRef: locationRef)
        }
    }
    
    // Input validation
    private func validateInput() -> Bool {
        if descriptionText.isEmpty {
            addPostStatusMessage = "Please enter a description for your post"
            return false
        }
        if selectedLocation.isEmpty {
            addPostStatusMessage = "Please select a location for your post"
            return false
        }
        if images.isEmpty {
            addPostStatusMessage = "Please add some images for your post"
            return false
        }
        return true
    }
    
    
    // Function to get the corrdinates of the location tagged and add them to the map view
    // Case when the location pin already exists on map then add to it
    private func handleLocation(completion: @escaping (DocumentReference) -> Void) {
        let db = FirebaseManager.shared.firestore
        db.collection("locations")
            .whereField("address", isEqualTo: selectedLocation)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    self?.addPostStatusMessage = "Error checking location: \(error.localizedDescription)"
                    self?.isLoading = false
                    return
                }
                
                if let existingLocation = snapshot?.documents.first {
                    completion(existingLocation.reference)
                } else {
                    self?.createNewLocation(completion: completion)
                }
            }
    }
    
    // Function to get the corrdinates of the location tagged and add them to the map view
    // Case when the location pin does not already exists on map then create one
    private func createNewLocation(completion: @escaping (DocumentReference) -> Void) {
        let db = FirebaseManager.shared.firestore
        let locationData: [String: Any] = [
            "address": selectedLocation,
            "location_coordinates": [latitude, longitude],
            "average_rating": rating
        ]
        
        db.collection("locations").addDocument(data: locationData) { [weak self] error in
            if let error = error {
                self?.addPostStatusMessage = "Error creating location: \(error.localizedDescription)"
                self?.isLoading = false
                return
            }
            
            db.collection("locations")
                .whereField("address", isEqualTo: self?.selectedLocation ?? "")
                .getDocuments { snapshot, _ in
                    if let newLocationRef = snapshot?.documents.first?.reference {
                        completion(newLocationRef)
                    }
                }
        }
    }
    
    // Function to add the newly created post to the Firebase database
    private func uploadPost(userID: String, locationRef: DocumentReference) {
        uploadImages(userID: userID) { [weak self] imageURLs in
            self?.createPost(userID: userID, locationRef: locationRef, imageURLs: imageURLs)
        }
    }
    
    private func uploadImages(userID: String, completion: @escaping ([String]) -> Void) {
        // Upload images first
        var imageURLs: [String] = []
        let group = DispatchGroup()
        
        for (index, image) in images.enumerated() {
            group.enter()
            let imageRef = FirebaseManager.shared.storage.reference(withPath: "posts/\(userID)/\(UUID().uuidString).jpg")
            guard let imageData = image.jpegData(compressionQuality: 0.7) else {
                group.leave()
                continue
            }
            
            imageRef.putData(imageData, metadata: nil) { [weak self] _, err in
                if let err = err {
                    self?.addPostStatusMessage = "Failed to upload image: \(err.localizedDescription)"
                    self?.isLoading = false
                    group.leave()
                    return
                }
                
                imageRef.downloadURL { [weak self] url, err in
                    if let err = err {
                        self?.addPostStatusMessage = "Failed to get download URL: \(err.localizedDescription)"
                        self?.isLoading = false
                        group.leave()
                        return
                    }
                    
                    if let url = url {
                        imageURLs.append(url.absoluteString)
                        self?.addPostStatusMessage = "Uploading image \(index + 1) of \(self?.images.count ?? 0)..."
                    }
                    group.leave()
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
        let db = FirebaseManager.shared.firestore
        let postData: [String: Any] = [
            "uid": userID,
            "rating": rating,
            "description": descriptionText,
            "locationRef": locationRef,
            "images": imageURLs,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        db.collection("user_posts").addDocument(data: postData) { [weak self] err in
            if let err = err {
                self?.addPostStatusMessage = "Failed to create post: \(err.localizedDescription)"
                self?.isLoading = false
                return
            }
            
            // Update location's average rating
            self?.updateLocationAverageRating(locationRef: locationRef)
            
            // Success
            self?.addPostStatusMessage = "Post uploaded successfully!"
            self?.clearForm()
            self?.isLoading = false
        }
    }
    
    // Function to update the average rating of the location depending the new reating added
    private func updateLocationAverageRating(locationRef: DocumentReference) {
        let db = FirebaseManager.shared.firestore
        
        // Get all posts for this location to calculate new average
        db.collection("user_posts")
            .whereField("locationRef", isEqualTo: locationRef)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("Error getting posts for rating update: \(error.localizedDescription)")
                    return
                }
                
                // Calculate new average
                var totalRating = 0
                var count = 0
                
                snapshot?.documents.forEach { doc in
                    if let rating = doc.data()["rating"] as? Int {
                        totalRating += rating
                        count += 1
                    }
                }
                
                let newAverageRating = count > 0 ? Double(totalRating) / Double(count) : Double(self?.rating ?? 0)
                
                // Update location with new average rating
                locationRef.updateData(["average_rating": newAverageRating]) { error in
                    if let error = error {
                        print("Error updating location average rating: \(error.localizedDescription)")
                    }
                }
            }
    }
    
    // Function to clear the add post form once the new post information is added into the database
    private func clearForm() {
        descriptionText = ""
        selectedLocation = ""
        images = []
        rating = 0
        latitude = 0
        longitude = 0
        addPostStatusMessage = ""
    }
}
