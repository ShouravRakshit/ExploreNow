//
//  HotspotsViewModel.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 04/12/2024.
//

import Foundation
import Combine

class HotspotsViewModel: ObservableObject {
    @Published var images: [String: String] = [:] // Store images for each place
    @Published var selectedCity: String? = nil // Store the selected city dynamically
    private var cancellables: Set<AnyCancellable> = [] // Store cancellables
    
    private let pixabayAPI = PixabayAPI.shared

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

    func fetchImagesForSuggestions() {
        for suggestion in suggestions {
            let query = suggestion.0 // Use the city name directly as the query
            pixabayAPI.searchImages(query: query)
                .sink(receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        print("Error: \(error)")
                    }
                }, receiveValue: { images in
                    if let firstImage = images.first {
                        self.images[suggestion.0] = firstImage.webformatURL
                    }
                })
                .store(in: &cancellables)
        }
    }
}
