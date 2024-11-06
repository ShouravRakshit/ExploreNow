
import SwiftUI
import Firebase
import MapKit
import FirebaseFirestore
import SDWebImageSwiftUI  // For WebImage

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
    
    // Move LocationDetails outside of the view
}

// Move LocationDetails struct outside the view
struct LocationDetails {
    let mainAddress: String
    let fullAddress: String
    let averageRating: Double
}

extension LocationPostsPage {
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView()
            } else {
                // Header Image with location and rating
                ZStack(alignment: .bottom) {
                    Image("banff") // You might want to add location images later
                        .resizable()
                        .scaledToFill()
                        .frame(height: 250)
                        .clipped()
                    
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
        FirebaseManager.shared.firestore
            .collection("user_posts")
            .whereField("locationRef", isEqualTo: locationRef)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error fetching posts: \(error)")
                    return
                }
                
                querySnapshot?.documentChanges.forEach { change in
                    if change.type == .added {
                        let data = change.document.data()
                        
                        let post = Post(
                            id: change.document.documentID,
                            description: data["description"] as? String ?? "",
                            rating: data["rating"] as? Int ?? 0,
                            locationRef: locationRef,
                            locationAddress: locationDetails?.mainAddress ?? "",
                            imageUrls: data["images"] as? [String] ?? [],
                            timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                            uid: data["uid"] as? String ?? "",
                            username: "User", // You might want to fetch this from the user document
                            userProfileImageUrl: "" // You might want to fetch this from the user document
                        )
                        
                        if !locationPosts.contains(where: { $0.id == post.id }) {
                            locationPosts.append(post)
                            locationPosts.sort { $0.timestamp > $1.timestamp }
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
    
    // Helper function to format the date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
