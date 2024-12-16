//
//  PixabayImagePickerView.swift
//  ExploreNow
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
               
                searchBar  // Displays the search bar UI for user input
                
                // Show a loading indicator if images are being fetched
                if viewModel.isLoading {
                    ProgressView("Loading...")  // A loading spinner displayed during image fetch
                        .padding()  // Adds padding around the progress view
                }
                // Show a message if no images are found
                else if viewModel.images.isEmpty {
                    Text("No images found.")  // Message displayed when no images are available
                        .foregroundColor(.gray) // Sets the text color to gray
                        .padding() // Adds padding around the text
                    Spacer() // Pushes content upwards, creating space below the message
                }
                // Display the fetched images in a grid format
                else {
                    ScrollView { // A scrollable view to allow vertical scrolling of images
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) { // A grid layout with adaptive column sizes, minimum width of 100, and 10 points of spacing
                            ForEach(viewModel.images) { image in  // Iterates through the fetched images
                                Button(action: { // Action for when an image is tapped
                                    imageTapped(image) // Calls the imageTapped function with the tapped image
                                }) {
                                    ZStack { // A stack that layers its children on top of each other
                                        // Display image preview
                                        if let urlString = image.previewURL, let url = URL(string: urlString) { // Checks if preview URL exists and is valid
                                            WebImage(url: url) // Displays the image from the URL
                                                .resizable()  // Makes the image resizable
                                                .scaledToFill() // Scales the image to fill the frame, potentially cropping
                                                .frame(width: 100, height: 100) // Sets the image frame to 100x100
                                                .clipped()   // Clips the image to ensure it fits the frame
                                                .cornerRadius(8) // Rounds the corners of the image
                                                .overlay(
                                                    // Adds an overlay for additional UI effects
                                                    // Highlight selected images with a blue border
                                                    RoundedRectangle(cornerRadius: 8) // Creates a rounded rectangle overlay
                                                        .stroke(viewModel.selectedImages.contains(where: { $0.id == image.id }) ? Color.blue : Color.clear, lineWidth: 4) // Applies a blue border if the image is selected, otherwise clear
                                                )
                                                .opacity(viewModel.selectedImages.contains(where: { $0.id == image.id }) ? 0.7 : 1.0) // Adjusts opacity for selected images, making them semi-transparent (0.7) when selected, or fully opaque (1.0) when not selected
                                                .overlay(
                                                    // Adds an overlay for selected images
                                                    // Add a checkmark overlay for selected images
                                                    viewModel.selectedImages.contains(where: { $0.id == image.id }) ?  // Checks if the image is selected by matching its ID
                                                        Image(systemName: "checkmark.circle.fill") // Displays a checkmark circle icon
                                                            .foregroundColor(.blue)  // Sets the checkmark color to blue
                                                            .font(.system(size: 24)) // Adjusts the font size of the checkmark icon
                                                            .padding(4) // Adds padding around the checkmark
                                                        : nil,  // If the image is not selected, no overlay is applied
                                                    alignment: .topTrailing // Positions the checkmark in the top-right corner
                                                )
                                        }
                                    }
                                }
                            }
                        }
                        .padding() // Adds padding around the entire VStack, ensuring elements don't touch the edges of the screen
                    }
                }
            }
            // Navigation bar configuration
            .navigationBarTitle("Select Images", displayMode: .inline)  // Sets the title of the navigation bar to "Select Images" with an inline display style
            .navigationBarItems( // Configures the items in the navigation bar
                leading: Button("Cancel") {  // Adds a "Cancel" button on the left side
                    presentationMode.wrappedValue.dismiss()  // Dismisses the current view when "Cancel" is pressed
                },
                trailing: allowsMultipleSelection ? Button("Add") { // Adds an "Add" button on the right side only if multiple selection is allowed
                    // Pass the selected images to the parent view
                    onImagesSelected(viewModel.selectedImages)  // Sends the selected images to the parent view when "Add" is pressed
                    presentationMode.wrappedValue.dismiss() // Dismisses the current view after selecting images
                }
                .disabled(viewModel.selectedImages.isEmpty)  // Disables the "Add" button if no images are selected
                : nil // If multiple selection is not allowed, the "Add" button is not shown
            )
        }
        // Fetch popular images when the view appears
        .onAppear {
            viewModel.fetchImages(query: "popular") // Fetches popular images from the view model when the view first appears
        }
    }

    // Search bar view for querying images
    private var searchBar: some View {
        HStack {  // Horizontal stack to arrange the search field and progress indicator side by side
            TextField("Search images...", text: $viewModel.searchQuery, onCommit: {  // TextField for entering the search query
                // Fetch images based on the search query
                viewModel.fetchImages(query: viewModel.searchQuery) // Calls the view model's fetchImages function when the user presses 'Return'
            })
            .textFieldStyle(RoundedBorderTextFieldStyle()) // Applies a rounded border style to the text field
            .padding(.horizontal) // Adds horizontal padding around the text field for spacing
            if viewModel.isLoading {  // Conditionally shows a progress indicator when images are being fetched
                ProgressView() // Displays a spinning progress indicator
                    .padding(.trailing) // Adds trailing padding to ensure the indicator doesn't touch the edge of the screen
            }
        }
    }

    // Handles the image tap action
    // - Parameter image: The image that was tapped
    private func imageTapped(_ image: PixabayImage) {
        if allowsMultipleSelection {  // Checks if multiple image selection is allowed
            // Toggle selection for multiple image mode
            viewModel.toggleSelection(for: image)  // Calls the toggleSelection function on the view model to toggle the image's selection status
        } else {
            // Immediately select the image and dismiss the view
            onImagesSelected([image])  // Passes the selected image to the parent view through the onImagesSelected callback
            presentationMode.wrappedValue.dismiss() // Dismisses the current view after selecting the image
        }
    }
}
