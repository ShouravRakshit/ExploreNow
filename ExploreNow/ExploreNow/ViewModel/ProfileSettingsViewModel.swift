//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, --------, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

import Foundation
import Firebase
import SDWebImage

// ViewModel class responsible for managing the profile settings state and logic
class ProfileSettingsViewModel: ObservableObject {
    
    // Published properties to allow UI binding and state updates
    @Published var isUploading = false // Tracks if a profile picture is being uploaded
    @Published var isProfilePictureAvailable = false // Tracks whether the user has a profile picture
    
    // Private property to hold the application's global state
    private let appState: AppState
    
    // Published user manager to observe and update the user's data
    @Published var userManager: UserManager
    
    // Initializer to set up the ViewModel with the app's global state and user manager
    init(appState: AppState, userManager: UserManager) {
        self.appState = appState // Assign appState to the private property
        self.userManager = userManager // Assign userManager to the published property
    }
    // Method to fetch the user's profile data and check if the profile picture is available
    func fetchProfileData(userManager: UserManager) {
        // Check if the current user has a profile image URL and if it's not empty
        if let profileImageUrl = userManager.currentUser?.profileImageUrl, !profileImageUrl.isEmpty {
            // If the profile image URL is valid, update the profile picture status
            isProfilePictureAvailable = true
        }
    }

    // Function to upload a profile image to Firebase Storage
    func uploadProfileImage(image: UIImage?) {
        // Ensure the current user is authenticated and the image is not nil
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid,
              let imageData = image?.jpegData(compressionQuality: 0.5) else {
                  // If either condition fails, exit the function early
                  return
              }

        // Set the `isUploading` flag to true, indicating an upload is in progress
        isUploading = true
        // Create a reference for the image in Firebase Storage with a unique file path using the user's UID and a new UUID
        let ref = FirebaseManager.shared.storage.reference(withPath: "profile_images/\(uid)_\(UUID().uuidString).jpg")

        // Upload the image data to Firebase Storage
        ref.putData(imageData, metadata: nil) { _, error in
            // If there's an error during the upload, print the error and stop the upload process
            if let error = error {
                print("Failed to upload image: \(error.localizedDescription)")
                self.isUploading = false // Stop the upload process
                return
            }
            
            // If the image upload is successful, attempt to retrieve the download URL
            ref.downloadURL { url, error in
                // If there's an error retrieving the download URL, print the error and stop the upload process
                if let error = error {
                    print("Failed to get download URL: \(error.localizedDescription)")
                    self.isUploading = false // Stop the upload process
                    return
                }
                // If the URL is successfully retrieved, update the user's profile image URL
                if let url = url {
                    self.updateUserProfileImageURL(url: url)
                }
            }
        }
    }

    // Private function to update the user's profile image URL in Firestore
    private func updateUserProfileImageURL(url: URL) {
        // Ensure the current user is authenticated and has a valid UID
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }

        // Create a dictionary containing the profile image URL as a string
        let userData = ["profileImageUrl": url.absoluteString]

        // Access the Firestore database and reference the current user's document
        FirebaseManager.shared.firestore.collection("users")
            .document(uid).updateData(userData) { error in
                // Set the uploading flag to false after the update is complete
                self.isUploading = false
                // Set the uploading flag to false after the update is complete
                if let error = error {
                    print("Failed to update Firestore: \(error.localizedDescription)")
                    return
                }
                // If the update is successful, print a success message
                print("Successfully updated profile image URL.")
            }
    }

    // Function to download an image from a URL and return it through the completion handler
    func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        // Use SDWebImageDownloader to download the image from the provided URL
        SDWebImageDownloader.shared.downloadImage(with: url) { image, _, _, _ in
            // Once the image is downloaded, pass the image to the completion handler on the main thread
            DispatchQueue.main.async { completion(image) }
        }
    }

    // Function to delete a user's account, calling completion with the result
    func deleteAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        // Ensure the current user is authenticated
        guard let user = FirebaseManager.shared.auth.currentUser else {
            // If no user is found, return an error with a "User not found" message
            completion(.failure(NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found."])))
            return
        }

        // Delete the user's authentication account and associated Firestore data
        user.delete { error in
            // Check if there is an error during the deletion of the user's account
            if let error = error {
                // If there's an error, return a failure result with the error
                completion(.failure(error))
                return
            }

            // If account deletion was successful, proceed to delete the user's data from Firestore
            FirebaseManager.shared.firestore.collection("users").document(user.uid).delete { error in
                // Check if there was an error while deleting the user's data from Firestore
                if let error = error {
                    // If there's an error during the Firestore deletion, return a failure result with the error
                    completion(.failure(error))
                    return
                }
                // If both the account and Firestore data are deleted successfully, return a success result
                completion(.success(()))
            }
        }
    }

    // This function is used to sign out the current authenticated user from Firebase.
    func signOut() {
        do {
            // Attempt to sign out the user using Firebase Authentication
            try FirebaseManager.shared.auth.signOut()
            // If sign out is successful, update the app's logged-in state on the main thread
            DispatchQueue.main.async {
                self.appState.isLoggedIn = false
            }
        } catch {
            // If there is an error during sign-out, print the error's localized description
            print("Failed to sign out: \(error.localizedDescription)")
        }
    }
    
    // Function to upload the image to Firebase Storage
    func persistImageToStorage(image: UIImage) {
        // Indicate that an image upload operation is in progress by setting isUploading to true
         isUploading = true

        // Retrieve the current authenticated user's unique ID (uid)
         guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        // Construct a unique image path for storing the profile image
        // This helps to prevent caching or overwriting issues by appending a unique UUID to the filename
         let uniqueImagePath = "profile_images/\(uid)_\(UUID().uuidString).jpg"
        // Get a reference to Firebase Storage using the unique path
         let ref = FirebaseManager.shared.storage.reference(withPath: uniqueImagePath)
        // Convert the UIImage to JPEG data with 50% compression quality
         guard let imageData = image.jpegData(compressionQuality: 0.5) else { return }

        // Upload the image data to Firebase Storage at the specified reference
         ref.putData(imageData, metadata: nil) { metadata, err in
             // Handle any error that occurs during the image upload process
             if let err = err {
                 print("Failed to push image to Storage: \(err.localizedDescription)")
                 self.isUploading = false // Stop loading since the upload failed
                 return
             }
             
        // If the upload is successful, attempt to retrieve the download URL for the uploaded image
             ref.downloadURL { url, err in
                 // Handle any error that occurs while fetching the download URL
                 if let err = err {
                     print("Failed to retrieve downloadURL: \(err.localizedDescription)")
                     self.isUploading = false // Stop loading if there's an error
                     return
                 }
                 
                 // Ensure the download URL is valid
                 guard let url = url else { return }
                 // Log the new profile image URL for debugging purposes
                 print("New profileImageUrl: \(url.absoluteString)")
                 // Store the URL in the user’s profile information (e.g., Firestore or Realtime Database)
                 self.storeUserInformation(imageProfileUrl: url)
             }
         }
     }
    
    // Function to update the user's profileImageUrl in Firestore
    private func storeUserInformation(imageProfileUrl: URL) {
        // Retrieve the current user's unique identifier (UID) from Firebase Authentication
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        // Prepare the data to be updated in Firestore, in this case, the profile image URL
        let userData = ["profileImageUrl": imageProfileUrl.absoluteString]

        // Access the "users" collection in Firestore and update the document for the current user (identified by UID)
        FirebaseManager.shared.firestore.collection("users")
            .document(uid).updateData(userData) { err in
                // Stop the loading indication once the update operation is complete
                self.isUploading = false
                
                // Handle potential errors during the update operation
                if let err = err {
                    // If there is an error, print the error message and exit the function
                    print("Failed to update user data: \(err.localizedDescription)")
                    return
                }
                // If the update is successful, print a success message for debugging
                print("Profile image URL successfully updated.")
                
                // Optionally, refresh the current user data to ensure the userManager has the most up-to-date information
                // The fetchCurrentUser method might re-fetch the user's details from Firestore
                self.userManager.fetchCurrentUser()
            }
    }
}
