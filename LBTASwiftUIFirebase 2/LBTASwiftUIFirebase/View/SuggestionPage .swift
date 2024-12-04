//
//  SuggestionPage .swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 04/12/2024.
//

import SwiftUI


struct SuggestionPage: View {
    let city: String
    @StateObject private var viewModel = SuggestionPageViewModel()

    var body: some View {
        VStack {
            Text("Welcome to \(city)") // Use binding city or fallback to provided city
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
            .onAppear {
                viewModel.fetchDetailedImages(for: city)
            }
        }
        .padding()
    }
}
