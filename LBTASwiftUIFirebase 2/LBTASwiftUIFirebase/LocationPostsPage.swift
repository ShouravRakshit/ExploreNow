import SwiftUI
import CoreLocation
import MapKit
import Firebase
import FirebaseFirestore
import SDWebImageSwiftUI

struct LocationDetails {
    let mainAddress: String
    let fullAddress: String
    let averageRating: Double
}

struct LocationPostsPage: View {
    let locationRef: DocumentReference
    @State private var locationPosts: [Post] = []
    @State private var locationDetails: LocationDetails?
    @State private var isLoading = true
    @State private var headerImageUrl: String? = nil
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    if isLoading {
                        loadingView
                    } else {
                        VStack(spacing: 0) {
                            headerSection
                            locationInfoSection
                            postsSection
                        }
                    }
                }
            }
            .edgesIgnoringSafeArea(.top)
            .background(AppTheme.background)
            .onAppear {
                fetchLocationDetails()
                fetchLocationPosts()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - UI Components
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(AppTheme.primaryPurple)
            Text("Loading location details...")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    private var headerSection: some View {
        ZStack(alignment: .bottom) {
            // Header Image
            Group {
                if let imageUrl = headerImageUrl {
                    WebImage(url: URL(string: imageUrl))
                        .resizable()
                        .scaledToFill()
                        .frame(height: 250)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(AppTheme.secondaryBackground)
                        .frame(height: 250)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(AppTheme.secondaryText)
                        )
                }
            }
            
            // Gradient overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.5),
                    Color.black.opacity(0)
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 150)
        }
        .frame(height: 250)
    }
    
    private var locationInfoSection: some View {
        VStack(spacing: 16) {
            // Location Name
            Text(locationDetails?.mainAddress ?? "Location")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppTheme.primaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 16)
            
            // Address
            if let fullAddress = locationDetails?.fullAddress {
                Button(action: { openInMaps() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 16))
                        Text(fullAddress)
                            .font(.system(size: 14))
                    }
                    .foregroundColor(AppTheme.primaryPurple)
                }
                .padding(.horizontal)
            }
            
            // Rating and Directions
            HStack(spacing: 20) {
                // Rating
                HStack(spacing: 4) {
                    Text(String(format: "%.1f", locationDetails?.averageRating ?? 0))
                        .font(.system(size: 16, weight: .semibold))
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AppTheme.lightPurple)
                .cornerRadius(12)
                
                // Directions Button
                Button(action: { openInMapsWithDirections() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "car.fill")
                        Text("Get Directions")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppTheme.primaryPurple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .padding(.vertical, 8)
            
            Divider()
                .padding(.horizontal)
        }
        .background(AppTheme.background)
    }
    
    private var postsSection: some View {
        VStack(spacing: 16) {
            // Section Header
            HStack {
                Text("Posts")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppTheme.primaryText)
                
                Spacer()
                
                Text("\(locationPosts.count)")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.secondaryText)
            }
            .padding(.horizontal)
            .padding(.top, 16)
            
            // Posts List
            if locationPosts.isEmpty {
                emptyPostsView
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(locationPosts) { post in
                        PostCard(post: post)
                            .environmentObject(userManager)
                            .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.bottom, 20)
    }
    
    private var emptyPostsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.stack")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.secondaryText)
            
            Text("No posts yet for this location")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(AppTheme.background)
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
    
    private func openInMaps() {
        fetchLocationCoordinates { coordinates in
            guard let coordinates = coordinates else { return }
            
            let coordinate = CLLocationCoordinate2D(
                latitude: coordinates[0],
                longitude: coordinates[1]
            )
            let placemark = MKPlacemark(coordinate: coordinate)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = locationDetails?.mainAddress
            mapItem.openInMaps(launchOptions: nil)
        }
    }

    private func openInMapsWithDirections() {
        fetchLocationCoordinates { coordinates in
            guard let coordinates = coordinates else { return }
            
            let coordinate = CLLocationCoordinate2D(
                latitude: coordinates[0],
                longitude: coordinates[1]
            )
            let placemark = MKPlacemark(coordinate: coordinate)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = locationDetails?.mainAddress
            
            // Set launch options for directions
            let launchOptions = [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ]
            
            mapItem.openInMaps(launchOptions: launchOptions)
        }
    }
    
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


    
    private func fetchLocationPosts() {
        print("DEBUG: Starting to fetch posts for location: \(locationRef.documentID)")
        
        let db = FirebaseManager.shared.firestore
        
        db.collection("user_posts")
            .whereField("locationRef", isEqualTo: locationRef)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("DEBUG: Error fetching posts: \(error)")
                    return
                }
                
                print("DEBUG: Received \(querySnapshot?.documentChanges.count ?? 0) post changes")
                
                // Process each document change
                querySnapshot?.documentChanges.forEach { change in
                    if change.type == .added {
                        let data = change.document.data()
                        let postId = change.document.documentID
                        
                        // Handle header image first
                        if let imageUrls = data["images"] as? [String],
                           !imageUrls.isEmpty,
                           self.headerImageUrl == nil {
                            self.headerImageUrl = imageUrls.randomElement()
                            print("DEBUG: Set header image from post: \(postId)")
                        }
                        
                        // Get location details first
                        guard let locationRef = data["locationRef"] as? DocumentReference else { return }
                        
                        // Fetch location details
                        locationRef.getDocument { locationSnapshot, locationError in
                            if let locationError = locationError {
                                print("DEBUG: Error fetching location: \(locationError)")
                                return
                            }
                            
                            guard let locationData = locationSnapshot?.data(),
                                  let address = locationData["address"] as? String else {
                                print("DEBUG: No location data found")
                                return
                            }
                            
                            // Now fetch user details
                            if let userId = data["uid"] as? String {
                                db.collection("users")
                                    .document(userId)
                                    .getDocument { userSnapshot, userError in
                                        if let userError = userError {
                                            print("DEBUG: Error fetching user details: \(userError)")
                                            return
                                        }
                                        
                                        let userData = userSnapshot?.data() ?? [:]
                                        let username = userData["username"] as? String ?? "Unknown User"
                                        let userProfileImageUrl = userData["profileImageUrl"] as? String ?? ""
                                        
                                        let post = Post(
                                            id: postId,
                                            description: data["description"] as? String ?? "",
                                            rating: data["rating"] as? Int ?? 0,
                                            locationRef: locationRef,
                                            locationAddress: address,  // Use the fetched address
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
                                                print("DEBUG: Added post from user \(username) with location: \(address)")
                                            }
                                        }
                                    }
                            }
                        }
                    }
                }
            }
    }
}
