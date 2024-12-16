//
//  SuggestionPageViewModel.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

// MARK: - SuggestionPageViewModel

// The `SuggestionPageViewModel` class serves as the ViewModel for a suggestion page.
// It fetches detailed images from the Pixabay API based on a selected city and keeps the UI updated dynamically using Combine.

import Foundation
import Combine

class SuggestionPageViewModel: ObservableObject {
    
    @Published var detailedImages: [PixabayImage] = [] // Holds images to display
    @Published var selectedCity: String // The selected city to update the UI
    private var cancellables: Set<AnyCancellable> = [] // To store Combine cancellables
    private var pixkey = PixabayAPI.shared // The shared instance of PixabayAPI

    // Initializes the ViewModel with a selected city and triggers an image fetch for that city.
    init(city: String) {
        self.selectedCity = city
        fetchDetailedImages(for: city)
    }
    
    // Fetches detailed images from the Pixabay API based on the provided query.
    func fetchDetailedImages(for query: String) {
        // Calls the `searchImages` function on the PixabayAPI instance to perform the API request.
        pixkey.searchImages(query: query)
            .sink(receiveCompletion: { completion in
                // Handle the result of the Combine publisher.
                if case let .failure(error) = completion {
                    // Log any errors encountered during the API request.
                    print("Error fetching detailed images for \(query): \(error)")
                }
            }, receiveValue: { images in
                // On successful data retrieval, update the `detailedImages` property.
                self.detailedImages = images
            })
            .store(in: &cancellables)  // Store the cancellable to manage the subscription lifecycle.
    }
}
