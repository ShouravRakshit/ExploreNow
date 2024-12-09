//
//  SuggestProfilePicView.swift
//  LBTASwiftUIFirebase
//
//  Created by Alisha Lalani on 2024-10-17.
//
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import SDWebImage

// A view that suggests a profile picture to the currently logged-in user.
// Users can select an image from Pixabay, upload it to Firebase, and update their profile.
struct SuggestProfilePicView: View {
    // The global app state, used here to set the logged in status.
    @EnvironmentObject var appState: AppState
    
    // Manages current user information and fetch requests.
    @EnvironmentObject var userManager: UserManager
    
    // The view model that handles data and logic for this view.
    @StateObject var viewModel = SuggestProfilePicViewModel()
    
    // Controls whether to present the Pixabay image picker sheet.
    @State private var showPixabayPicker = false

    // Convenience property to get the current user from UserManager.
    private var currentUser: User? {
        userManager.currentUser
    }

    var body: some View {
        VStack {
            // Greet the current user by name if available.
            if let user = currentUser {
                Text("Welcome, \(user.name)")
                    .padding(.top, 50)
                    .font(.custom("Sansation-Regular", size: 35))
                    .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255))
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }

            ZStack {
                // A circular border around the profile image.
                Circle()
                    .stroke(Color.black, lineWidth: 4)
                    .frame(width: 188, height: 188)

                // If an image is selected, show it inside a circle. Otherwise, show a placeholder.
                if let image = viewModel.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 180, height: 180)
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 64))
                        .padding()
                        .foregroundColor(Color(.label))
                        .frame(width: 180, height: 180)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            .padding(.top, 30)

            // A prompt to upload a profile picture. Tapping it shows the Pixabay picker.
            Text("Upload Profile Picture")
                .foregroundColor(Color.blue)
                .font(.custom("Sansation-Regular", size: 25))
                .padding(.top, 10)
                .underline()
                .onTapGesture {
                    showPixabayPicker.toggle()
                }
                .sheet(isPresented: $showPixabayPicker) {
                    // PixabayImagePickerView allows selecting an image from a remote source.
                    PixabayImagePickerView(allowsMultipleSelection: false) { selectedImages in
                        if let selectedImage = selectedImages.first,
                           let urlString = selectedImage.largeImageURL,
                           let url = URL(string: urlString) {
                            // Use the ViewModel's downloadImage method to fetch the image.
                            viewModel.downloadImage(from: url) { image in
                                viewModel.image = image
                            }
                        }
                    }
                }

            // Button to confirm uploading the selected image as the profile picture.
            Button(action: {
                viewModel.persistImageToStorage(appState: appState, userManager: userManager)
            }) {
                Text ("Set Profile Picture")
                    .foregroundColor(.white)
                    .font(.custom("Sansation-Regular", size: 20))
                    .padding()
                    .frame(width: 335, alignment: .center)
                    .background(Color(red: 140/255, green: 82/255, blue: 255/255))
                    .cornerRadius(15)
            }
            .padding(.top, 30)
            .disabled(viewModel.image == nil) // Disabled if no image is selected.

            // If the user doesn't want to set a profile picture now, they can skip.
            Text("Skip for now")
                .foregroundColor(Color.black)
                .font(.custom("Sansation-Regular", size: 20))
                .padding(.top, 50)
                .underline()
                .onTapGesture {
                    // Simply mark the user as logged in and skip setting the picture.
                    self.appState.isLoggedIn = true
                }

            Spacer()
        }
    }
}
