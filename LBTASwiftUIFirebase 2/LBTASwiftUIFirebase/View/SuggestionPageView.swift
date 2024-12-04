//
//  SuggestionPageView.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 04/12/2024.
//


import SwiftUI
import Combine

struct SuggestionPage: View {
    let city: String
    @StateObject private var viewModel: SuggestionPageViewModel
    
    init(city: String) {
        self.city = city
        _viewModel = StateObject(wrappedValue: SuggestionPageViewModel(city: city)) // Initialize the ViewModel
    }
    
    var body: some View {
        VStack {
            Text("Welcome to \(viewModel.selectedCity)") // Use the ViewModel's city
                .font(.largeTitle)
                .padding()
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(viewModel.detailedImages, id: \.webformatURL) { image in
                        AsyncImage(url: URL(string: image.webformatURL ?? "")) { img in
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
        }
        .padding()
        .onAppear {
            viewModel.fetchDetailedImages(for: city) // Fetch images when the view appears
        }
    }
}

