//
//  AddPhotos.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

import SwiftUI
import PhotosUI

// A SwiftUI wrapper for PHPickerViewController to allow users to select multiple images.
struct AddPhotos: UIViewControllerRepresentable {
    // Binding to hold the selected images.
    @Binding var images: [UIImage] // Now using an array to support multiple images

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    // Coordinator to handle PHPickerViewController delegation.
    class Coordinator: NSObject, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
        let parent: AddPhotos

        init(parent: AddPhotos) {
            self.parent = parent
        }

        // Handles the user's selection of photos.
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            var pickedImages: [UIImage] = []

            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                        if let image = object as? UIImage {
                            pickedImages.append(image)
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

    func makeUIViewController(context: Context) -> PHPickerViewController {
        // Configure the PHPickerViewController for multiple image selection
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 0 // 0 for unlimited selection
        configuration.filter = .images
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No updates required
    }
}
