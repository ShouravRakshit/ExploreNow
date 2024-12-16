//
//  AppState.swift
//  ExploreNow - CPSC 575
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

// MARK: - AppState Class

// The `AppState` class serves as an observable object that tracks the authentication state of the user.
// It uses the `@Published` property wrapper to notify SwiftUI views whenever the `isLoggedIn` state changes.
// This allows the app to dynamically update its UI based on the user's authentication status.

import SwiftUI
import FirebaseAuth // Import Firebase Authentication to handle user authentication status.

class AppState: ObservableObject {
    // MARK: - Published Properties
        
    // A boolean property that represents whether the user is currently logged in.
    // Changes to this property will automatically notify any SwiftUI views observing this object.
    @Published var isLoggedIn: Bool = false
    
    // MARK: - Initializer
    init() {
        // Check if a user is already authenticated when the app launches.
        // The `Auth.auth().currentUser` property returns the current authenticated user, or `nil` if no user is logged in.
        self.isLoggedIn = Auth.auth().currentUser != nil
    }
}
