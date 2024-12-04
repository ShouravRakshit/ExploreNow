//
//  Hotspots.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 04/12/2024.
//

import SwiftUI


struct Hotspots: View {
    @StateObject private var viewModel = HotspotsViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("TRENDING")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)

                    ForEach(viewModel.suggestions, id: \.0) { suggestion in
                        NavigationLink(destination: SuggestionPage(city: suggestion.0)) {
                            VStack {
                                if let imageURL = viewModel.images[suggestion.0], let url = URL(string: imageURL) {
                                    AsyncImage(url: url) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        Color.gray.opacity(0.2)
                                    }
                                    .frame(height: 200)
                                    .cornerRadius(8)
                                    .padding(.bottom, 8)
                                } else {
                                    Color.gray.opacity(0.2)
                                        .frame(height: 200)
                                        .cornerRadius(8)
                                        .padding(.bottom, 8)
                                }

                                Text(suggestion.1)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(8)
                                    .padding([.leading, .bottom], 10)
                            }
                        }
                    }
                    .onAppear {
                        viewModel.fetchImagesForSuggestions()
                    }
                }
                .padding()
                .background(
                    Color(UIColor(hex: "#9a4fd1") ?? .purple) // Solid purple color
                )
                .cornerRadius(10)
            }
            .background(Color.gray.opacity(0.05))
            .navigationTitle("Hotspots")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
