
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

import SwiftUI
import CoreLocation
import MapKit
import Firebase
import FirebaseFirestore
import SDWebImageSwiftUI

// Struct to hold location details like the main address, full address, and average rating
struct LocationDetails {
    let mainAddress: String // Stores the main address of the location
    let fullAddress: String // Stores the full address of the location
    let averageRating: Double // Stores the average rating for the location
}

// View for displaying location posts, details, and related information
struct LocationPostsPage: View {
    let locationRef: DocumentReference // Reference to the specific location's Firestore document
    @State private var locationPosts: [Post] = [] // Array to store posts related to the location
    @State private var locationDetails: LocationDetails? // Optional to store location details fetched from Firestore
    @State private var isLoading = true // Boolean to indicate if the data is still being loaded
    @State private var headerImageUrl: String? = nil // URL of the image for the location's header, optional

    @EnvironmentObject var userManager: UserManager // Shared environment object to manage the user session
    
    var body: some View {
        // The main view of the page, a NavigationView for navigation stack
        NavigationView {
            // A scrollable view containing all content on the page
            ScrollView {
                // Stack layout for arranging content vertically
                VStack(spacing: 0) {
                    // Display a loading view when data is being fetched
                    if isLoading {
                        loadingView // The custom loading view while data is being fetched
                    } else {
                        // Once data is loaded, show the sections of the page
                        VStack(spacing: 0) {
                            headerSection // Section for location header
                            locationInfoSection // Section for displaying location details (address, rating, etc.)
                            postsSection  // Section for displaying posts related to the location
                        }
                    }
                }
            }
            // Extension of the existing body of the view to handle the appearance and background of the page
            .edgesIgnoringSafeArea(.top) // Ensures that the content extends to the top of the screen, ignoring the safe area (status bar area).
            .background(AppTheme.background)  // Applies a custom background color defined in the AppTheme to the entire view.
            .onAppear { // Runs when the view appears on the screen, triggering the fetching of data.
                fetchLocationDetails()  // Fetches location details (e.g., address, rating) from Firestore
                fetchLocationPosts()  // Fetches posts related to the location from Firestore.
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())  // Specifies the navigation style to use for the NavigationView. StackNavigationViewStyle is used to control the layout in a stack-based manner, typically useful for phone screens.
    }
    
    // MARK: - UI Components

    // A private computed property for the loading view, which is displayed while the data is being fetched.
    
    private var loadingView: some View {
        // Vertical stack layout for the loading view
        VStack(spacing: 16) {
            ProgressView() // A native SwiftUI view that shows a progress indicator
                .scaleEffect(1.5)  // Scales the progress indicator for better visibility
                .tint(AppTheme.primaryPurple)  // Custom color tint for the progress indicator, defined in the app's theme
            Text("Loading location details...") // Text displayed alongside the loading indicator
                .font(.system(size: 14))  // Specifies the font size for the text
                .foregroundColor(AppTheme.secondaryText) // Custom text color, defined in the app's theme
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)   // Ensures the loading view takes up the full available space
        .padding(.top, 100)  // Adds padding at the top to position the loading view slightly lower from the top of the screen
    }
    
    // MARK: - Header Section UI Component
    private var headerSection: some View {
        ZStack(alignment: .bottom) { // ZStack allows us to layer views on top of each other, with the alignment set to .bottom
            // Header Image
            Group { // Group is used to group views conditionally without affecting the layout
                if let imageUrl = headerImageUrl {  // Checks if there's a valid image URL
                    WebImage(url: URL(string: imageUrl))  // Loads the image from the URL
                        .resizable() // Makes the image resizable to fill the frame
                        .scaledToFill()  // Ensures the image fills the frame while maintaining its aspect ratio
                        .frame(height: 250)  // Sets the frame height of the image to 250 points
                        .clipped()  // Clips any part of the image that goes outside the frame
                } else {  // If no image URL is available, display a placeholder
                    Rectangle() // A simple rectangle serves as the background placeholder
                        .fill(AppTheme.secondaryBackground) // Fills the rectangle with the secondary background color defined in AppTheme
                        .frame(height: 250) // Sets the rectangle's height to 250 points
                        .overlay( // Places the overlay view on top of the rectangle
                            Image(systemName: "photo") // Uses a built-in SF Symbol for a photo icon
                                .font(.system(size: 40))  // Sets the size of the icon to 40 points
                                .foregroundColor(AppTheme.secondaryText)  // Sets the icon color to secondary text color defined in AppTheme
                        )
                }
            }
            
            // Gradient overlay
            LinearGradient(  // Creates a gradient with a smooth transition from black to transparent
                gradient: Gradient(colors: [
                    Color.black.opacity(0.5), // Starting color (black with 50% opacity)
                    Color.black.opacity(0) // Ending color (black with 0% opacity, transparent)
                ]),
                startPoint: .bottom,  // The gradient starts at the bottom of the view
                endPoint: .top  // The gradient ends at the top of the view
            )
            .frame(height: 150) // The height of the gradient overlay is set to 150 points
        }
        .frame(height: 250)  // The overall height of the header section is set to 250 points
    }
    
    // MARK: - Location Info Section UI Component
    private var locationInfoSection: some View {
        VStack(spacing: 16) { // Vertical stack for layout with spacing of 16 points between each item
            
            // Location Name
            Text(locationDetails?.mainAddress ?? "Location") // Display the main address of the location or "Location" if it's nil
                .font(.system(size: 24, weight: .bold)) // Set the font size to 24 points with bold weight
                .foregroundColor(AppTheme.primaryText) // Set the text color using the primary text color defined in AppTheme
                .multilineTextAlignment(.center) // Align the text to the center if it spans multiple lines
                .padding(.horizontal)  // Apply horizontal padding to the text
                .padding(.top, 16) // Apply 16 points of padding to the top of the text
            
            // Address
            if let fullAddress = locationDetails?.fullAddress {  // Check if there's a full address available
                Button(action: { openInMaps() }) { // If there's a full address, create a button to open the location in Maps
                    HStack(spacing: 6) { // Horizontal stack for the address button content
                        Image(systemName: "mappin.circle.fill") // SF symbol for the map pin icon
                            .font(.system(size: 16)) // Set the icon size to 16 points
                        Text(fullAddress)  // Display the full address text
                            .font(.system(size: 14)) // Set the font size to 14 points for the address
                    }
                    .foregroundColor(AppTheme.primaryPurple)  // Set the button text and icon color to the primary purple from AppTheme
                }
                .padding(.horizontal)  // Apply horizontal padding to the button
            }
            
            // Rating and Directions Section
            HStack(spacing: 20) {
                
                // Location Name
                HStack(spacing: 4) { // Horizontal stack for the rating display, with spacing of 4 points
                    Text(String(format: "%.1f", locationDetails?.averageRating ?? 0)) // Display the average rating, formatted to one decimal place
                        .font(.system(size: 16, weight: .semibold))  // Set the font size to 16 points with a semibold weight
                    Image(systemName: "star.fill") // SF symbol for the star icon, representing a filled star
                        .font(.system(size: 14)) // Set the icon size to 14 points
                        .foregroundColor(.yellow) // Set the star color to yellow to represent the rating
                }
                .padding(.horizontal, 12)  // Apply horizontal padding of 12 points
                .padding(.vertical, 6)  // Apply vertical padding of 6 points
                .background(AppTheme.lightPurple) // Set the background color of the rating display to light purple
                .cornerRadius(12) // Apply rounded corners with a radius of 12 points
                
                // Directions Button
                Button(action: { openInMapsWithDirections() }) {  // Create a button for getting directions
                    HStack(spacing: 6) { // Horizontal stack for the directions button content
                        Image(systemName: "car.fill") // SF symbol for the car icon (representing travel/directions)
                        Text("Get Directions")   // Display the "Get Directions" text
                            .font(.system(size: 14, weight: .medium))  // Set the font size to 14 points with medium weight
                    }
                    .padding(.horizontal, 16) // Apply horizontal padding of 16 points
                    .padding(.vertical, 8) // Apply vertical padding of 8 points
                    .background(AppTheme.primaryPurple) // Set the background color of the button to primary purple from AppTheme
                    .foregroundColor(.white) // Set the text and icon color to white
                    .cornerRadius(12) // Apply rounded corners with a radius of 12 points
                }
            }
            .padding(.vertical, 8) // Apply vertical padding of 8 points to the HStack
            
            // MARK: - Divider and Background for the Section
            Divider() // Adds a visual divider line to separate sections
                .padding(.horizontal) // Applies horizontal padding to the divider to ensure spacing on both sides
        }
        // Set background color for the entire container
        .background(AppTheme.background) // Apply the background color defined in the AppTheme
    }
    
    // MARK: - Posts Section UI Component
    private var postsSection: some View {
        VStack(spacing: 16) {  // Vertical stack for arranging components in the posts section with 16 points of spacing
            
            // Section Header
            HStack {
                Text("Posts") // Title for the section, displaying the word "Posts"
                    .font(.system(size: 18, weight: .semibold))  // Set the font size to 18 points with semibold weight
                    .foregroundColor(AppTheme.primaryText)  // Set the text color to primary text color defined in AppTheme
                
                Spacer()  // A spacer to push the post count to the right side of the header
                
                // Display the number of posts in the location
                Text("\(locationPosts.count)") // Display the count of posts dynamically from the locationPosts array
                    .font(.system(size: 14)) // Set the font size to 14 points for the post count
                    .foregroundColor(AppTheme.secondaryText)  // Set the text color to secondary text color from AppTheme
            }
            .padding(.horizontal)  // Apply horizontal padding to the header for consistent spacing
            .padding(.top, 16) // Apply top padding to separate the header from the content
            
            // Posts List: Displays the posts if available or an empty state message if there are no posts.
            if locationPosts.isEmpty {
                emptyPostsView // Shows the empty posts view if there are no posts in the locationPosts array
            } else {
                // LazyVStack to display posts in a vertical stack with dynamic content
                LazyVStack(spacing: 16) { // The LazyVStack lazily loads the posts as they appear on the screen for better performance
                    ForEach(locationPosts) { post in  // Iterates over each post in the locationPosts array
                        PostCard(post: post) // Displays a post card for each post
                            .environmentObject(userManager) // Passes the userManager as an environment object for state management
                            .padding(.horizontal) // Applies horizontal padding to each post card for spacing
                    }
                }
            }
        }
        .padding(.bottom, 20) // Adds padding to the bottom of the entire posts section to ensure proper spacing
    }
    
    // MARK: - Empty Posts View UI Component
    private var emptyPostsView: some View {
        // VStack to vertically arrange the content with a spacing of 12 points between elements
        VStack(spacing: 12) {
            // Displays a photo stack icon to visually represent the absence of posts
            Image(systemName: "photo.stack")
                .font(.system(size: 40))  // Sets the icon size to 40 points for a large, noticeable icon
                .foregroundColor(AppTheme.secondaryText)  // Sets the icon color to the secondary text color from the app's theme
            
            // Text indicating there are no posts available for the location
            Text("No posts yet for this location")
                .font(.system(size: 14)) // Sets the font size to 14 points for a readable, smaller text
                .foregroundColor(AppTheme.secondaryText) // Uses the secondary text color from the app's theme for consistent styling
        }
        // Ensures the empty posts view takes up the full width of the available screen space
        .frame(maxWidth: .infinity)
        // Adds vertical padding of 40 points to ensure the content is vertically centered and spaced appropriately
        .padding(.vertical, 40)
        // Applies the background color defined in AppTheme for a consistent background appearance across the app
        .background(AppTheme.background)
    }

    // MARK: - Fetch Location Details
    private func fetchLocationDetails() {
        // Fetching document from the Firestore database using locationRef
        locationRef.getDocument { snapshot, error in
            // If there is an error fetching the document, print the error and return
            if let error = error {
                print("Error fetching location details: \(error)")
                return
            }
            
            // If the snapshot contains data, parse it
            if let data = snapshot?.data() {
                // Extract the address, coordinates, and average rating from the fetched data
                let address = data["address"] as? String ?? ""
                let coordinates = data["location_coordinates"] as? [Double] ?? []
                let averageRating = data["average_rating"] as? Double ?? 0
                
                // If coordinates are available, reverse geocode to get the full address
                if coordinates.count == 2 {
                    // Create a CLLocation object using the latitude and longitude
                    let location = CLLocation(latitude: coordinates[0], longitude: coordinates[1])
                    let geocoder = CLGeocoder() // Geocoder to perform reverse geocoding
                    
                    // Reverse geocoding to fetch the location's address
                    geocoder.reverseGeocodeLocation(location) { placemarks, error in
                        // If there's an error with reverse geocoding, print the error and return
                        if let error = error {
                            print("Reverse geocoding error: \(error)")
                            return
                        }
                        
                        // If we successfully get placemarks, proceed to extract the details
                        if let placemark = placemarks?.first {
                            // Extract the main address (POI or street name) from the placemark, fallback to the address field if unavailable
                            let mainAddress = placemark.name ?? address
                            
                            // Build the full address from various components (street, city, state, country, etc.)
                            var fullAddressComponents: [String] = []
                            
                            if let streetNumber = placemark.subThoroughfare {
                                fullAddressComponents.append(streetNumber) // Street number (if available)
                            }
                            if let street = placemark.thoroughfare {
                                fullAddressComponents.append(street) // Street name (if available)
                            }
                            if let city = placemark.locality {
                                fullAddressComponents.append(city) // City (if available)
                            }
                            if let state = placemark.administrativeArea {
                                fullAddressComponents.append(state) // State (if available)
                            }
                            if let country = placemark.country {
                                fullAddressComponents.append(country)  // Country (if available)
                            }
                            
                            // Join the components into a single string, separated by commas
                            let fullAddress = fullAddressComponents.joined(separator: ", ")
                            
                            // Update the location details state on the main thread
                            DispatchQueue.main.async {
                                locationDetails = LocationDetails(
                                    mainAddress: mainAddress, // Set the main address
                                    fullAddress: fullAddress,  // Set the full address
                                    averageRating: averageRating // Set the average rating
                                )
                                isLoading = false // Set loading state to false once data is fetched and processed
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Open Location in Maps
    private func openInMaps() {
        // Fetch the location coordinates (latitude and longitude) asynchronously
        fetchLocationCoordinates { coordinates in
            // Ensure that coordinates are available, otherwise return
            guard let coordinates = coordinates else { return }
            
            // Create a CLLocationCoordinate2D object from the fetched coordinates
            let coordinate = CLLocationCoordinate2D(
                latitude: coordinates[0], // Latitude from coordinates
                longitude: coordinates[1] // Longitude from coordinates
            )
            // Create an MKPlacemark using the coordinate
            let placemark = MKPlacemark(coordinate: coordinate)
            // Create an MKMapItem from the placemark
            let mapItem = MKMapItem(placemark: placemark)
            // Set the name of the map item (using the main address of the location)
            mapItem.name = locationDetails?.mainAddress
            // Open the map item in the Maps app
            mapItem.openInMaps(launchOptions: nil) // No special launch options (just open the location)
        }
    }

    // MARK: - Open Location in Maps with Directions
    private func openInMapsWithDirections() {
        // Fetch the location coordinates (latitude and longitude) asynchronously
        fetchLocationCoordinates { coordinates in
            // Ensure that coordinates are available, otherwise return
            guard let coordinates = coordinates else { return }
            
            // Create a CLLocationCoordinate2D object from the fetched coordinates
            let coordinate = CLLocationCoordinate2D(
                latitude: coordinates[0], // Latitude from coordinates
                longitude: coordinates[1] // Longitude from coordinates
            )
            // Create an MKPlacemark using the coordinate
            let placemark = MKPlacemark(coordinate: coordinate)
            // Create an MKMapItem from the placemark
            let mapItem = MKMapItem(placemark: placemark)
            // Set the name of the map item (using the main address of the location)
            mapItem.name = locationDetails?.mainAddress
            
            // Set launch options to request directions in driving mode
            let launchOptions = [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving  // Directions in driving mode
            ]
            // Open the map item in the Maps app with the directions launch options
            mapItem.openInMaps(launchOptions: launchOptions)
        }
    }
    
    private func fetchLocationCoordinates(completion: @escaping ([Double]?) -> Void) {
        // Fetch the document from Firestore
        locationRef.getDocument { snapshot, error in
            // Handle any errors during the document fetch
            if let error = error {
                print("Error fetching location: \(error)")
                completion(nil) // Return nil in case of error
                return
            }
            
            // Extract data from the snapshot if available
            if let data = snapshot?.data(),
               let coordinates = data["location_coordinates"] as? [Double], // Ensure location_coordinates is a valid array of Doubles
               coordinates.count == 2 { // Ensure there are exactly 2 coordinates (latitude, longitude)
                completion(coordinates) // Return the coordinates (latitude and longitude)
            } else {
                completion(nil) // Return nil if no coordinates or invalid data
            }
        }
    }


    
    private func fetchLocationPosts() {
        // Log the start of fetching posts for the specific location
        print("DEBUG: Starting to fetch posts for location: \(locationRef.documentID)")
        // Access the Firestore database instance from FirebaseManager
        let db = FirebaseManager.shared.firestore
        
        // Query the "user_posts" collection, filtering by locationRef to only get posts related to the current location
        // The posts are ordered by "timestamp" in descending order to get the most recent posts first
        db.collection("user_posts")
            .whereField("locationRef", isEqualTo: locationRef) // Filter by location reference
            .order(by: "timestamp", descending: true) // Order by timestamp in descending order
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    // Check for any errors when fetching the snapshot
                    print("DEBUG: Error fetching posts: \(error)")
                    return
                }
                
                // Log the number of document changes received (added, modified, removed)
                print("DEBUG: Received \(querySnapshot?.documentChanges.count ?? 0) post changes")
                
                // Iterate over the document changes received from the snapshot
                querySnapshot?.documentChanges.forEach { change in
                    // Check if the change type is .added (new post added)
                    if change.type == .added {
                        // Get the data for the post and the document ID
                        let data = change.document.data()
                        let postId = change.document.documentID
                        
                        // Handle setting the header image for the first post
                        // Check if the post has image URLs, and if a header image hasn't been set yet
                        if let imageUrls = data["images"] as? [String],
                           !imageUrls.isEmpty, // Ensure there are images available
                           self.headerImageUrl == nil { // Check if a header image has already been set
                            // Set a random image URL as the header image for the location
                            self.headerImageUrl = imageUrls.randomElement()
                            print("DEBUG: Set header image from post: \(postId)")
                        }
                        
                        // Get location details first
                        guard let locationRef = data["locationRef"] as? DocumentReference else {
                            // If the locationRef cannot be extracted from the data dictionary, exit early
                            return
                        }

                        
                        // Fetch location details using the locationRef
                        locationRef.getDocument { locationSnapshot, locationError in
                            // Handle any error that occurs when fetching the location details
                            if let locationError = locationError {
                                print("DEBUG: Error fetching location: \(locationError)")
                                return // Exit early if there's an error fetching the document
                            }
                            
                            // Extract the location data from the fetched snapshot
                            guard let locationData = locationSnapshot?.data(),
                                  let address = locationData["address"] as? String else {
                                // If location data or address is not found, log an error and return
                                print("DEBUG: No location data found")
                                return
                            }
                            
                            // Now fetch user details
                            if let userId = data["uid"] as? String {
                                // Fetch the user document from Firestore using the extracted userId
                                db.collection("users")
                                    .document(userId)
                                    .getDocument { userSnapshot, userError in
                                        // Handle any error that occurs while fetching user details
                                        if let userError = userError {
                                            print("DEBUG: Error fetching user details: \(userError)")
                                            return // Exit early if there's an error fetching the user document
                                        }
                                        
                                        // Extract user data from the snapshot, defaulting to an empty dictionary if not found
                                        let userData = userSnapshot?.data() ?? [:]
                                        
                                        // Extract the username and profile image URL, defaulting to placeholders if not found
                                        let username = userData["username"] as? String ?? "Unknown User"
                                        let userProfileImageUrl = userData["profileImageUrl"] as? String ?? ""
                                        
                                        // Create a new post object using the fetched location and user details
                                        let post = Post(
                                            id: postId,  // Post ID from Firestore document
                                            description: data["description"] as? String ?? "",  // Post description, defaulting to empty string if not found
                                            rating: data["rating"] as? Int ?? 0, // Rating, defaulting to 0 if not found
                                            locationRef: locationRef, // Location reference (Firebase DocumentReference)
                                            locationAddress: address,  // Fetched location address
                                            imageUrls: data["images"] as? [String] ?? [], // Array of image URLs, defaulting to empty array if not found
                                            timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),  // Timestamp of the post
                                            uid: userId, // User ID
                                            username: username,  // Fetched username
                                            userProfileImageUrl: userProfileImageUrl // Fetched user profile image URL
                                        )
                                        
                                        // Update the UI on the main thread with the new post
                                        DispatchQueue.main.async {
                                            // Ensure the post is not already in the list before appending
                                            if !self.locationPosts.contains(where: { $0.id == post.id }) {
                                                self.locationPosts.append(post) // Add the post to the array
                                                self.locationPosts.sort { $0.timestamp > $1.timestamp }  // Sort the posts by timestamp in descending order
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
