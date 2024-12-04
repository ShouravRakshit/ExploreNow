//
//  SuggestionPageViewModel.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 04/12/2024.
//

import Foundation
import Combine

class SuggestionPageViewModel: ObservableObject {
    @Published var detailedImages: [PixabayImage] = []
    private var cancellables: Set<AnyCancellable> = [] // Store cancellables
    
    private let pixabayAPI = PixabayAPI.shared

    func fetchDetailedImages(for query: String) {
        pixabayAPI.searchImages(query: query)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error: \(error)")
                }
            }, receiveValue: { images in
                self.detailedImages = images
            })
            .store(in: &cancellables)
    }
}
