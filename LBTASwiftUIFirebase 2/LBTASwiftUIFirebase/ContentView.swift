//
//  ContentView.swift
//  LBTASwiftUIFirebase
//
//  Created by Ivan on 2024-10-17.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var userManager: UserManager
    @State private var isActive = true

    var body: some View {
        VStack {
            NavigationView {
                if isActive {
                    SplashScreen(isActive: $isActive)
                } else {
                    Group {
                        if appState.isLoggedIn {
                            // The NavBar and potential MainMessagesView for logged-in users
                            NavBar()
                                .environmentObject(userManager)
                        } else {
                            // Show the login view if not logged in
                            LoginView()
                                .environmentObject(appState)
                                .environmentObject(userManager)
                        }
                    }
                }
            }
        }
        .animation(.easeOut(duration: 0.5), value: isActive)
    }
}

