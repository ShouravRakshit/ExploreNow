//
// ProfileSettingsView.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni


import SwiftUI
import Firebase
import SDWebImageSwiftUI
struct ProfileSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var appState: AppState
    let settingsManager = UserSettingsManager()
    //    @State var shouldShowImagePicker = false
    
    // Pass appState to the ViewModel
    @StateObject private var viewModel: ProfileSettingsViewModel

    // Pass appState and userManager to the ViewModel
    init(appState: AppState, userManager: UserManager) {
        _viewModel = StateObject(wrappedValue: ProfileSettingsViewModel(appState: appState, userManager: userManager))
    }
    
    @State var image: UIImage?
    @State private var showImageSourceOptions = false
    @State private var showPixabayPicker = false
    @State private var selectedRow: String? // Track the selected row
    @State private var showEditView       = false
    @State private var showChangePassword = false
    @State private var showBlockedUsers   = false
    @State private var showingAlert = false
    
    var body: some View {
        VStack {
            //----- TOP ROW --------------------------------------
            HStack {
                Image(systemName: "chevron.left")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 25, height: 25)
                    .padding()
                    .foregroundColor(Color.customPurple)
                    .onTapGesture {
                        // Go back to profile page
                        presentationMode.wrappedValue.dismiss()
                    }
                Spacer()
                Text("Settings")
                    .font(.custom("Sansation-Regular", size: 25))
                    .foregroundColor(Color.customPurple)
                    .offset(x: -30)
                Spacer()
            }
            .padding(.top, 20)
            //------------------------------------------------
            ZStack {
                // Circular border
                Circle()
                    .stroke(Color.customPurple, lineWidth: 4) // Purple border
                    .frame(width: 188, height: 188) // Slightly larger than the image
                if viewModel.isUploading {
                    // Show loading spinner
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .customPurple))
                        .frame(width: 180, height: 180)
                }
                else if let selectedImage = self.image {
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
            .padding(.top, 10)
            
            Button(action: {
                showImageSourceOptions = true
            }) {
                Text(self.userManager.currentUser?.profileImageUrl == nil || (self.userManager.currentUser?.profileImageUrl?.isEmpty ?? true) ? "Upload Profile Picture" : "Change Profile Picture")
                    .padding(.top, 15)
                    .font(.custom("Sansation-Regular", size: 21))
                    .foregroundColor(.blue)
                    .underline()
                    .padding(.bottom, 20)
            }.actionSheet(isPresented: $showImageSourceOptions) {
                ActionSheet(title: Text("Select Image Source"), message: nil, buttons: [
                    .default(Text("Photo Library")) {
                        showPixabayPicker = true // Open Pixabay when "Photo Library" is selected
                    },
                    .cancel()
                ])
            }.fullScreenCover(isPresented: $showPixabayPicker) {
                PixabayImagePickerView(allowsMultipleSelection: false) { selectedImages in
                    if let selectedImage = selectedImages.first,
                       let urlString = selectedImage.largeImageURL,
                       let url = URL(string: urlString) {
                        viewModel.downloadImage(from: url) { downloadedImage in
                            if let downloadedImage = downloadedImage {
                                self.image = downloadedImage
                                // Call persistImageToStorage() after image is set
                                viewModel.persistImageToStorage(image: downloadedImage)
                            } else {
                                print("Image download failed.")
                            }
                            // Dismiss the picker
                            self.showPixabayPicker = false
                        }
                    } else {
                        print("Invalid image selection.")
                        // Dismiss the picker
                        self.showPixabayPicker = false
                    }
                }
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
            .padding (.top, 5)
            
            Text("Blocked Users >")
                .padding(.top, 10)
                .font(.custom("Sansation-Regular", size: 18))
                .foregroundColor(.red)
                .onTapGesture {
                    showBlockedUsers = true
                }
            
            ToggleButtonView(userId: userManager.currentUser?.uid ?? "")
            
            Button(action: {
                showChangePassword = true
            }) {
                Text("Change Password")
                    .font(.custom("Sansation-Regular", size: 16))
                    .frame(width: 360, height: 50)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(22)
                    .shadow(radius: 4)
            }
            .padding(.top, 5)
            
            
            // "Delete Account" Button
            Button(action: {
                showingAlert = true
            }) {
                Text("Delete Account")
                    .font(.custom("Sansation-Regular", size: 16))
                    .frame(width: 360, height: 50)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(22)  // Rounded corners
                    .shadow(radius: 4) // Add shadow to match the visual style
            }
            .padding(.top, 5)
            
            Spacer() // Pushes content to the top
            Spacer()
        }
        .padding(.horizontal, 15)

    
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
        .fullScreenCover(isPresented: $showBlockedUsers) {
            BlockedUsersView()
                .environmentObject(userManager)
        }
        .alert(isPresented: $showingAlert) {
             Alert(
                 title: Text("Delete Account?"),
                 message: Text("Are you sure you want to delete your account?"),
                 primaryButton: .destructive(Text("Delete")) {
                     viewModel.deleteAccount { result in
                         switch result {
                         case .success:
                             print("Account deleted successfully.")
                             viewModel.signOut()
                         case .failure(let error):
                             print("Failed to delete account:", error.localizedDescription)
                         }
                     }
                 },
                 secondaryButton: .cancel {
                     // Cancel action (dismiss the alert)
                     print("Delete Account canceled.")
                 }
             )
         }
    }
 
}

struct ToggleButtonView: View {
    @State private var isPublic: Bool = false // State variable for the toggle
    @State private var isLoading: Bool = true // Loading state

    let userId: String

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading...")
            } else {
                Toggle("Public Account", isOn: $isPublic)
                    .toggleStyle(SwitchToggleStyle())
                    .onChange(of: isPublic) { newValue in
                        updatePublicSetting(isPublic: newValue)
                    }
                    .padding()
            }
        }
        .onAppear {
            fetchPublicSetting()
        }
        .padding()
    }

    /// Fetch the public field from Firestore
    private func fetchPublicSetting() {
        let db = Firestore.firestore()
        let settingsRef = db.collection("settings").document(userId)

        settingsRef.getDocument { document, error in
            if let error = error {
                print("Error fetching document: \(error.localizedDescription)")
                isPublic = false
                isLoading = false
                return
            }

            if let document = document, document.exists {
                isPublic = document.get("public") as? Bool ?? false
            } else {
                print("Document does not exist, creating default record.")
                isPublic = false
                // Create a new document with default values
                settingsRef.setData(["public": isPublic]) { error in
                    if let error = error {
                        print("Error creating default document: \(error.localizedDescription)")
                    } else {
                        print("Default document created successfully.")
                    }
                }
            }

            isLoading = false
        }
    }


    /// Update the public field in Firestore
    private func updatePublicSetting(isPublic: Bool) {
        let db = Firestore.firestore()
        let settingsRef = db.collection("settings").document(userId)

        settingsRef.setData(["public": isPublic], merge: true) { error in
            if let error = error {
                print("Error updating document: \(error.localizedDescription)")
            } else {
                print("Public setting updated to \(isPublic).")
            }
        }
    }
}
