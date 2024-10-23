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

    var body: some View {
        Group {
            if appState.isLoggedIn {
                // The NavBar and potential MainMessagesView for logged-in users
                NavBar()
                    .environmentObject(userManager)
                // You can choose to uncomment or modify MainMessagesView later
                // MainMessagesView()
                // .environmentObject(appState)
                
            } else {
                // Show the login view if not logged in
                LoginView()
                    .environmentObject(appState)
                    .environmentObject(userManager)
            }
           
        }
    }
}


