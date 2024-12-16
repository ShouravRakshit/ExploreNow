//
//  SuggestProfilePicViewModel.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import SDWebImage

// ViewModel responsible for handling the profile picture upload, image downloading,
// and updating user profile information in Firestore.
class SuggestProfilePicViewModel: ObservableObject {
    // The user-selected image to be set as the profile picture.
    @Published var image: UIImage?
    
    // Indicates whether the app is currently uploading the profile image to Firebase Storage.
    @Published var isUploading = false
    
    // Holds messages related to the status of operations, e.g., error messages.
    @Published var statusMessage = ""
    
    // Downloads an image from a given URL using SDWebImageDownloader.

    func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        SDWebImageDownloader.shared.downloadImage(with: url) { image, data, error, finished in
            if let image = image, finished {
                // If the image is successfully downloaded and the download finished,
                // return it via the completion handler.
                DispatchQueue.main.async {
                    completion(image)
                }
            } else {
                // If there's an error, print it and return nil.
                print("Failed to download image: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
            }
        }
    }
    
    // Persists the currently selected `image` to Firebase Storage and updates Firestore user profile URL.
    
    func persistImageToStorage(appState: AppState, userManager: UserManager) {
        self.isUploading = true // Begin upload indicator
        
        // Ensure that we have a current user ID.
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        // Create a unique path in Firebase Storage for the user's profile image.
        let uniqueImagePath = "profile_images/\(uid)_\(UUID().uuidString).jpg"
        let ref = FirebaseManager.shared.storage.reference(withPath: uniqueImagePath)
        
        // Convert the selected UIImage to JPEG data with reasonable compression.
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else { return }

        // Upload the image data to Firebase Storage.
        ref.putData(imageData, metadata: nil) { metadata, err in
            if let err = err {
                // If there's an error during upload, print it and stop the loading indicator.
                print("Failed to push image to Storage: \(err.localizedDescription)")
                self.isUploading = false
                return
            }
            
            // Once uploaded, retrieve the download URL for the newly stored image.
            ref.downloadURL { url, err in
                if let err = err {
                    // If getting the download URL fails, print the error and stop loading.
                    print("Failed to retrieve downloadURL: \(err.localizedDescription)")
                    self.isUploading = false
                    return
                }
                // If success, proceed to store the URL in Firestore.
                guard let url = url else { return }
                print("New profileImageUrl: \(url.absoluteString)")
                self.storeUserInformation(imageProfileUrl: url, appState: appState, userManager: userManager)
            }
        }
    }

    // Updates the Firestore user document with the new profile image URL.
    private func storeUserInformation(imageProfileUrl: URL, appState: AppState, userManager: UserManager) {
        // Ensure we have a current user ID.
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        // Prepare the data payload with the new profile image URL.
        let userData = ["profileImageUrl": imageProfileUrl.absoluteString]
        
        // Update the Firestore document for the current user with the new profile image URL.
        FirebaseManager.shared.firestore.collection("users")
            .document(uid).updateData(userData) { err in
                if let err = err {
                    // If there's an error, store it in statusMessage and return.
                    print(err)
                    self.statusMessage = "\(err.localizedDescription)"
                    return
                }
                // If successful, print a message and update app state and user info.
                print("Profile image URL successfully stored.")
                DispatchQueue.main.async {
                    // Set the app as logged in and fetch the updated user data.
                    appState.isLoggedIn = true
                    userManager.fetchCurrentUser()
                }
            }
    }
}
