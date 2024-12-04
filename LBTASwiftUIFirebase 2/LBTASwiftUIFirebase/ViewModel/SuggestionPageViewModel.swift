//
//  SuggestionPageViewModel.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 04/12/2024.
//

import Foundation
import Combine

class SuggestionPageViewModel: ObservableObject {
    @Published var detailedImages: [PixabayImage] = [] // Holds images to display
    @Published var selectedCity: String // The selected city to update the UI
    private var cancellables: Set<AnyCancellable> = [] // To store Combine cancellables
    private var pixkey = PixabayAPI.shared // The shared instance of PixabayAPI

    init(city: String) {
        self.selectedCity = city
        fetchDetailedImages(for: city)
    }
    
    // Fetch detailed images based on the selected city
    func fetchDetailedImages(for query: String) {
        pixkey.searchImages(query: query)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error fetching detailed images for \(query): \(error)")
                }
            }, receiveValue: { images in
                self.detailedImages = images
            })
            .store(in: &cancellables) // Store the cancellable to manage the subscription lifecycle
    }
}
