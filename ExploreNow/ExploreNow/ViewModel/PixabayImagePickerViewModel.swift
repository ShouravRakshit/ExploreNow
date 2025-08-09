//
//  PixabayImagePickerViewModel.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, --------, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

import Foundation
import Combine

// ViewModel for managing state and business logic of the Pixabay Image Picker view.
class PixabayImagePickerViewModel: ObservableObject {
    @Published var images: [PixabayImage] = [] // List of images fetched from Pixabay
    @Published var selectedImages: [PixabayImage] = [] // Images selected by the user
    @Published var isLoading: Bool = false // Indicates whether images are being loaded
    @Published var searchQuery: String = "" // Current search query entered by the user

    // Property to manage the Combine subscription
    private var cancellable: AnyCancellable?

    // Fetches images from the Pixabay API based on the search query.
    func fetchImages(query: String) {
        isLoading = true // Set loading state to true
        images = [] // Clear existing images
        selectedImages = [] // Reset selection when a new search occurs
        
        // Subscribe to the Pixabay API call and handle its response
        cancellable = PixabayAPI.shared.searchImages(query: query)
            .sink(receiveCompletion: { completion in
                self.isLoading = false // Set loading state to false
                // Handle errors if the API call fails
                if case let .failure(error) = completion {
                    print("Error fetching images: \(error.localizedDescription)")
                }
            }, receiveValue: { images in
                // Update the images property with the fetched results
                self.images = images
            })
    }

    // Toggles the selection state of an image.
    func toggleSelection(for image: PixabayImage) {
        // Check if the image is already selected
        if let index = selectedImages.firstIndex(where: { $0.id == image.id }) {
            // If selected, remove it from the selectedImages array
            selectedImages.remove(at: index)
        } else {
            // If not selected, add it to the selectedImages array
            selectedImages.append(image)
        }
    }

    // Resets the selection of images.
    func resetSelection() {
        selectedImages = [] // Clear all selected images
    }
}
