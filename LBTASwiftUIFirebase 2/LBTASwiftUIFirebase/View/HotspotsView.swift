//
//  HotspotsView.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 04/12/2024.
//

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
                        NavigationLink(destination: SuggestionPage(city: viewModel.suggestions[index].0)) {
                            VStack {
                                // Displaying the image for each suggestion
                                if let imageURL = viewModel.images[viewModel.suggestions[index].0], let url = URL(string: imageURL) {
                                    AsyncImage(url: url) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        Color.gray.opacity(0.2)
                                    }
                                    .frame(height: 200) // Set consistent height for each image
                                    .cornerRadius(12) // Rounded corners for images
                                    .shadow(radius: 8) // Add a subtle shadow
                                    .padding(.bottom, 8)
                                } else {
                                    Color.gray.opacity(0.2)
                                        .frame(height: 200)
                                        .cornerRadius(12)
                                        .shadow(radius: 8)
                                        .padding(.bottom, 8)
                                }
                                
                                // Location name with purple background
                                Text(viewModel.suggestions[index].1)
                                    .font(.headline)
                                    .foregroundColor(.white) // White text color for the location name
                                    .padding(8)
                                    .background(Color(red: 0.60, green: 0.31, blue: 0.82)) // Purple background using RGB
                                    .cornerRadius(8)
                                    .padding([.leading, .bottom], 10)
                                    .shadow(radius: 4) // Add a light shadow for text box
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Hotspots")
            .navigationBarTitleDisplayMode(.inline) // Ensure the title is displayed inline
            .background(Color.white) // Set background to white for the overall view
            .onAppear {
                viewModel.fetchImagesForSuggestions() // Fetch images when the view appears
            }
        }
    }
}
