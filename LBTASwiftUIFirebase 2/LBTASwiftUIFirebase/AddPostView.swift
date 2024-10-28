//
//  AddPostView.swift
//  LBTASwiftUIFirebase
//
//  Created by Manvi Juneja on 2024-10-22.
//

import Foundation

import SwiftUI

struct AddPostView: View {
    @State private var descriptionText: String = ""
    @State private var rating: Int = 0
    @State private var isRatingSheetPresented = false
    @State private var isLocationSheetPresented = false
    @State private var selectedLocation: String = ""
    @State private var images: [UIImage] = [] // Array for selected images
    @State private var isImagePickerPresented = false
    
    // Define grid layout for 2 images per row
        let columns = [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
    
    var body: some View {
        VStack {
            // Header with close button, "New Post" title and Divider
            HStack {
                Button(action: {
                    // Action to close, needs implementation
                }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                }
                
                Spacer()
                
                Text("New Post")
                    .font(.title3)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Spacer()
                    .frame(width: 30) // Empty space on the right
            }
            .padding()
            
            // Divider below the header
            Divider()
                .background(Color.gray)
            
            // Profile section
            HStack(alignment: .center) {
                // User profile picture
                Image("user_profile") // Replace with actual user profile image
                    .resizable()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .padding(.leading, 10)

                    Text("User 1")
                    .font(.custom("Sansation", size: 20))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 5)
                        .background(Color(red: 140/255, green: 82/255, blue: 255/255))
                        .cornerRadius(15)
                Spacer()
                }
                .padding(.horizontal)
            
           
            HStack(alignment: .top) {
                TextField("Description of the recently visited place...", text: $descriptionText)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 5)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)
           
            Spacer()
            Divider()
                .background(Color.gray)
                .padding(.top, 15)
           
           
            // Add location button (placeholder)
            Button(action: {
                isLocationSheetPresented = true
                // Action to provide location
            }) {
                HStack{
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 20))
                    Text("Location")
                        .font(.system(size: 20))
                    Spacer()
                    Text(selectedLocation.isEmpty ? "" : "\(selectedLocation)")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.headline)
                .foregroundColor(.black)
            }
            .padding()
            .sheet(isPresented: $isLocationSheetPresented) {
                LocationSearchView(selectedLocation: $selectedLocation) // Pass the binding
            }
            
            
            // Add Ratings button (placeholder)
            Button(action: {
                isRatingSheetPresented = true
                // Action to provide rating
            }) {
                HStack{
                    Image(systemName: "star.fill")
                        .font(.system(size: 20))
                    Text("Ratings")
                        .font(.system(size: 20))
                    Spacer() // Added to push the rating text to the right
                                        Text(rating > 0 ? "\(rating) star\(rating > 1 ? "s" : "")" : "")
                        .font(.system(size: 20)) // Smaller font for the rating text
                                            .foregroundColor(.gray) // Optional: Change color
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.headline)
                .foregroundColor(.black)
            }
            .padding()
            .sheet(isPresented: $isRatingSheetPresented) {
                            // Present the rating selection view
                            RatingSelectionView(selectedRating: $rating)
                        }
            
            
            // Add Photos button (placeholder)
            Button(action: {
                isImagePickerPresented = true
                // Action to add photos
            }) {
                HStack{
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                    Text("Add Photos")
                        .font(.system(size: 20))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.headline)
                .foregroundColor(.black)
            }
            .padding()
            .sheet(isPresented: $isImagePickerPresented) {
                            AddPhotos(images: $images) // Present the image picker
                        }

            // Grid view for selected images with delete option
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(images, id: \.self) { image in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 200) // Set a larger height for images
                                            .cornerRadius(15)
                                            .clipped()

                                        // Delete button overlay
                                        Button(action: {
                                            if let index = images.firstIndex(of: image) {
                                                images.remove(at: index) // Remove the image
                                            }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .padding(5)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.horizontal, 5)
                        }
                        .frame(height: 300) // Adjust the height to display images better

            
            
            Spacer()
            
            // Post button
            Button(action: {
                // Action to post
            }) {
                Text("Post")
                    .font(.custom("Sansation-Regular", size: 23))
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 350)
                    .background(Color(red: 140/255, green: 82/255, blue: 255/255))
                    .cornerRadius(15)
            }
            .padding(.horizontal, 50)
        }
        .navigationBarHidden(true)
        .onAppear {
                    // Optional: Hide the navigation bar when this view appears
                    UINavigationBar.setAnimationsEnabled(false)
                }
    }
}

// The rating selection pop-up view
struct RatingSelectionView: View {
    @Binding var selectedRating: Int
    @Environment(\.presentationMode) var presentationMode // To dismiss the view

    var body: some View {
        VStack {
            Spacer()
            Text("Select Your Rating")
                .font(.largeTitle)
                .padding()
            
            HStack {
                ForEach(1..<6) { rating in
                    Button(action: {
                        selectedRating = rating  // Update the selected rating
                    }) {
                        Image(systemName: rating <= selectedRating ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.largeTitle)
                    }
                }
            }
            .padding()

            Spacer()

            Button(action: {
                // Dismiss the sheet (pop-up)
                                presentationMode.wrappedValue.dismiss() // Close the view
            }) {
                Text("Done")
                    .font(.title2)
                    .padding()
                    .frame(width: 200)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            Spacer()
        }
    }
}


struct AddPostView_Previews: PreviewProvider {
    static var previews: some View {
        AddPostView()
    }
}
