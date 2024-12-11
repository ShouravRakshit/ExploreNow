//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

import SwiftUI
import MapKit
import CoreLocation

// MARK: - LocationSearchBar View
/// A view representing a location search bar that allows users to search for locations,
/// view suggestions, and select a location for further use.
struct LocationSearchBar: View {
    // MARK: - State & Bindings
    @Binding var selectedLocation: String // Binding to the selected location string.
    @Binding var latitude: Double  // Binding to the latitude of the selected location.
    @Binding var longitude: Double  // Binding to the longitude of the selected location.
    
    // MARK: - State Properties
    @StateObject private var searchCompleter = LocationSearchCompleter()  // Handles location search and completion.
    @StateObject private var locationManager = CustomLocationManager() // Custom location manager for getting current location.
    @State private var searchText = "" // Holds the text input by the user for location search.
    @State private var showResults = false // Flag to control whether search results are displayed.
    @State private var showLocationButton = true // Controls the visibility of a location button.
    
    // MARK: - Custom Colors
    private let primaryPurple = Color(red: 140/255, green: 82/255, blue: 255/255) // Custom purple color for the search bar.
    private let lightPurple = Color(red: 140/255, green: 82/255, blue: 255/255).opacity(0.1)
    // Light purple for background or accents.
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // MARK: - Search Bar UI
            HStack(spacing: 12) {
                // Location icon inside the search bar
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.primary) // Uses system's primary color (black or dark mode)
                
                // TextField for user input
                TextField("Search location...", text: $searchText)
                    .font(.system(size: 16))
                    .tint(.blue)  // Blue tint for cursor color.
                    .onChange(of: searchText) { _, newValue in
                        // Handle text changes in the search field
                        if newValue.isEmpty {
                            showResults = false // Hide results if the text field is cleared.
                        } else {
                            showResults = true // Show results when user starts typing.
                            searchCompleter.searchTerm = newValue // Pass the search term to the completer.
                        }
                    }
                
                // Clear button appears when the search text is not empty
                if !searchText.isEmpty {
                    Button(action: {
                        // Reset the search field when clear button is tapped
                        searchText = ""
                        selectedLocation = ""
                        showResults = false
                        showLocationButton = true
                    }) {
                        // X mark icon for clearing the text field
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray) // Gray color for the clear button.
                            .font(.system(size: 18)) // Set size of the icon.
                    }
                }
            }
            .padding(.horizontal, 12) // Horizontal padding for search bar.
            .padding(.vertical, 10) // Vertical padding for search bar.
            .background(Color(.systemGray6)) // Light gray background color for the search bar.
            .cornerRadius(12)   // Rounded corners for the search bar.
            
            if showLocationButton {
                // Current Location Button - Full width
                Button(action: {
                    // Action to fetch the current location when the button is tapped
                    fetchCurrentLocation()
                    // Hides the button after it's tapped to prevent multiple actions
                    showLocationButton = false
                }) {
                    // MARK: - Button Content (HStack)
                    HStack(spacing: 8) {
                        // Location icon
                        Image(systemName: "location.circle.fill")
                            .font(.system(size: 16)) // Sets the font size of the location icon
                        // Label for the button text
                        Text("Use Current Location")
                            .font(.system(size: 14, weight: .medium)) // Sets the font size and weight of the label text
                        Spacer() // Adds flexible space to ensure the button spans the full width
                    }
                    .foregroundColor(primaryPurple) // Sets the text and icon color to the custom primary purple color
                    .padding(.horizontal, 12) // Horizontal padding around the button content
                    .padding(.vertical, 8)  // Vertical padding around the button content
                    .frame(maxWidth: .infinity) // Ensures the button takes up the full available width
                    .background(lightPurple) // Background color of the button (light purple)
                    .cornerRadius(8) // Rounds the corners of the button to make it visually softer
                }
            }
            
            // MARK: - Search Results Display

            // This block of code handles the display of search results when the `showResults` flag is `true`.
            // It uses a ScrollView to present a list of search results returned by the MKLocalSearchCompleter.
            if showResults {
                // Stack to arrange search results vertically.
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Iterate over the search results from the completer.
                        ForEach(searchCompleter.results, id: \.self) { result in
                            // Button to select a search result when clicked.
                            Button(action: { selectSearchResult(result) }) {
                                // Stack to present the title and subtitle of the search result.
                                VStack(alignment: .leading, spacing: 4) {
                                    // Display the title of the search result.
                                    Text(result.title)
                                        .font(.system(size: 16))
                                        .foregroundColor(.primary) // Title text color is primary (default black).
                                    
                                    // Display the subtitle, if it exists.
                                    if !result.subtitle.isEmpty {
                                        Text(result.subtitle)
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)  // Subtitle text color is gray.
                                    }
                                }
                                .padding(.vertical, 12) // Vertical padding for spacing.
                                .padding(.horizontal, 12)  // Horizontal padding for spacing.
                                .frame(maxWidth: .infinity, alignment: .leading) // Make button full width.
                                .contentShape(Rectangle())  // Makes the entire button area tappable.
                            }
                            .background(Color(.systemBackground)) // Background color is system background color (usually white).
                            
                            // Add a divider between results.
                            Divider()
                                .padding(.horizontal, 12) // Padding for divider.
                        }
                        
                        // Handle case when no results are found.
                        if searchCompleter.results.isEmpty {
                            HStack {
                                // Icon for search (magnifying glass).
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                // Text to indicate no results were found.
                                Text("No results found")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray) // Gray text color for "No results found".
                            }
                            .frame(maxWidth: .infinity) // Ensure the message spans the entire width.
                            .padding(.vertical, 20) // Vertical padding for spacing.
                        }
                    }
                }
                .frame(maxHeight: 250) // Limit the maximum height of the results view.
                .background(Color(.systemBackground))  // Background color for the ScrollView.
                .cornerRadius(12)  // Rounded corners for the results view.
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2) // Shadow effect for depth.
            }
        }
        // MARK: - Search Reset Handling

        // Monitor changes to the `selectedLocation` property. If it's cleared (empty string),
        // reset the search text and hide the results.
        .onChange(of: selectedLocation) { _, newValue in
            if newValue.isEmpty {
                searchText = "" // Clear the search text field.
                showResults = false // Hide the search results when location is cleared.
            }
        }
    }

    // MARK: - Fetch Current Location and Update State

    // This method fetches the current location of the user and updates the UI accordingly.
    // It uses the `CLLocationManager` to get the current location, performs reverse geocoding to
    // retrieve the address, and updates the `selectedLocation` and `searchText` states.

    private func fetchCurrentLocation() {
        // Start the location fetch process by requesting the current location from the location manager.
        locationManager.requestLocation()
        // Update the UI immediately to reflect that the location is being fetched.
        selectedLocation = "Fetching location..."
        searchText = "Fetching location..." // Update UI immediately

        // Delay the UI update by 0.1 seconds to allow the location manager some time to update the location.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // Allow time for location to update
            // Check if the location manager successfully retrieved the current location.
            if let currentLocation = locationManager.userLocation {
                latitude = currentLocation.latitude // Store the latitude of the current location.
                longitude = currentLocation.longitude // Store the longitude of the current location.

                // Create a geocoder to perform reverse geocoding based on the current coordinates.
                let geocoder = CLGeocoder()
                let location = CLLocation(latitude: latitude, longitude: longitude)

                // Perform reverse geocoding to fetch the address from the coordinates.
                geocoder.reverseGeocodeLocation(location) { placemarks, error in
                    // Handle error if reverse geocoding fails.
                    if let error = error {
                        print("Reverse geocoding failed: \(error.localizedDescription)")
                        selectedLocation = "Unable to fetch location" // Update the location UI with error message.
                        searchText = "Unable to fetch location" // Update the search bar with error message.
                        return
                    }

                    
                    // If geocoding is successful, update the location UI with the fetched address.
                    if let placemark = placemarks?.first {
                        let address = placemark.compactAddress // Get the formatted address from the placemark.
                        selectedLocation = address // Update the selected location with the address.
                        searchText = address // Update the search bar with the address.
                    } else {
                        // If no placemark is found, set location as "Unknown location".
                        selectedLocation = "Unknown location"
                        searchText = "Unknown location" // Reflect this in the search bar as well.
                    }
                }
            } else {
                // If location is not available, show the status "Fetching location..." again.
                selectedLocation = "Fetching location..."
                searchText = "Fetching location..." // Reflect fetching status in the search bar.
            }
        }
    }

    // MARK: - selectSearchResult Method

    // This method is responsible for handling the selection of a search result
    // from the MKLocalSearchCompleter's search results. It fetches the coordinates
    // of the selected location and updates the state variables accordingly.
    
    private func selectSearchResult(_ result: MKLocalSearchCompletion) {
        // Call the 'getCoordinates' method from the LocationSearchCompleter to fetch
        // the coordinates of the selected location.
        searchCompleter.getCoordinates(for: result) { location in
            // If the location is successfully fetched (non-nil), update the latitude,
            // longitude, selected location text, and the search text.
            if let location = location {
                // Update the latitude and longitude of the selected location.
                latitude = location.coordinate.latitude
                longitude = location.coordinate.longitude
                // Create a formatted string for the location text (e.g., "City, Country").
                let locationText = result.title + (result.subtitle.isEmpty ? "" : ", \(result.subtitle)")
                // Set the selected location text to the formatted location string.
                selectedLocation = locationText
                // Set the search text to the same location text to reflect the user's selection.
                searchText = locationText
            }
        }
        // Hide the search results once a result has been selected.
        showResults = false
    }
}

// MARK: - CustomLocationManager Class
class CustomLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    // CLLocationManager is the system class responsible for managing location services
    private let locationManager = CLLocationManager()
    // Published property to store the user's location (coordinates)
    @Published var userLocation: CLLocationCoordinate2D? = nil
    // Published property to store any location errors (if any occur)
    @Published var locationError: String? = nil

    // MARK: - Initializer
    override init() {
        super.init()
        // Set the delegate of the location manager to self, so this class can handle updates
        locationManager.delegate = self
        // Set the desired accuracy for location updates to the best available accuracy
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // Request authorization to access the user's location while the app is in use
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - Location Request Method
       
    // Method to trigger a location request from the CLLocationManager
    func requestLocation() {
        // Request a one-time location update
        locationManager.requestLocation()
    }

    // MARK: - CLLocationManagerDelegate Methods
        
    // Delegate method called when the location manager successfully updates the user's location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Ensure that there is at least one location update in the list
        guard let location = locations.last else { return }
        userLocation = location.coordinate
        print("Updated location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error.localizedDescription
        print("Location error: \(error.localizedDescription)")
    }
}

// MARK: - LocationSearchCompleter Class
class LocationSearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    // Published property that triggers UI updates when the search term is modified
    @Published var searchTerm = "" {
        didSet {
            // Update the completer's query fragment whenever the search term changes
            completer.queryFragment = searchTerm
        }
    }
    // Published property to store the results of the search, which will be displayed in the UI
    @Published var results: [MKLocalSearchCompletion] = []
    // MKLocalSearchCompleter is responsible for performing the actual search based on the query
    private let completer: MKLocalSearchCompleter
    
    // MARK: - Initializer
    override init() {
        completer = MKLocalSearchCompleter() // Initialize the MKLocalSearchCompleter
        super.init()
        // Set the delegate to self so that the class can handle search results and errors
        completer.delegate = self
        // Specify the type of search results that we want (addresses in this case)
        completer.resultTypes = .address
    }
    
    // MARK: - Get Coordinates Method
       
    // Method that retrieves the coordinates (MKPlacemark) of a search result
    func getCoordinates(for result: MKLocalSearchCompletion, completion: @escaping (MKPlacemark?) -> Void) {
        // Create a search request using the selected search result
        let searchRequest = MKLocalSearch.Request(completion: result)
        // Perform the search using the search request
        let search = MKLocalSearch(request: searchRequest)
        // Start the search asynchronously
        search.start { response, error in
            // Check if there was an error during the search or if the response was empty
            guard error == nil, let placemark = response?.mapItems.first?.placemark else {
                // If no result or error occurred, return nil
                completion(nil)
                return
            }
            // If successful, pass the placemark (coordinates and other location details) to the completion handler
            completion(placemark)
        }
    }
    
    // MARK: - Completer Did Update Results
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Update the results on the main thread to ensure UI updates happen on the main thread
        DispatchQueue.main.async {
            self.results = completer.results // Assign the search results to the class's results property
        }
    }
    
    // MARK: - Completer Did Fail with Error
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Print out the error message if the search fails
        print("Location search failed with error: \(error.localizedDescription)")
    }
}

// MARK: - CLPlacemark Extension for Compact Address
extension CLPlacemark {
    // Computed property to return a compact address string by combining available address components
    var compactAddress: String {
        var result = ""
        // Append subThoroughfare (street number) if available
        if let subThoroughfare = subThoroughfare {
            result += subThoroughfare + " "
        }
        // Append thoroughfare (street name) if available
        if let thoroughfare = thoroughfare {
            result += thoroughfare + ", "
        }
        // Append locality (city) if available
        if let locality = locality {
            result += locality + ", "
        }
        // Append administrativeArea (state or province) if available
        if let administrativeArea = administrativeArea {
            result += administrativeArea + " "
        }
        // Append postalCode if available
        if let postalCode = postalCode {
            result += postalCode
        }
        // If no address components are available, return "Address unavailable"
        return result.isEmpty ? "Address unavailable" : result
    }
}

