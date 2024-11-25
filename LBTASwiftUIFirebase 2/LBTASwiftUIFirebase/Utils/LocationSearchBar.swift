import SwiftUI
import MapKit
import CoreLocation

struct LocationSearchBar: View {
    @Binding var selectedLocation: String
    @Binding var latitude: Double
    @Binding var longitude: Double
    
    @StateObject private var searchCompleter = LocationSearchCompleter()
    @StateObject private var locationManager = CustomLocationManager()
    @State private var searchText = ""
    @State private var showResults = false
    @State private var showLocationButton = true // State to track button visibility
    
    private let primaryPurple = Color(red: 140/255, green: 82/255, blue: 255/255)
    private let lightPurple = Color(red: 140/255, green: 82/255, blue: 255/255).opacity(0.1)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Search Bar
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.primary) // Changed to black/primary color
                
                TextField("Search location...", text: $searchText)
                    .font(.system(size: 16))
                    .tint(.blue) // Changed to blue for cursor
                    .onChange(of: searchText) { _, newValue in
                        if newValue.isEmpty {
                            showResults = false
                        } else {
                            showResults = true
                            searchCompleter.searchTerm = newValue
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        selectedLocation = ""
                        showResults = false
                        showLocationButton = true
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 18))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            if showLocationButton {
                // Current Location Button - Full width
                Button(action: {
                    fetchCurrentLocation()
                    showLocationButton = false
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "location.circle.fill")
                            .font(.system(size: 16))
                        Text("Use Current Location")
                            .font(.system(size: 14, weight: .medium))
                        Spacer() // Added to make the button full width
                    }
                    .foregroundColor(primaryPurple)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity) // Added to ensure full width
                    .background(lightPurple)
                    .cornerRadius(8)
                }
            }
            
            // Search Results
            if showResults {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(searchCompleter.results, id: \.self) { result in
                            Button(action: { selectSearchResult(result) }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(result.title)
                                        .font(.system(size: 16))
                                        .foregroundColor(.primary)
                                    
                                    if !result.subtitle.isEmpty {
                                        Text(result.subtitle)
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .background(Color(.systemBackground))
                            
                            Divider()
                                .padding(.horizontal, 12)
                        }
                        
                        if searchCompleter.results.isEmpty {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                Text("No results found")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        }
                    }
                }
                .frame(maxHeight: 250)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
        .onChange(of: selectedLocation) { _, newValue in
            if newValue.isEmpty {
                searchText = ""
                showResults = false
            }
        }
    }

    // Fetch current location and update state
    private func fetchCurrentLocation() {
        locationManager.requestLocation() // Start location fetch
        selectedLocation = "Fetching location..."
        searchText = "Fetching location..." // Update UI immediately

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // Allow time for location to update
            if let currentLocation = locationManager.userLocation {
                latitude = currentLocation.latitude
                longitude = currentLocation.longitude

                let geocoder = CLGeocoder()
                let location = CLLocation(latitude: latitude, longitude: longitude)

                // Perform reverse geocoding
                geocoder.reverseGeocodeLocation(location) { placemarks, error in
                    if let error = error {
                        print("Reverse geocoding failed: \(error.localizedDescription)")
                        selectedLocation = "Unable to fetch location"
                        searchText = "Unable to fetch location" // Reflect error
                        return
                    }

                    if let placemark = placemarks?.first {
                        let address = placemark.compactAddress
                        selectedLocation = address
                        searchText = address // Automatically update UI
                    } else {
                        selectedLocation = "Unknown location"
                        searchText = "Unknown location" // Reflect in search bar
                    }
                }
            } else {
                selectedLocation = "Fetching location..."
                searchText = "Fetching location..." // Reflect fetching status
            }
        }
    }

    // Select a location from search results
    private func selectSearchResult(_ result: MKLocalSearchCompletion) {
        searchCompleter.getCoordinates(for: result) { location in
            if let location = location {
                latitude = location.coordinate.latitude
                longitude = location.coordinate.longitude
                let locationText = result.title + (result.subtitle.isEmpty ? "" : ", \(result.subtitle)")
                selectedLocation = locationText
                searchText = locationText
            }
        }
        showResults = false
    }
}

class CustomLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D? = nil
    @Published var locationError: String? = nil

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        locationManager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location.coordinate
        print("Updated location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error.localizedDescription
        print("Location error: \(error.localizedDescription)")
    }
}

class LocationSearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchTerm = "" {
        didSet {
            completer.queryFragment = searchTerm
        }
    }
    
    @Published var results: [MKLocalSearchCompletion] = []
    private let completer: MKLocalSearchCompleter
    
    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }
    
    func getCoordinates(for result: MKLocalSearchCompletion, completion: @escaping (MKPlacemark?) -> Void) {
        let searchRequest = MKLocalSearch.Request(completion: result)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { response, error in
            guard error == nil, let placemark = response?.mapItems.first?.placemark else {
                completion(nil)
                return
            }
            completion(placemark)
        }
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.results = completer.results
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Location search failed with error: \(error.localizedDescription)")
    }
}

extension CLPlacemark {
    var compactAddress: String {
        var result = ""
        if let subThoroughfare = subThoroughfare {
            result += subThoroughfare + " "
        }
        if let thoroughfare = thoroughfare {
            result += thoroughfare + ", "
        }
        if let locality = locality {
            result += locality + ", "
        }
        if let administrativeArea = administrativeArea {
            result += administrativeArea + " "
        }
        if let postalCode = postalCode {
            result += postalCode
        }
        return result.isEmpty ? "Address unavailable" : result
    }
}
