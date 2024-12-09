import SwiftUI
import MapKit
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import SDWebImageSwiftUI
import CoreLocation
import Combine

struct AddPostView: View {
    // Keeping all existing state variables
    @State private var descriptionText: String = ""
    @State private var rating: Int = 0
    @State private var selectedLocation: String = ""
    @State private var images: [UIImage] = []
//    @State private var isImagePickerPresented = false
    @State private var searchText: String = ""
    @State private var addPostStatusMessage: String = ""
    @State private var latitude: Double = 0.0
    @State private var longitude: Double = 0.0
    @State private var isLoading = false
    @State private var showPixabayPicker = false
    @State private var showImageSourceOptions = false
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var searchCompleter = LocationSearchCompleter()
    @EnvironmentObject var userManager: UserManager
    @StateObject private var locationManager = CustomLocationManager()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Images Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Photos")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                // Add Photo Button
                                Button(action: { showImageSourceOptions = true }) {
                                    VStack {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 24))
                                        Text("Add Photos")
                                            .font(.system(size: 12))
                                    }
                                    .frame(width: 100, height: 100)
                                    .background(AppTheme.lightPurple)
                                    .foregroundColor(AppTheme.primaryPurple)
                                    .cornerRadius(12)
                                }
                                
                                // Image Previews
                                ForEach(images, id: \.self) { image in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        
                                        // Delete Button
                                        Button(action: {
                                            if let index = images.firstIndex(of: image) {
                                                images.remove(at: index)
                                            }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white)
                                                .background(Color.black.opacity(0.6))
                                                .clipShape(Circle())
                                        }
                                        .padding(4)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Description Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.system(size: 16, weight: .semibold))
                        
                        TextField("Share your experience...", text: $descriptionText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .frame(height: 100, alignment: .top)
                            .padding(8)
                            .background(AppTheme.background)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .lineLimit(5...10)
                            .tint(.blue)
                    }
                    .padding(.horizontal)
                    
                    // Location Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(.system(size: 16, weight: .semibold))
                        
                        LocationSearchBar(selectedLocation: $selectedLocation,
                                        latitude: $latitude,
                                        longitude: $longitude)
                            .background(AppTheme.background)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)
                    
                    // Rating Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rating")
                            .font(.system(size: 16, weight: .semibold))
                        
                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.system(size: 24))
                                    .foregroundColor(star <= rating ? .yellow : Color(.systemGray4))
                                    .onTapGesture {
                                        withAnimation(.spring()) {
                                            rating = star
                                        }
                                    }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Status Message
                    if !addPostStatusMessage.isEmpty {
                        Text(addPostStatusMessage)
                            .font(.system(size: 14))
                            .foregroundColor(addPostStatusMessage.contains("Error") ?
                                           AppTheme.error : AppTheme.success)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                addPostStatusMessage.contains("Error") ?
                                AppTheme.error.opacity(0.1) : AppTheme.success.opacity(0.1)
                            )
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                    
                    // Post Button
                    Button(action: { addPost() }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 8)
                            }
                            Text("Share Post")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isLoading ? Color.gray : AppTheme.primaryPurple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .padding(.vertical, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("New Post")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .background(AppTheme.background)
        }
        .sheet(isPresented: $showPixabayPicker) {
                    PixabayImagePickerView(allowsMultipleSelection: true) { selectedImages in
                        let group = DispatchGroup()
                        for selectedImage in selectedImages {
                            if let urlString = selectedImage.largeImageURL,
                               let url = URL(string: urlString) {
                                group.enter()
                                downloadImage(from: url) { image in
                                    if let image = image {
                                        self.images.append(image)
                                    }
                                    group.leave()
                                }
                            }
                        }
                        group.notify(queue: .main) {
                            print("All images downloaded and added.")
                        }
                    }
                }
        .actionSheet(isPresented: $showImageSourceOptions) {
            ActionSheet(
                title: Text("Select Image Source"),
                message: nil,
                buttons: [
                    .default(Text("Photo Library")) { showPixabayPicker = true },
                    .cancel()
                ]
            )
        }

    }

    
    private func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
            SDWebImageDownloader.shared.downloadImage(with: url) { image, data, error, finished in
                DispatchQueue.main.async {
                    if let image = image, finished {
                        completion(image)
                    } else {
                        print("Failed to download image: \(error?.localizedDescription ?? "Unknown error")")
                        completion(nil)
                    }
                }
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
