import SwiftUI
import MapKit
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

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
                        Image("user_profile")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())

                        Text("User 1")
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("New Post")
                        .font(.headline)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
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
        
        var imageURLs: [String] = []
        let group = DispatchGroup()
        
        // Upload each image
        for (index, image) in images.enumerated() {
            group.enter()
            
            let imageRef = FirebaseManager.shared.storage.reference(withPath: "posts/\(userID)/\(UUID().uuidString).jpg")
            
            guard let imageData = image.jpegData(compressionQuality: 0.7) else {
                group.leave()
                continue
            }
            
            // Upload image
            imageRef.putData(imageData, metadata: nil) { metadata, err in
                if let err = err {
                    self.addPostStatusMessage = "Failed to upload image: \(err.localizedDescription)"
                    self.isLoading = false
                    group.leave()
                    return
                }
                
                // Get download URL
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
        
        group.notify(queue: .main) {
            let db = FirebaseManager.shared.firestore
            let postData: [String: Any] = [
                "uid": userID,
                "rating": rating,
                "description": descriptionText,
                "location": selectedLocation,
                "location_coordinates": [latitude, longitude],
                "images": imageURLs,
                "timestamp": FieldValue.serverTimestamp()
            ]

            db.collection("user_posts").addDocument(data: postData) { err in
                if let err = err {
                    self.addPostStatusMessage = "Failed to create post: \(err.localizedDescription)"
                    self.isLoading = false
                    return
                }
                
                self.addPostStatusMessage = "Post uploaded successfully!"
                self.clearForm()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.dismiss()
                }
                self.isLoading = false
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
    }
}
