////
////  ProfileSettingsView.swift
////  LBTASwiftUIFirebase
////
////  Created by Alisha Lalani on 2024-10-19.
////
//
//import SwiftUI
//import Firebase
//import SDWebImageSwiftUI
//
//struct ProfileSettingsView: View {
//    @Environment(\.presentationMode) var presentationMode
//    @EnvironmentObject var userManager: UserManager
//
//    @State var shouldShowImagePicker = false
//    @State var image: UIImage?
//
//    @State private var selectedRow: String? // Track the selected row
//
//    @State private var showEditView = false
//    @State private var showChangePassword = false
//
//    @State private var isUploading = false // Loading state
//
//    var body: some View {
//        VStack {
//            //----- TOP ROW --------------------------------------
//            HStack {
//                Image(systemName: "chevron.left")
//                    .resizable() // Make the image resizable
//                    .aspectRatio(contentMode: .fit) // Maintain the aspect ratio
//                    .frame(width: 30, height: 30) // Set size
//                    .padding()
//                    .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255)) // Set color to #8C52FF
//                    .onTapGesture {
//                        // Go back to profile page
//                        presentationMode.wrappedValue.dismiss()
//                    }
//                Spacer() // Pushes the text to the center
//                Text("Edit Profile")
//                    .font(.custom("Sansation-Regular", size: 30))
//                    .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255)) // Set color to #8C52FF
//                    .offset(x: -30)
//                Spacer() // Pushes the text to the center
//            }
//            //------------------------------------------------
//            ZStack {
//                // Circular border
//                Circle()
//                    .stroke(Color.customPurple, lineWidth: 4) // Black border
//                    .frame(width: 188, height: 188) // Slightly larger than the image
//
//                if let selectedImage = self.image {
//                    // Display the newly selected image
//                    Image(uiImage: selectedImage)
//                        .resizable()
//                        .scaledToFill()
//                        .clipShape(Circle()) // Clip to circle shape
//                        .frame(width: 180, height: 180) // Set size
//                } else if let imageUrl = self.userManager.currentUser?.profileImageUrl {
//                    // Display the existing profile image from URL
//                    WebImage(url: URL(string: imageUrl)) { image in
//                        image
//                            .resizable()
//                            .scaledToFill()
//                            .clipShape(Circle())
//                    } placeholder: {
//                        ProgressView()
//                    }
//                    .frame(width: 180, height: 180)
//                } else {
//                    // Display placeholder image
//                    Image(systemName: "person.fill")
//                        .font(.system(size: 64))
//                        .padding()
//                        .foregroundColor(Color(.label))
//                        .frame(width: 180, height: 180) // Set size for placeholder
//                        .background(Color.gray.opacity(0.2)) // Optional background
//                        .clipShape(Circle()) // Clip to circle shape
//                }
//            }
//            .padding(.top, 30)
//
//            if self.userManager.currentUser?.profileImageUrl == nil {
//                // If no profile image exists
//                Text("Upload Profile Picture")
//                    .padding(.top, 15)
//                    .font(.custom("Sansation-Regular", size: 21))
//                    .foregroundColor(.blue)
//                    .underline() // Underline the text
//                    .onTapGesture {
//                        shouldShowImagePicker.toggle()
//                    }
//                    .padding(.bottom, 50)
//            } else {
//                // If a profile image already exists
//                Text("Change Profile Picture")
//                    .padding(.top, 15)
//                    .font(.custom("Sansation-Regular", size: 21))
//                    .foregroundColor(.blue)
//                    .underline() // Underline the text
//                    .onTapGesture {
//                        shouldShowImagePicker.toggle()
//                    }
//                    .padding(.bottom, 50)
//            }
//
//            // Display loading indicator if uploading
//            if isUploading {
//                ProgressView("Uploading...")
//                    .padding()
//            }
//
//            // Rest of your UI components (Grid, Change Password, etc.)
//            Grid {
//                Divider()
//                GridRow {
//                    HStack {
//                        Text("Name:")
//                            .frame(maxWidth: 125, alignment: .leading)
//                            .padding(.leading, 10)
//                            .font(.custom("Sansation-Bold", size: 20))
//                        if let name = self.userManager.currentUser?.name {
//                            Text(name)
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                                .offset(x: -10)
//                                .font(.custom("Sansation-Regular", size: 20))
//                        }
//                    }
//                    .padding(.vertical, 5)
//                    .background(selectedRow == "Name" ? Color.blue.opacity(0.1) : Color.clear) // Highlight if selected
//                    .onTapGesture {
//                        selectedRow = "Name" // Update selected row
//                        showEditView = true
//                    }
//                }
//
//                Divider()
//
//                GridRow {
//                    HStack {
//                        Text("Username:")
//                            .frame(maxWidth: 125, alignment: .leading)
//                            .padding(.leading, 10)
//                            .font(.custom("Sansation-Bold", size: 20))
//                        if let username = self.userManager.currentUser?.username {
//                            Text(username)
//                                .offset(x: -10)
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                                .font(.custom("Sansation-Regular", size: 20))
//                        }
//                    }
//                    .padding(.vertical, 5)
//                    .background(selectedRow == "Username" ? Color.blue.opacity(0.1) : Color.clear) // Highlight if selected
//                    .onTapGesture {
//                        selectedRow = "Username" // Update selected row
//                        showEditView = true
//                    }
//                }
//
//                Divider()
//
//                GridRow {
//                    HStack {
//                        Text("Bio:")
//                            .frame(maxWidth: 125, alignment: .leading)
//                            .padding(.leading, 10)
//                            .font(.custom("Sansation-Bold", size: 20))
//                        if let bio = self.userManager.currentUser?.bio {
//                            Text(bio)
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                                .offset(x: -10)
//                                .font(.custom("Sansation-Regular", size: 20))
//                                .lineLimit(nil) // Allow for multiple lines
//                                .fixedSize(horizontal: false, vertical: true) // Allow vertical growth
//                        } else {
//                            Text(" ")
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                                .offset(x: -10)
//                                .font(.custom("Sansation-Regular", size: 20))
//                                .lineLimit(nil) // Allow for multiple lines
//                                .fixedSize(horizontal: false, vertical: true) // Allow vertical growth
//                        }
//                    }
//                    .padding(.vertical, 5)
//                    .background(selectedRow == "Bio" ? Color.blue.opacity(0.1) : Color.clear) // Highlight if selected
//                    .onTapGesture {
//                        selectedRow = "Bio" // Update selected row
//                        showEditView = true
//                    }
//                }
//
//                Divider()
//            }
//
//            Text("Change Password")
//                .padding(.top, 50)
//                .font(.custom("Sansation-Regular", size: 23))
//                .foregroundColor(.blue)
//                .underline() // Underline the text
//                .onTapGesture {
//                    showChangePassword = true
//                }
//
//            Spacer() // Pushes content to the top
//        }
//        // Attach the fullScreenCover modifier to the VStack
//        .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: {
//            if image != nil {
//                persistImageToStorage()
//            }
//        }) {
//            ImagePicker(image: $image)
//        }
//        .fullScreenCover(isPresented: $showEditView) {
//            if selectedRow == "Name" {
//                EditView(fieldName: "Name")
//                    .environmentObject(userManager)
//            } else if selectedRow == "Username" {
//                EditView(fieldName: "Username")
//                    .environmentObject(userManager)
//            } else if selectedRow == "Bio" {
//                EditView(fieldName: "Bio")
//                    .environmentObject(userManager)
//            }
//        }
//        .fullScreenCover(isPresented: $showChangePassword) {
//            ChangePasswordView()
//                .environmentObject(userManager)
//        }
//    }
//
//    // Function to upload the image to Firebase Storage
//    private func persistImageToStorage() {
//        isUploading = true // Start loading
//
//        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
//        let ref = FirebaseManager.shared.storage.reference(withPath: "profile_images/\(uid).jpg")
//        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else { return }
//
//        ref.putData(imageData, metadata: nil) { metadata, err in
//            if let err = err {
//                print("Failed to push image to Storage: \(err.localizedDescription)")
//                isUploading = false // Stop loading
//                return
//            }
//            ref.downloadURL { url, err in
//                if let err = err {
//                    print("Failed to retrieve downloadURL: \(err.localizedDescription)")
//                    isUploading = false // Stop loading
//                    return
//                }
//                guard let url = url else { return }
//                self.storeUserInformation(imageProfileUrl: url)
//            }
//        }
//    }
//
//    // Function to update the user's profileImageUrl in Firestore
//    private func storeUserInformation(imageProfileUrl: URL) {
//        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
//
//        let userData = ["profileImageUrl": imageProfileUrl.absoluteString]
//
//        FirebaseManager.shared.firestore.collection("users")
//            .document(uid).updateData(userData) { err in
//                isUploading = false // Stop loading
//                if let err = err {
//                    print("Failed to update user data: \(err.localizedDescription)")
//                    return
//                }
//                print("Profile image URL successfully updated.")
//                // Refresh the currentUser data in userManager
//                self.userManager.fetchCurrentUser()
//                // Optionally, you can reset self.image here if needed
//                // self.image = nil
//            }
//    }
//}



















import SwiftUI
import Firebase
import SDWebImageSwiftUI

struct ProfileSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userManager: UserManager

    @State var shouldShowImagePicker = false
    @State var image: UIImage?

    @State private var selectedRow: String? // Track the selected row

    @State private var showEditView = false
    @State private var showChangePassword = false

    @State private var isUploading = false // Loading state

    var body: some View {
        VStack {
            //----- TOP ROW --------------------------------------
            HStack {
                Image(systemName: "chevron.left")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .padding()
                    .foregroundColor(Color.customPurple)
                    .onTapGesture {
                        // Go back to profile page
                        presentationMode.wrappedValue.dismiss()
                    }
                Spacer()
                Text("Edit Profile")
                    .font(.custom("Sansation-Regular", size: 30))
                    .foregroundColor(Color.customPurple)
                    .offset(x: -30)
                Spacer()
            }
            //------------------------------------------------
            ZStack {
                // Circular border
                Circle()
                    .stroke(Color.customPurple, lineWidth: 4) // Purple border
                    .frame(width: 188, height: 188) // Slightly larger than the image

                if let selectedImage = self.image {
                    // Display the newly selected image
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle()) // Clip to circle shape
                        .frame(width: 180, height: 180) // Set size
                } else if let imageUrl = self.userManager.currentUser?.profileImageUrl, !imageUrl.isEmpty {
                    // Display the existing profile image from URL
                    WebImage(url: URL(string: imageUrl))
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 180, height: 180)
                } else {
                    // Display placeholder image
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 180, height: 180)
                        .foregroundColor(Color(.label))
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            .padding(.top, 30)

            // Button to upload or change profile picture
            if self.userManager.currentUser?.profileImageUrl == nil || (self.userManager.currentUser?.profileImageUrl?.isEmpty ?? true) {
                // If no profile image exists
                Text("Upload Profile Picture")
                    .padding(.top, 15)
                    .font(.custom("Sansation-Regular", size: 21))
                    .foregroundColor(.blue)
                    .underline() // Underline the text
                    .onTapGesture {
                        shouldShowImagePicker.toggle()
                    }
                    .padding(.bottom, 50)
            } else {
                // If a profile image already exists
                Text("Change Profile Picture")
                    .padding(.top, 15)
                    .font(.custom("Sansation-Regular", size: 21))
                    .foregroundColor(.blue)
                    .underline() // Underline the text
                    .onTapGesture {
                        shouldShowImagePicker.toggle()
                    }
                    .padding(.bottom, 50)
            }

            // Display loading indicator if uploading
            if isUploading {
                ProgressView("Uploading...")
                    .padding()
            }

            // Profile Information Grid
            Grid {
                Divider()
                GridRow {
                    HStack {
                        Text("Name:")
                            .frame(maxWidth: 125, alignment: .leading)
                            .padding(.leading, 10)
                            .font(.custom("Sansation-Bold", size: 20))
                        if let name = self.userManager.currentUser?.name {
                            Text(name)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .offset(x: -10)
                                .font(.custom("Sansation-Regular", size: 20))
                        }
                    }
                    .padding(.vertical, 5)
                    .background(selectedRow == "Name" ? Color.blue.opacity(0.1) : Color.clear) // Highlight if selected
                    .onTapGesture {
                        selectedRow = "Name" // Update selected row
                        showEditView = true
                    }
                }

                Divider()

                GridRow {
                    HStack {
                        Text("Username:")
                            .frame(maxWidth: 125, alignment: .leading)
                            .padding(.leading, 10)
                            .font(.custom("Sansation-Bold", size: 20))
                        if let username = self.userManager.currentUser?.username {
                            Text(username)
                                .offset(x: -10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.custom("Sansation-Regular", size: 20))
                        }
                    }
                    .padding(.vertical, 5)
                    .background(selectedRow == "Username" ? Color.blue.opacity(0.1) : Color.clear) // Highlight if selected
                    .onTapGesture {
                        selectedRow = "Username" // Update selected row
                        showEditView = true
                    }
                }

                Divider()

                GridRow {
                    HStack {
                        Text("Bio:")
                            .frame(maxWidth: 125, alignment: .leading)
                            .padding(.leading, 10)
                            .font(.custom("Sansation-Bold", size: 20))
                        if let bio = self.userManager.currentUser?.bio {
                            Text(bio)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .offset(x: -10)
                                .font(.custom("Sansation-Regular", size: 20))
                                .lineLimit(nil) // Allow for multiple lines
                                .fixedSize(horizontal: false, vertical: true) // Allow vertical growth
                        } else {
                            Text(" ")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .offset(x: -10)
                                .font(.custom("Sansation-Regular", size: 20))
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, 5)
                    .background(selectedRow == "Bio" ? Color.blue.opacity(0.1) : Color.clear) // Highlight if selected
                    .onTapGesture {
                        selectedRow = "Bio" // Update selected row
                        showEditView = true
                    }
                }

                Divider()
            }

            Text("Change Password")
                .padding(.top, 50)
                .font(.custom("Sansation-Regular", size: 23))
                .foregroundColor(.blue)
                .underline() // Underline the text
                .onTapGesture {
                    showChangePassword = true
                }

            Spacer() // Pushes content to the top
        }
        // Attach the fullScreenCover modifier to the VStack
        .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: {
            if image != nil {
                persistImageToStorage()
            }
        }) {
            ImagePicker(image: $image)
        }
        .fullScreenCover(isPresented: $showEditView) {
            if selectedRow == "Name" {
                EditView(fieldName: "Name")
                    .environmentObject(userManager)
            } else if selectedRow == "Username" {
                EditView(fieldName: "Username")
                    .environmentObject(userManager)
            } else if selectedRow == "Bio" {
                EditView(fieldName: "Bio")
                    .environmentObject(userManager)
            }
        }
        .fullScreenCover(isPresented: $showChangePassword) {
            ChangePasswordView()
                .environmentObject(userManager)
        }
    }
    
    // Function to upload the image to Firebase Storage
    private func persistImageToStorage() {
        isUploading = true // Start loading

        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        let uniqueImagePath = "profile_images/\(uid)_\(UUID().uuidString).jpg" // Unique path to prevent caching issues
        let ref = FirebaseManager.shared.storage.reference(withPath: uniqueImagePath)
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else { return }

        ref.putData(imageData, metadata: nil) { metadata, err in
            if let err = err {
                print("Failed to push image to Storage: \(err.localizedDescription)")
                isUploading = false // Stop loading
                return
            }
            ref.downloadURL { url, err in
                if let err = err {
                    print("Failed to retrieve downloadURL: \(err.localizedDescription)")
                    isUploading = false // Stop loading
                    return
                }
                guard let url = url else { return }
                print("New profileImageUrl: \(url.absoluteString)") // Debugging
                self.storeUserInformation(imageProfileUrl: url)
            }
        }
    }

    // Function to update the user's profileImageUrl in Firestore
    private func storeUserInformation(imageProfileUrl: URL) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }

        let userData = ["profileImageUrl": imageProfileUrl.absoluteString]

        FirebaseManager.shared.firestore.collection("users")
            .document(uid).updateData(userData) { err in
                isUploading = false // Stop loading
                if let err = err {
                    print("Failed to update user data: \(err.localizedDescription)")
                    return
                }
                print("Profile image URL successfully updated.")
                // Refresh the currentUser data in userManager
                self.userManager.fetchCurrentUser()
            }
    }
}
