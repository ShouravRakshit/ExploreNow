//
//  AddPostView.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni


import SwiftUI
import SDWebImageSwiftUI
import MapKit


struct AddPostView: View {
    @EnvironmentObject var userManager: UserManager
    let locationManager = CustomLocationManager()
    
    @ObservedObject var viewModel = AddPostViewModel()
    @State private var showPixabayPicker = false
    @State private var showImageSourceOptions = false
    @Environment(\.dismiss) var dismiss
    
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    imagesSection
                    descriptionSection
                    locationSection
                    ratingSection
                    statusMessage
                    postButton
                }
                .padding(.vertical, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("New Post")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .background(AppTheme.background)
        }
        .sheet(isPresented: $showPixabayPicker) {
            PixabayImagePickerView(allowsMultipleSelection: true) { selectedImages in
                handleSelectedImages(selectedImages)
            }
        }
        .actionSheet(isPresented: $showImageSourceOptions) {
            ActionSheet(
                title: Text("Select Image Source"),
                message: nil,
                buttons: [
                    .default(Text("Photo Library")) { showPixabayPicker = true },
                    .cancel()
                ]
            )
        }
    }
    
    private var imagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photos")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    addPhotoButton
                    imagePreviews
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal)
    }
    
    private var addPhotoButton: some View {
        Button(action: { showImageSourceOptions = true }) {
            VStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                Text("Add Photos")
                    .font(.system(size: 12))
            }
            .frame(width: 100, height: 100)
            .background(AppTheme.lightPurple)
            .foregroundColor(AppTheme.primaryPurple)
            .cornerRadius(12)
        }
    }
    
    private var imagePreviews: some View {
        ForEach(viewModel.images, id: \.self) { image in
            ZStack(alignment: .topTrailing) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Button(action: {
                    if let index = viewModel.images.firstIndex(of: image) {
                        viewModel.images.remove(at: index)
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .padding(4)
            }
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.system(size: 16, weight: .semibold))
            TextField("Share your experience...", text: $viewModel.descriptionText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .frame(height: 100, alignment: .top)
                .padding(8)
                .background(AppTheme.background)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .lineLimit(5...10)
                .tint(.blue)
        }
        .padding(.horizontal)
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(.system(size: 16, weight: .semibold))
            LocationSearchBar(selectedLocation: $viewModel.selectedLocation, latitude: $viewModel.latitude, longitude: $viewModel.longitude)
                .background(AppTheme.background)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        }
        .padding(.horizontal)
    }
    
    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Rating")
                .font(.system(size: 16, weight: .semibold))
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= viewModel.rating ? "star.fill" : "star")
                        .font(.system(size: 24))
                        .foregroundColor(star <= viewModel.rating ? .yellow : Color(.systemGray4))
                        .onTapGesture {
                            withAnimation(.spring()) {
                                viewModel.rating = star
                            }
                        }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var statusMessage: some View {
        Group {
            if !viewModel.addPostStatusMessage.isEmpty {
                Text(viewModel.addPostStatusMessage)
                    .font(.system(size: 14))
                    .foregroundColor(viewModel.addPostStatusMessage.contains("Error") ? AppTheme.error : AppTheme.success)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        viewModel.addPostStatusMessage.contains("Error") ? AppTheme.error.opacity(0.1) : AppTheme.success.opacity(0.1)
                    )
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
        }
    }
    
    private var postButton: some View {
        Button(action: viewModel.addPost) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.trailing, 8)
                }
                Text("Share Post")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(viewModel.isLoading ? Color.gray : AppTheme.primaryPurple)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(viewModel.isLoading)
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private func handleSelectedImages(_ selectedImages: [PixabayImage]) {
        let group = DispatchGroup()
        for selectedImage in selectedImages {
            if let urlString = selectedImage.largeImageURL, let url = URL(string: urlString) {
                group.enter()
                downloadImage(from: url) { image in
                    if let image = image {
                        viewModel.images.append(image)
                    }
                    group.leave()
                }
            }
        }
        group.notify(queue: .main) {
            print("All images downloaded and added.")
        }
    }
    
    // Function to download the images from Pixabay
    private func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        SDWebImageDownloader.shared.downloadImage(with: url) { image, data, error, finished in
            DispatchQueue.main.async {
                if let image = image, finished {
                    completion(image)
                } else {
                    print("Failed to download image: \(error?.localizedDescription ?? "Unknown error")")
                    completion(nil)
                }
            }
        }
    }
}

