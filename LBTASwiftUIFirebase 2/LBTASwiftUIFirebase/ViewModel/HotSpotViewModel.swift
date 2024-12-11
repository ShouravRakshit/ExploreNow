//
//  HotSpotViewModel.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

import Foundation
import Combine

// MARK: - HotspotsViewModel
// ViewModel to manage trending hotspot data, including location suggestions and associated images.

class HotspotsViewModel: ObservableObject {
    // MARK: - Published Properties
        
    // List of suggestions to be displayed in the UI with their corresponding details.
    @Published var displayedSuggestions: [(String, String)] = []
    // Dictionary to store image URLs for each location.
    // The keys are location names, and the values are URLs for the first image retrieved from the Pixabay API.
    @Published var images: [String: String] = [:]
    
    // The currently selected city, allowing dynamic updates to the UI when a city is selected.
    @Published var selectedCity: String? = nil
    
    // MARK: - Private Properties
       
    // A set of Combine cancellables to manage subscriptions and prevent memory leaks.
    private var cancellables: Set<AnyCancellable> = []
    // Shared instance of PixabayAPI used for fetching images.
    private var pixkey = PixabayAPI.shared
    
    // MARK: - Static Suggestions
        
    // A predefined list of trending locations, each represented by a tuple containing a search query (for the API)
    // and a display name.
    let suggestions = [
        ("Jasper", "Jasper, Canada"),
        ("Banff", "Banff, Canada"),
        ("Korea", "Seoul, Korea"),
        ("Paris", "Paris, France"),
        ("Drumheller", "Drumheller, Canada"),
        ("Canmore", "Canmore, Canada"),
        ("Toronto", "Toronto, Canada"),
        ("Calgary", "Calgary, Canada"),
        ("Japan", "Kyoto, Japan"),
        ("Italy", "Venice, Italy")
    ]

    // MARK: - Fetch Images for Suggestions
        
    // Fetches images for each suggestion using the PixabayAPI and updates the `images` dictionary.
    func fetchImagesForSuggestions() {
        // Iterate through each suggestion in the list.
        for suggestion in suggestions {
            // Perform an API call to fetch images for the current suggestion.
            pixkey.searchImages(query: suggestion.0)
                .sink(receiveCompletion: { completion in
                    // Handle API call completion.
                    if case let .failure(error) = completion {
                        // Log an error message if the API call fails.
                        print("Error fetching images for \(suggestion.0): \(error)")
                    }
                }, receiveValue: { images in
                    // On success, check if there's at least one image returned.
                    if let firstImageURL = images.first?.webformatURL {
                        // Store the first image URL for the current suggestion in the `images` dictionary.
                        self.images[suggestion.0] = firstImageURL
                    }
                })
                .store(in: &cancellables) // Store the cancellable to manage the subscription's lifecycle.
        }
    }
}
