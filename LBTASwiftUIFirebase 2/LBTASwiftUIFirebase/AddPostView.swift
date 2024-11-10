import SwiftUI
import MapKit
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import SDWebImageSwiftUI

struct AddPostView: View {
    @State private var descriptionText: String = ""
    @State private var rating: Int = 0
    @State private var selectedLocation: String = ""
    @State private var images: [UIImage] = []
    @State private var isImagePickerPresented = false
    @State private var searchText: String = ""
    @State private var addPostStatusMessage: String = ""
    @State private var latitude: Double = 0.0
    @State private var longitude: Double = 0.0
    @State private var isLoading = false
    @Environment(\.dismiss) var dismiss
    @StateObject private var searchCompleter = LocationSearchCompleter()
    @EnvironmentObject var userManager: UserManager //Current user

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Profile section
                    HStack(alignment: .center) {
                        WebImage(url: URL(string: userManager.currentUser?.profileImageUrl ?? ""))
                            .resizable()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())

                        Text(userManager.currentUser?.username ?? "User 1")
                            .font(.custom("Sansation", size: 18))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                            .background(Color(red: 140/255, green: 82/255, blue: 255/255))
                            .cornerRadius(12)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Description
                    TextField("Description of the recently visited place...", text: $descriptionText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .lineLimit(nil) // Allow for multiple lines
                    
                    Divider()
                    
                    // Location Search
                    LocationSearchBar(selectedLocation: $selectedLocation, latitude: $latitude, longitude: $longitude)
                    
                    Divider()
                    
                    // Rating Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rating")
                            .font(.headline)
                        
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundColor(star <= rating ? .yellow : .gray)
                                    .onTapGesture {
                                        rating = star
                                    }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // Photos Section
                    VStack(alignment: .leading, spacing: 8) {
                        Button(action: {
                            isImagePickerPresented = true
                        }) {
                            HStack {
                                Image(systemName: "photo")
                                Text("Add Photos")
                                Spacer()
                            }
                            .foregroundColor(.primary)
                        }
                        .padding(.horizontal)
                        
                        if !images.isEmpty {
                            LazyVGrid(columns: columns, spacing: 8) {
                                ForEach(images, id: \.self) { image in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 150)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        
                                        Button(action: {
                                            if let index = images.firstIndex(of: image) {
                                                images.remove(at: index)
                                            }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .background(Color.white)
                                                .clipShape(Circle())
                                                .padding(4)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    if !addPostStatusMessage.isEmpty {
                        Text(addPostStatusMessage)
                            .foregroundColor(addPostStatusMessage.contains("Error") ? .red : .green)
                            .padding()
                    }
                    
                    // Post Button
                    Button(action: {
                        addPost()
                    }) {
                        Text("Post")
                            .font(.custom("Sansation-Regular", size: 20))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                isLoading ? Color.gray : Color(red: 140/255, green: 82/255, blue: 255/255)
                            )
                            .cornerRadius(12)
                    }
                    .disabled(isLoading)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .padding (.top, 10)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("New Post")
                        .font(.headline)
                }
                /*
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }*/
            }
        }
        .sheet(isPresented: $isImagePickerPresented) {
            AddPhotos(images: $images)
        }
    }

    private func addPost() {
        // Input validation
        if descriptionText.isEmpty {
            addPostStatusMessage = "Please enter a description for your post"
            return
        }
        
        if selectedLocation.isEmpty {
            addPostStatusMessage = "Please select a location for your post"
            return
        }
        
        if images.isEmpty {
            addPostStatusMessage = "Please add some images for your post"
            return
        }
        
        guard let userID = FirebaseManager.shared.auth.currentUser?.uid else {
            addPostStatusMessage = "User not authenticated"
            return
        }
        
        // Show loading state
        isLoading = true
        addPostStatusMessage = "Uploading post..."
        
        // First, check if location exists and handle location logic
        handleLocation { locationRef in
            // Now proceed with post upload
            uploadPost(userID: userID, locationRef: locationRef)
        }
    }

    private func handleLocation(completion: @escaping (DocumentReference) -> Void) {
        let db = FirebaseManager.shared.firestore
        
        // Query for existing location
        db.collection("locations")
            .whereField("address", isEqualTo: selectedLocation)
            .getDocuments { snapshot, error in
                if let error = error {
                    self.addPostStatusMessage = "Error checking location: \(error.localizedDescription)"
                    self.isLoading = false
                    return
                }
                
                if let existingLocation = snapshot?.documents.first {
                    // Location exists, use its reference
                    completion(existingLocation.reference)
                } else {
                    // Location doesn't exist, create new one
                    let locationData: [String: Any] = [
                        "address": selectedLocation,
                        "location_coordinates": [latitude, longitude],
                        "average_rating": rating  // Initial rating
                    ]
                    
                    // Add new location
                    db.collection("locations").addDocument(data: locationData) { error in
                        if let error = error {
                            self.addPostStatusMessage = "Error creating location: \(error.localizedDescription)"
                            self.isLoading = false
                            return
                        }
                        
                        // Get the reference of the newly created location
                        db.collection("locations")
                            .whereField("address", isEqualTo: self.selectedLocation)
                            .getDocuments { snapshot, error in
                                if let newLocationRef = snapshot?.documents.first?.reference {
                                    completion(newLocationRef)
                                }
                            }
                    }
                }
            }
    }

    private func uploadPost(userID: String, locationRef: DocumentReference) {
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
            
            imageRef.putData(imageData, metadata: nil) { metadata, err in
                if let err = err {
                    self.addPostStatusMessage = "Failed to upload image: \(err.localizedDescription)"
                    self.isLoading = false
                    group.leave()
                    return
                }
                
                imageRef.downloadURL { url, err in
                    if let err = err {
                        self.addPostStatusMessage = "Failed to get download URL: \(err.localizedDescription)"
                        self.isLoading = false
                        group.leave()
                        return
                    }
                    
                    if let url = url {
                        imageURLs.append(url.absoluteString)
                        self.addPostStatusMessage = "Uploading image \(index + 1) of \(self.images.count)..."
                    }
                    group.leave()
                }
            }
        }
        
        // After all images are uploaded, create the post with location reference
        group.notify(queue: .main) {
            let db = FirebaseManager.shared.firestore
            
            // Create post with location reference
            let postData: [String: Any] = [
                "uid": userID,
                "rating": self.rating,
                "description": self.descriptionText,
                "locationRef": locationRef,  // Store reference to location document
                "images": imageURLs,
                "timestamp": FieldValue.serverTimestamp()
            ]
            
            db.collection("user_posts").addDocument(data: postData) { err in
                if let err = err {
                    self.addPostStatusMessage = "Failed to create post: \(err.localizedDescription)"
                    self.isLoading = false
                    return
                }
                
                // Update location's average rating
                self.updateLocationAverageRating(locationRef: locationRef)
                
                // Success
                self.addPostStatusMessage = "Post uploaded successfully!"
                self.clearForm()
                
                // Dismiss the view after successful upload
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.dismiss()
                }
                self.isLoading = false
            }
        }
    }

    private func updateLocationAverageRating(locationRef: DocumentReference) {
        let db = FirebaseManager.shared.firestore
        
        // Get all posts for this location to calculate new average
        db.collection("user_posts")
            .whereField("locationRef", isEqualTo: locationRef)
            .getDocuments { snapshot, error in
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
                
                let newAverageRating = count > 0 ? Double(totalRating) / Double(count) : Double(self.rating)
                
                // Update location with new average rating
                locationRef.updateData([
                    "average_rating": newAverageRating
                ]) { error in
                    if let error = error {
                        print("Error updating location average rating: \(error.localizedDescription)")
                    }
                }
            }
    }

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
