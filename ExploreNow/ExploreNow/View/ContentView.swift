//
//  ContentView.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

import SwiftUI

// Main view of the app, responsible for managing app state and navigating between views base
struct ContentView: View {
    // Injected environment objects for app state and user management.
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var userManager: UserManager
    
    // Local state variable to manage whether the splash screen is active or not.
    @State private var isActive = true

    var body: some View {
        VStack {
            // A NavigationStack is used to enable navigation between views in the app.
            NavigationStack {
                // Conditionally displaying the SplashScreen or the main app content based on the isActive flag.
                if isActive {
                // Show the splash screen initially. The isActive flag is bound to control visibility.
                    SplashScreen(isActive: $isActive)
                } else {
                    // The main content for logged-in users if the appState indicates they are logged in.
                    Group {
                        // Conditional rendering based on the app's login state.
                        if appState.isLoggedIn {
                            //NavigationStack {
                            // The NavBar and potential MainMessagesView are shown if the user is logged in.
                                NavBar()
                                    .environmentObject(userManager)  // Passing the userManager to NavBar for managing user-related tasks
                           // }
                        } else {
                            // If the user is not logged in, show the LoginView.
                            LoginView()
                                .environmentObject(appState) // Passing appState to LoginView to manage login state
                                .environmentObject(userManager) // Passing userManager to LoginView to manage user-related actions
                        }
                    }
                }
            }
        }
        .animation(.easeOut(duration: 0.5), value: isActive) // Apply an ease-out animation lasting 0.5 seconds when `isActive` changes
    }
}

