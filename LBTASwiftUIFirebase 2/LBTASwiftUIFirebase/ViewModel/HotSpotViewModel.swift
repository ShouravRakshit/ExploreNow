//
//  HotSpotViewModel.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 04/12/2024.
//

import Foundation
import Combine

class HotspotsViewModel: ObservableObject {
    @Published var displayedSuggestions: [(String, String)] = []
    @Published var images: [String: String] = [:] // Store images for each place
    @Published var selectedCity: String? = nil // Store the selected city dynamically
    
    private var cancellables: Set<AnyCancellable> = [] // Store cancellables for Combine
    private var pixkey = PixabayAPI.shared // Use the shared instance of PixabayAPI
    
    // List of trending locations
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

    // Fetch images for the suggestions using PixabayAPI
    func fetchImagesForSuggestions() {
        for suggestion in suggestions {
            pixkey.searchImages(query: suggestion.0)
                .sink(receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        print("Error fetching images for \(suggestion.0): \(error)")
                    }
                }, receiveValue: { images in
                    if let firstImageURL = images.first?.webformatURL {
                        self.images[suggestion.0] = firstImageURL // Store the first image URL for each suggestion
                    }
                })
                .store(in: &cancellables) // Store the cancellable
        }
    }
}
