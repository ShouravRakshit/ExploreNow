
//
//  ExploreNowApp.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni


import SwiftUI
import FirebaseCore

@main
struct ExploreNow: App {
    // MARK: - State Objects
        
    // AppState manages the overall state of the app, making it accessible across views.
    @StateObject var appState = AppState() // Initialize AppState
    // UserManager handles user-related actions, such as authentication, and is available throughout the app.
    @StateObject private var userManager = UserManager()
    
    // MARK: - Initializer
        
    init() {
        // FirebaseApp.configure() initializes Firebase for the app, enabling the Firebase SDK and services.
        FirebaseApp.configure()
        // Customizing the appearance of the UITabBar globally
        // Changes the background color of the tab bar to a custom color using a hex code.
        UITabBar.appearance().backgroundColor = UIColor(hex: "#8C52FF")
        // Sets the color of unselected tab items to white.
        UITabBar.appearance().unselectedItemTintColor = UIColor.white
    }
    
    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            // The ContentView is the initial view presented when the app is launched.
            ContentView()
            // Injecting appState into the environment, allowing it to be accessed by all child views.
                .environmentObject (appState) // Makes appState available to all child views.
            // Injecting userManager into the environment, providing access to user management features in all views.
                .environmentObject (userManager)
        }
    }
    
    
}
