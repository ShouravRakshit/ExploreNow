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
    @State private var selectedImages: [PixabayImage] = []
    @State private var cancellable: AnyCancellable?
    @State private var isLoading: Bool = false

    var allowsMultipleSelection: Bool 
    var onImagesSelected: ([PixabayImage]) -> Void

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
                                    imageTapped(image)
                                }) {
                                    ZStack {
                                        if let urlString = image.previewURL, let url = URL(string: urlString) {
                                            WebImage(url: url)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .clipped()
                                                .cornerRadius(8)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(selectedImages.contains(where: { $0.id == image.id }) ? Color.blue : Color.clear, lineWidth: 4)
                                                )
                                                .opacity(selectedImages.contains(where: { $0.id == image.id }) ? 0.7 : 1.0)
                                                .overlay(
                                                    selectedImages.contains(where: { $0.id == image.id }) ?
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
            .navigationBarTitle("Select Images", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: allowsMultipleSelection ? Button("Add") {
                    onImagesSelected(selectedImages)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(selectedImages.isEmpty)
                : nil
            )
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
        selectedImages = [] // Reset selection when new search occurs
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

    private func imageTapped(_ image: PixabayImage) {
        if allowsMultipleSelection {
            toggleSelection(for: image)
        } else {
            // Single selection mode
            onImagesSelected([image])
            presentationMode.wrappedValue.dismiss()
        }
    }

    private func toggleSelection(for image: PixabayImage) {
        if let index = selectedImages.firstIndex(where: { $0.id == image.id }) {
            selectedImages.remove(at: index)
        } else {
            selectedImages.append(image)
        }
    }
}
