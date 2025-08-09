//
//  AddPhotos.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, ------------, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

import SwiftUI
import PhotosUI

// A SwiftUI wrapper for PHPickerViewController to allow users to select multiple images.
struct AddPhotos: UIViewControllerRepresentable {
    // Binding to hold the selected images.
    @Binding var images: [UIImage] // Now using an array to support multiple images

    // Create a coordinator instance to handle delegation.
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    // Coordinator to handle PHPickerViewController delegation.
    class Coordinator: NSObject, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
        // Reference to the parent AddPhotos view.
        let parent: AddPhotos

        // Initialize the coordinator with a reference to the parent.
        init(parent: AddPhotos) {
            self.parent = parent
        }

        // Handles the user's selection of photos.
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // Dismiss the picker view.
            picker.dismiss(animated: true)

            var pickedImages: [UIImage] = []    // Temporary array to store selected images.

            // Loop through the selected results.
            for result in results {
                // Check if the item can be loaded as a UIImage
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    // Load the image object.
                    result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                        if let image = object as? UIImage {
                            pickedImages.append(image)    // Append the loaded image to the array.
                        }

                        // Update the images binding on the main thread
                        DispatchQueue.main.async {
                            self.parent.images = pickedImages
                        }
                    }
                }
            }
        }
    }

    // Create and configure the PHPickerViewController.
    func makeUIViewController(context: Context) -> PHPickerViewController {
        // Configure the PHPickerViewController for multiple image selection
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 0 // 0 for unlimited selection
        configuration.filter = .images

        // Initialize the picker with the configuration and set its delegate.
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    // Update the PHPickerViewController when the SwiftUI view's state changes.
    // This implementation is empty as there are no updates required for this view.
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No updates required
    }
}
