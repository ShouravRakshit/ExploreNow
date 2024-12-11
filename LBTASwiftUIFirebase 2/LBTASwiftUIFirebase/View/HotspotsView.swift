//
//  HotspotsView.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

//  To further expand this implementation, the locations present on the Hotspot
//  page can be collected using an algorithm that grabs the most popular locations
//  from the database

import SwiftUI
import Foundation
import Combine


struct Hotspots: View {
    @StateObject private var viewModel = HotspotsViewModel() // Initialize the view model

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title with the new purple color using RGB values
                    Text("TRENDING")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(Color(red: 0.60, green: 0.31, blue: 0.82)) // Purple color using RGB
                        .padding(.top, 20) // Add some top padding to avoid overlap with the navigation bar
                        .padding(.bottom, 10) // Some bottom padding for spacing

                    // Using VStack to stack images vertically
                    ForEach(0..<viewModel.suggestions.count, id: \.self) { index in
                        // NavigationLink to navigate to SuggestionPage when tapped
                        NavigationLink(destination: SuggestionPage(city: viewModel.suggestions[index].0)) {
                            VStack {
                                // Displaying the image for each suggestion
                                if let imageURL = viewModel.images[viewModel.suggestions[index].0], let url = URL(string: imageURL) {
                                    // Using AsyncImage to asynchronously load the image from the URL
                                    AsyncImage(url: url) { image in
                                        image.resizable().scaledToFill() // Resizes the image and scales it to fill the container
                                    } placeholder: {
                                        Color.gray.opacity(0.2) // Placeholder color while image is loading
                                    }
                                    .frame(height: 200) // Set consistent height for each image
                                    .cornerRadius(12) // Rounded corners for images
                                    .shadow(radius: 8) // Add a subtle shadow to the image for visual effect
                                    .padding(.bottom, 8) // Adds bottom padding to space out the images
                                } else {
                                    // Fallback when image URL is unavailable or image loading fails
                                    Color.gray.opacity(0.2) // Set a light gray background
                                        .frame(height: 200) // Ensure has consistent height
                                        .cornerRadius(12) // Add rounded corners for a soft, uniform appearance
                                        .shadow(radius: 8) // Apply a subtle shadow to match the design aesthetics of the images
                                        .padding(.bottom, 8) // Add space below the placeholder to maintain consistency in layout
                                }
                                
                                // Location name with purple background
                                Text(viewModel.suggestions[index].1) // Display the name of the location from the suggestions array
                                    .font(.headline)  // Use a headline font style to make the location name stand out
                                    .foregroundColor(.white) // White text color for the location name
                                    .padding(8) // Add padding around the text to ensure it doesn't touch the edges of the background
                                    .background(Color(red: 0.60, green: 0.31, blue: 0.82))  // Apply a custom purple background using RGB values
                                    .cornerRadius(8) // Round the corners of the background for a smooth, visually appealing effect
                                    .padding([.leading, .bottom], 10) // Add extra padding on the leading and bottom edges for spacing
                                    .shadow(radius: 4) // Apply a subtle shadow to the text box for depth and emphasis
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Hotspots") //sets the title of the navigation bar to "Hotspots."
            .navigationBarTitleDisplayMode(.inline) // Ensure the title is displayed inline
            .background(Color.white) // Set background to white for the overall view
            .onAppear {
                viewModel.fetchImagesForSuggestions() // Fetch images when the view appears
            }
        }
    }
}
