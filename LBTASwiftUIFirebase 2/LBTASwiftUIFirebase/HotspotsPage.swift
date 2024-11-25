//
//  HotspotsPage.swift
//  LBTASwiftUIFirebase
//
//  Created by Manvi Juneja and Shree Patel on 2024-11-24.
//
//  To further expand this implementation, the locations present on the Hotspots page can be collected using an algorithm that grabs the most popular locations from the database. Additioanlly, when a location is clicked, the location page view for that location can be displayed (similar to how it is displayed in the Explore page), so that the user can view all posts present in that location.

import SwiftUI
import Foundation

// Pixabay Response Model
struct PixabayResponse1: Decodable {
    let hits: [PixabayImage1]
}

struct PixabayImage1: Decodable {
    let webformatURL: String
}

// Color Extension for Hex Values
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.currentIndex = hex.startIndex
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}

struct Hotspots: View {
    @State private var displayedSuggestions: [(String, String)] = []
    @State private var currentPage: Int = 0
    @State private var images: [String: String] = [:] // Store images for each place
    @State private var selectedCity: String? = nil // Store the selected city dynamically

    // List of trending locations
    let suggestions = [
        ("Jasper", "Jasper, Canada"),
        ("Banff", "Banff, Canada"),
        ("Korea", "Seoul, Korea"),
        ("Paris", "Paris, France"),
        ("Drumheller", "Drumheller, Canada"),
        ("Canmore", "Canmore, Canada"),
        ("Toronto", "Toronto, Canada"),
        ("Calgary", "Calgary, Canada"),
        ("Japan", "Kyoto, Japan"),
        ("Italy", "Venice, Italy")
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                // Displaying the heading for the page
                VStack(alignment: .leading, spacing: 16) {
                    Text("TRENDING")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(Color(hex: "8C52FF"))

                    // Using VStack to stack images vertically
                    ForEach(0..<suggestions.count, id: \.self) { index in
                        NavigationLink(destination: SuggestionPage(city: suggestions[index].0, selectedCity: $selectedCity)) {
                            VStack {
                                if let imageURL = images[suggestions[index].0], let url = URL(string: imageURL) {
                                    AsyncImage(url: url) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        Color.gray.opacity(0.2)
                                    }
                                    .frame(height: 200) // Set consistent height for each image
                                    .cornerRadius(8)
                                    .padding(.bottom, 8)
                                } else {
                                    Color.gray.opacity(0.2)
                                        .frame(height: 200)
                                        .cornerRadius(8)
                                        .padding(.bottom, 8)
                                }
                                // Displaying the name of the location
                                Text(suggestions[index].1)
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
                        fetchImagesForSuggestions()
                    }
                }
                .padding()
            }
            .navigationTitle("Hotspots")
        }
    }

    func fetchImagesForSuggestions() {
        let apiKey = "47197466-e97591543dd5d0d29999d6d75"
        for suggestion in suggestions {
            let query = suggestion.0.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? suggestion.0
            let urlString = "https://pixabay.com/api/?key=\(apiKey)&q=\(query)&image_type=photo"

            guard let url = URL(string: urlString) else { continue }

            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    do {
                        let decodedResponse = try JSONDecoder().decode(PixabayResponse1.self, from: data)
                        DispatchQueue.main.async {
                            if let firstImage = decodedResponse.hits.first {
                                images[suggestion.0] = firstImage.webformatURL
                            }
                        }
                    } catch {
                        print("Error decoding response for \(suggestion.0): \(error)")
                    }
                }
            }.resume()
        }
    }
}

struct SuggestionPage: View {
    let city: String
    @Binding var selectedCity: String? // Binding to update selected city in Hotspots view
    @State private var detailedImages: [PixabayImage1] = []

    var body: some View {
        VStack {
            Text("Welcome to \(selectedCity ?? city)") // Use binding city or fallback to provided city
                .font(.largeTitle)
                .padding()

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(detailedImages, id: \.webformatURL) { image in
                        AsyncImage(url: URL(string: image.webformatURL)) { img in
                            img.resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipped()
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                        .cornerRadius(8)
                    }
                }
            }
            .onAppear {
                fetchDetailedImages(for: city) // Fetch images based on the selected city
            }
        }
        .padding()
    }

    func fetchDetailedImages(for query: String) {
        let apiKey = "47197466-e97591543dd5d0d29999d6d75"
        let urlString = "https://pixabay.com/api/?key=\(apiKey)&q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&image_type=photo"

        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode(PixabayResponse1.self, from: data)
                    DispatchQueue.main.async {
                        detailedImages = decodedResponse.hits
                        selectedCity = query // Update selectedCity when images are loaded
                    }
                } catch {
                    print("Error decoding detailed images: \(error)")
                }
            }
        }.resume()
    }
}

