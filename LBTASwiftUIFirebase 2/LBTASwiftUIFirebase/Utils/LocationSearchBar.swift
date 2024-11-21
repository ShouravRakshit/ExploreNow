import SwiftUI
import MapKit
import CoreLocation

struct LocationSearchBar: View {
    @Binding var selectedLocation: String
    @Binding var latitude: Double
    @Binding var longitude: Double
    @Environment(\.presentationMode) var presentationMode // To dismiss the view
    
    @StateObject private var searchCompleter = LocationSearchCompleter()
    @StateObject private var locationManager = CustomLocationManager()
    @State private var searchText = ""
    @State private var showResults = false

    var body: some View {
        VStack(spacing: 120) {
            VStack(spacing: 20) {
                Spacer()
                Text("Select Your Location")
                    .font(.largeTitle)
                    .padding()
                // Search Bar
                HStack(spacing: 20) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 24))
                    TextField("Search location...", text: $searchText)
                        .font(.system(size: 24))
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
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal)
                
                // "Use Current Location" Button
                Button(action: {
                    fetchCurrentLocation()
                }) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("Use Current Location")
                    }
                    .foregroundColor(.primary)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Search Results
                if showResults {
                    ScrollView {
                        VStack(alignment: .leading) {
                            ForEach(searchCompleter.results, id: \.self) { result in
                                Button(action: {
                                    selectSearchResult(result)
                                }) {
                                    VStack(alignment: .leading) {
                                        Text(result.title)
                                            .foregroundColor(.primary)
                                        if !result.subtitle.isEmpty {
                                            Text(result.subtitle)
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                                Divider()
                            }
                            
                            if searchCompleter.results.isEmpty {
                                Text("No results found.")
                                    .foregroundColor(.gray)
                                    .padding(.vertical, 8)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
            }
            .onChange(of: selectedLocation) { _, newValue in
                if newValue.isEmpty {
                    searchText = ""
                    showResults = false
                }
            }
            
            Spacer()
            
            Button(action: {
                presentationMode.wrappedValue.dismiss() // Close the pop-up
            }) {
                Text("Done")
                    .font(.title2)
                    .frame(width: 200)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            Spacer()
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


