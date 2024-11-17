import SwiftUI
import CoreLocation
import MapKit
import Firebase
import FirebaseFirestore
import SDWebImageSwiftUI

struct LocationPostsPage: View {
    let locationRef: DocumentReference
    @State private var locationPosts: [Post] = []
    @State private var locationDetails: LocationDetails?
    @State private var isLoading = true
    @State private var headerImageUrl: String? = nil  // Add this property

}

struct LocationDetails {
    let mainAddress: String
    let fullAddress: String
    let averageRating: Double
}

extension LocationPostsPage {

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                } else {
                    // Header Image with location and rating
                    ZStack(alignment: .bottom) {
                        if let imageUrl = headerImageUrl {
                            WebImage(url: URL(string: imageUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(height: 250)
                                .clipped()
                        } else {
                            // Fallback image or color when no images are available
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 250)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 40))
                                )
                        }

                        // Location info overlay
                        VStack(spacing: 8) {
                            // Main address (POI)
                            Text(locationDetails?.mainAddress ?? "Location")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            // Full address
                            if let fullAddress = locationDetails?.fullAddress {
                                Text(fullAddress)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            
                            // Rating
                            HStack(spacing: 4) {
                                Text(String(format: "%.1f", locationDetails?.averageRating ?? 0))
                                    .font(.headline)
                                    .foregroundColor(.black)
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .shadow(radius: 3)
                        }
                        .padding(.bottom, 50)
                        .shadow(radius: 5)
                    }
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            if locationPosts.isEmpty {
                                Text("No posts yet for this location")
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                ForEach(locationPosts) { post in
                                    LocationPostView(post: post)
                                }
                            }
                        }
                        .padding(.top)
                    }
                }
                
                Spacer()
            }
            .edgesIgnoringSafeArea(.top)
            .onAppear {
                fetchLocationDetails()
                fetchLocationPosts()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func fetchLocationDetails() {
        locationRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching location details: \(error)")
                return
            }
            
            if let data = snapshot?.data() {
                let address = data["address"] as? String ?? ""
                let coordinates = data["location_coordinates"] as? [Double] ?? []
                let averageRating = data["average_rating"] as? Double ?? 0
                
                // Get detailed address using reverse geocoding
                if coordinates.count == 2 {
                    let location = CLLocation(latitude: coordinates[0], longitude: coordinates[1])
                    let geocoder = CLGeocoder()
                    
                    geocoder.reverseGeocodeLocation(location) { placemarks, error in
                        if let error = error {
                            print("Reverse geocoding error: \(error)")
                            return
                        }
                        
                        if let placemark = placemarks?.first {
                            // Extract POI or street name as main address
                            let mainAddress = placemark.name ?? address
                            
                            // Build full address
                            var fullAddressComponents: [String] = []
                            
                            if let streetNumber = placemark.subThoroughfare {
                                fullAddressComponents.append(streetNumber)
                            }
                            if let street = placemark.thoroughfare {
                                fullAddressComponents.append(street)
                            }
                            if let city = placemark.locality {
                                fullAddressComponents.append(city)
                            }
                            if let state = placemark.administrativeArea {
                                fullAddressComponents.append(state)
                            }
                            if let country = placemark.country {
                                fullAddressComponents.append(country)
                            }
                            
                            let fullAddress = fullAddressComponents.joined(separator: ", ")
                            
                            DispatchQueue.main.async {
                                locationDetails = LocationDetails(
                                    mainAddress: mainAddress,
                                    fullAddress: fullAddress,
                                    averageRating: averageRating
                                )
                                isLoading = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func fetchLocationPosts() {
        print("DEBUG: Starting to fetch posts for location: \(locationRef.documentID)")
        
        FirebaseManager.shared.firestore
            .collection("user_posts")
            .whereField("locationRef", isEqualTo: locationRef)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("DEBUG: Error fetching posts: \(error)")
                    return
                }
                
                print("DEBUG: Received \(querySnapshot?.documentChanges.count ?? 0) post changes")
                
                querySnapshot?.documentChanges.forEach { change in
                    if change.type == .added {
                        let data = change.document.data()
                        let postId = change.document.documentID
                        if let imageUrls = data["images"] as? [String], !imageUrls.isEmpty {
                            // If we don't have a header image yet, set one
                            if self.headerImageUrl == nil {
                                // Get a random image from the post's images
                                self.headerImageUrl = imageUrls.randomElement()
                                print("DEBUG: Set header image from post: \(change.document.documentID)")
                            }
                        }

                        print("DEBUG: Processing post: \(postId)")
                        
                        // Get the user ID from the post
                        if let userId = data["uid"] as? String {
                            print("DEBUG: Fetching user details for user: \(userId)")
                            
                            // Fetch user details
                            FirebaseManager.shared.firestore
                                .collection("users")
                                .document(userId)
                                .getDocument { userSnapshot, userError in
                                    if let userError = userError {
                                        print("DEBUG: Error fetching user details: \(userError)")
                                        return
                                    }
                                    
                                    // Get user data
                                    let userData = userSnapshot?.data() ?? [:]
                                    let username = userData["username"] as? String ?? "Unknown User"
                                    let userProfileImageUrl = userData["profileImageUrl"] as? String ?? ""
                                    
                                    print("DEBUG: Found user: \(username)")
                                    
                                    let post = Post(
                                        id: postId,
                                        description: data["description"] as? String ?? "",
                                        rating: data["rating"] as? Int ?? 0,
                                        locationRef: self.locationRef,
                                        locationAddress: self.locationDetails?.mainAddress ?? "",
                                        imageUrls: data["images"] as? [String] ?? [],
                                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                                        uid: userId,
                                        username: username,
                                        userProfileImageUrl: userProfileImageUrl
                                    )
                                    
                                    DispatchQueue.main.async {
                                        if !self.locationPosts.contains(where: { $0.id == post.id }) {
                                            self.locationPosts.append(post)
                                            self.locationPosts.sort { $0.timestamp > $1.timestamp }
                                            if headerImageUrl == nil, let firstImage = post.imageUrls.first {
                                                headerImageUrl = firstImage
                                                print("DEBUG: Set header image from new post: \(post.id)")
                                            }

                                            print("DEBUG: Added post to location posts. Total posts: \(self.locationPosts.count)")
                                        }
                                    }
                                }
                        }
                    }
                }
            }
    }
}
struct LocationPostView: View {
    let post: Post
    @State private var currentImageIndex = 0
    
    var body: some View {
        NavigationLink(destination: PostView(post: post, likesCount: post.likesCount, liked: post.liked)) {
            VStack(alignment: .leading, spacing: 0) {
                // Top section with user image and username
                HStack(alignment: .center) {
                    if let imageUrl = URL(string: post.userProfileImageUrl) {
                        WebImage(url: imageUrl)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    }
                    
                    Text(post.username)
                        .font(.custom("Sansation", size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 5)
                        .background(Color(red: 140/255, green: 82/255, blue: 255/255))
                        .cornerRadius(15)
                    
                    Spacer()
                }
                .padding([.top, .horizontal])
                
                // Post images carousel
                if !post.imageUrls.isEmpty {
                    TabView(selection: $currentImageIndex) {
                        ForEach(post.imageUrls.indices, id: \.self) { index in
                            if let imageUrl = URL(string: post.imageUrls[index]) {
                                WebImage(url: imageUrl)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 150)
                                    .clipped()
                                    .tag(index)
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 150)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.gray)
                                    )
                                    .tag(index)
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .frame(height: 150)
                    .padding(.horizontal)
                    .padding(.top, 6)
                }
                
                // Description if any
                if !post.description.isEmpty {
                    Text(post.description)
                        .font(.system(size: 14))
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                
                // Bottom section with rating and timestamp
                HStack {
                    Image(systemName: "star.fill").foregroundColor(Color.customPurple)
                    Text("\(post.rating)")
                    
                    Spacer()
                    
                    Text(formatDate(post.timestamp))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .font(.system(size: 14))
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 5)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.customPurple, lineWidth: 1))
        }
    }
    
    // Helper function to format the date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
