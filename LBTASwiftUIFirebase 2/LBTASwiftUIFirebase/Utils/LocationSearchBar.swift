//
//  LocationSearchBar.swift
//  LBTASwiftUIFirebase
//
//  Created by Saadman Rahman on 2024-11-05.
//


import SwiftUI
import MapKit
import CoreLocation

struct LocationSearchBar: View {
    @Binding var selectedLocation: String
    @Binding var latitude: Double
    @Binding var longitude: Double
    @StateObject private var searchCompleter = LocationSearchCompleter()
    @State private var searchText = ""
    @State private var showResults = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 20))
                TextField("Search location...", text: $searchText)
                    .onChange(of: searchText) { oldValue, newValue in
                        if !selectedLocation.isEmpty && searchText.isEmpty {
                            // Keep showing the selected location if the search field is cleared
                            searchText = selectedLocation
                        } else {
                            showResults = !newValue.isEmpty
                            searchCompleter.searchTerm = newValue
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        showResults = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.vertical, 8)
            
            if showResults {
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(searchCompleter.results, id: \.self) { result in
                            Button(action: {
                                searchCompleter.getCoordinates(for: result) { location in
                                    if let location = location {
                                        // Store raw coordinate values
                                        latitude = location.coordinate.latitude
                                        longitude = location.coordinate.longitude
                                        
                                        // Update location display
                                        let locationText = result.title + (result.subtitle.isEmpty ? "" : ", \(result.subtitle)")
                                        selectedLocation = locationText
                                        searchText = locationText
                                    }
                                }
                                showResults = false
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
                    }
                }
                .frame(maxHeight: 200)
            }
        }
        .padding(.horizontal)
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
        completer.resultTypes = .pointOfInterest
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
