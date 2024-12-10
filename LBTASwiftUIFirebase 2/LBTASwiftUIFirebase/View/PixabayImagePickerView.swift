//
//  PixabayImagePickerView.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

import SwiftUI
import SDWebImageSwiftUI
import Combine

// A SwiftUI View for selecting images from Pixabay.
// Supports single and multiple image selection.
struct PixabayImagePickerView: View {
    // Environment variable to control the view's presentation state
    @Environment(\.presentationMode) var presentationMode
    
    // ViewModel instance to manage state and business logic
    @StateObject private var viewModel = PixabayImagePickerViewModel()
    
    // Indicates whether multiple image selection is allowed
    var allowsMultipleSelection: Bool
    
    // Closure to handle the selected images
    var onImagesSelected: ([PixabayImage]) -> Void

    var body: some View {
        NavigationView {
            VStack {
                // Search bar for querying images
                searchBar
                
                // Show a loading indicator if images are being fetched
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .padding()
                }
                // Show a message if no images are found
                else if viewModel.images.isEmpty {
                    Text("No images found.")
                        .foregroundColor(.gray)
                        .padding()
                    Spacer()
                }
                // Display the fetched images in a grid format
                else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                            ForEach(viewModel.images) { image in
                                Button(action: {
                                    imageTapped(image)
                                }) {
                                    ZStack {
                                        // Display image preview
                                        if let urlString = image.previewURL, let url = URL(string: urlString) {
                                            WebImage(url: url)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .clipped()
                                                .cornerRadius(8)
                                                .overlay(
                                                    // Highlight selected images with a blue border
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(viewModel.selectedImages.contains(where: { $0.id == image.id }) ? Color.blue : Color.clear, lineWidth: 4)
                                                )
                                                .opacity(viewModel.selectedImages.contains(where: { $0.id == image.id }) ? 0.7 : 1.0)
                                                .overlay(
                                                    // Add a checkmark overlay for selected images
                                                    viewModel.selectedImages.contains(where: { $0.id == image.id }) ?
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .foregroundColor(.blue)
                                                            .font(.system(size: 24))
                                                            .padding(4)
                                                        : nil,
                                                    alignment: .topTrailing
                                                )
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            // Navigation bar configuration
            .navigationBarTitle("Select Images", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: allowsMultipleSelection ? Button("Add") {
                    // Pass the selected images to the parent view
                    onImagesSelected(viewModel.selectedImages)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(viewModel.selectedImages.isEmpty)
                : nil
            )
        }
        // Fetch popular images when the view appears
        .onAppear {
            viewModel.fetchImages(query: "popular")
        }
    }

    // Search bar view for querying images
    private var searchBar: some View {
        HStack {
            TextField("Search images...", text: $viewModel.searchQuery, onCommit: {
                // Fetch images based on the search query
                viewModel.fetchImages(query: viewModel.searchQuery)
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal)
            if viewModel.isLoading {
                ProgressView()
                    .padding(.trailing)
            }
        }
    }

    // Handles the image tap action
    // - Parameter image: The image that was tapped
    private func imageTapped(_ image: PixabayImage) {
        if allowsMultipleSelection {
            // Toggle selection for multiple image mode
            viewModel.toggleSelection(for: image)
        } else {
            // Immediately select the image and dismiss the view
            onImagesSelected([image])
            presentationMode.wrappedValue.dismiss()
        }
    }
}
