//
//  FirebaseManager.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

import Foundation
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

// MARK: - FirebaseManager Class
/// A singleton class to manage Firebase services (Auth, Firestore, Storage).
/// This class is designed to centralize access to Firebase functionalities, including authentication, file storage, and Firestore operations.
class FirebaseManager: NSObject {
    // MARK: - Properties
    /// Firebase Authentication instance, used for managing user authentication.
    let auth: Auth
    /// Firebase Storage instance, used for storing and retrieving files.
    let storage: Storage
    /// Firebase Firestore instance, used for interacting with Firestore database.
    let firestore: Firestore
    // MARK: - Singleton Instance
    /// A shared instance of FirebaseManager for easy access throughout the app.
    static let shared = FirebaseManager()
    
    // MARK: - Initialization
    /// The initializer for the FirebaseManager class, responsible for configuring the Firebase services.
    override init() {
        //FirebaseApp.configure()
        
        self.auth = Auth.auth() // Initialize the Firebase Auth service
        self.storage = Storage.storage() // Initialize the Firebase Storage service
        self.firestore = Firestore.firestore() // Initialize the Firebase Firestore service
        
        super.init()
    }
    
    // MARK: - Reauthentication Method
    /// Re-authenticate the currently logged-in user using their email and password.
    /// This is typically used when changing sensitive information, like email or password.
    ///
    /// - Parameters:
    ///   - currentPassword: The current password of the user, needed for re-authentication.
    ///   - completion: A closure that returns a Boolean indicating whether re-authentication was successful.
    func reauthenticateUser(currentPassword: String, completion: @escaping (Bool) -> Void) {
        guard let user = auth.currentUser else {
            // If there's no current user, return false in the completion closure.
            completion(false)
            return
        }
        
        // Create a credential object using the current email and password.
        let credential = EmailAuthProvider.credential(withEmail: user.email!, password: currentPassword)
        // Attempt to re-authenticate the user using the provided credentials.
        user.reauthenticate(with: credential) { result, error in
            if let error = error {
                // If re-authentication fails, print the error and return false.
                print("Reauthentication failed: \(error.localizedDescription)")
                completion(false)
                return
            }
            // If re-authentication is successful, return true.
            completion(true)
        }
    }
    
    // MARK: - Change Password Method
    /// Updates the current user's password with the new provided password.
    /// This method is typically used when the user wants to change their password in their profile settings.
    ///
    /// - Parameters:
    ///   - newPassword: The new password the user wants to set.
    ///   - completion: A closure that returns a Boolean indicating whether the password update was successful.
    func changePassword(newPassword: String, completion: @escaping (Bool) -> Void) {
        // Ensure there is a currently authenticated user
        guard let user = auth.currentUser else {
            // If no user is logged in, return false in the completion handler.
            completion(false)
            return
        }
        
        // Attempt to update the user's password with the provided new password
        user.updatePassword(to: newPassword) { error in
            if let error = error {
                // If there was an error updating the password, print the error and return false.
                print("Password update failed: \(error.localizedDescription)")
                completion(false)
                return
            }
            // If the password update is successful, return true.
            completion(true)
        }
    }
    
}

