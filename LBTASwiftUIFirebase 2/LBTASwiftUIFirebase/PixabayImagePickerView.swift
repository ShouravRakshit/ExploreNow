//
//  PixabayImagePickerView.swift
//  LBTASwiftUIFirebase
//
//  Created by Ivan on 2024-11-21.
//

import SwiftUI
import SDWebImageSwiftUI
import Combine

struct PixabayImagePickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var searchQuery: String = ""
    @State private var images: [PixabayImage] = []
    @State private var cancellable: AnyCancellable?
    @State private var isLoading: Bool = false

    var onImageSelected: (PixabayImage) -> Void

    var body: some View {
        NavigationView {
            VStack {
                searchBar
                if isLoading {
                    ProgressView("Loading...")
                        .padding()
                } else if images.isEmpty {
                    Text("No images found.")
                        .foregroundColor(.gray)
                        .padding()
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                            ForEach(images) { image in
                                Button(action: {
                                    onImageSelected(image)
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    if let urlString = image.previewURL, let url = URL(string: urlString) {
                                        WebImage(url: url)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipped()
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitle("Select Image", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .onAppear {
            fetchImages(query: "popular")
        }
    }

    private var searchBar: some View {
        HStack {
            TextField("Search images...", text: $searchQuery, onCommit: {
                fetchImages(query: searchQuery)
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal)
            if isLoading {
                ProgressView()
                    .padding(.trailing)
            }
        }
    }

    private func fetchImages(query: String) {
        isLoading = true
        images = []
        cancellable = PixabayAPI.shared.searchImages(query: query)
            .sink(receiveCompletion: { completion in
                isLoading = false
                if case let .failure(error) = completion {
                    print("Error fetching images: \(error.localizedDescription)")
                }
            }, receiveValue: { images in
                self.images = images
            })
    }
}
