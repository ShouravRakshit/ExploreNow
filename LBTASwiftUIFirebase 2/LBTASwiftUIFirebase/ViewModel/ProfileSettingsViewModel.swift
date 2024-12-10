//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

import Foundation
import Firebase
import SDWebImage

class ProfileSettingsViewModel: ObservableObject {
    @Published var isUploading = false
    @Published var isProfilePictureAvailable = false

    private let appState: AppState
    @Published var userManager: UserManager
    
    init(appState: AppState, userManager: UserManager) {
        self.appState = appState
        self.userManager = userManager
    }
    func fetchProfileData(userManager: UserManager) {
        if let profileImageUrl = userManager.currentUser?.profileImageUrl, !profileImageUrl.isEmpty {
            isProfilePictureAvailable = true
        }
    }

    func uploadProfileImage(image: UIImage?) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid,
              let imageData = image?.jpegData(compressionQuality: 0.5) else { return }

        isUploading = true
        let ref = FirebaseManager.shared.storage.reference(withPath: "profile_images/\(uid)_\(UUID().uuidString).jpg")

        ref.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Failed to upload image: \(error.localizedDescription)")
                self.isUploading = false
                return
            }
            ref.downloadURL { url, error in
                if let error = error {
                    print("Failed to get download URL: \(error.localizedDescription)")
                    self.isUploading = false
                    return
                }
                if let url = url {
                    self.updateUserProfileImageURL(url: url)
                }
            }
        }
    }

    private func updateUserProfileImageURL(url: URL) {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }

        let userData = ["profileImageUrl": url.absoluteString]

        FirebaseManager.shared.firestore.collection("users")
            .document(uid).updateData(userData) { error in
                self.isUploading = false
                if let error = error {
                    print("Failed to update Firestore: \(error.localizedDescription)")
                    return
                }
                print("Successfully updated profile image URL.")
            }
    }

    func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        SDWebImageDownloader.shared.downloadImage(with: url) { image, _, _, _ in
            DispatchQueue.main.async { completion(image) }
        }
    }

    func deleteAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = FirebaseManager.shared.auth.currentUser else {
            completion(.failure(NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found."])))
            return
        }

        user.delete { error in
            if let error = error {
                completion(.failure(error))
                return
            }

            FirebaseManager.shared.firestore.collection("users").document(user.uid).delete { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success(()))
            }
        }
    }

    func signOut() {
        do {
            try FirebaseManager.shared.auth.signOut()
            DispatchQueue.main.async {
                self.appState.isLoggedIn = false
            }
        } catch {
            print("Failed to sign out: \(error.localizedDescription)")
        }
    }
    
    // Function to upload the image to Firebase Storage
    func persistImageToStorage(image: UIImage) {
         isUploading = true // Start loading

         guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
         let uniqueImagePath = "profile_images/\(uid)_\(UUID().uuidString).jpg" // Unique path to prevent caching issues
         let ref = FirebaseManager.shared.storage.reference(withPath: uniqueImagePath)
         guard let imageData = image.jpegData(compressionQuality: 0.5) else { return }

         ref.putData(imageData, metadata: nil) { metadata, err in
             if let err = err {
                 print("Failed to push image to Storage: \(err.localizedDescription)")
                 self.isUploading = false // Stop loading
                 return
             }
             ref.downloadURL { url, err in
                 if let err = err {
                     print("Failed to retrieve downloadURL: \(err.localizedDescription)")
                     self.isUploading = false // Stop loading
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
                self.isUploading = false // Stop loading
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
