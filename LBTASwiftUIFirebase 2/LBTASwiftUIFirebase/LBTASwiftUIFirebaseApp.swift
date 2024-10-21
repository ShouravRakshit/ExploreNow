//
//  LBTASwiftUIFirebaseApp.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 06/10/2024.
//


import SwiftUI
import FirebaseCore

@main
struct LBTASwiftUIFirebaseApp: App {
    
    @StateObject var appState = AppState() // Initialize AppState
    
    init() {
        FirebaseApp.configure() // Configuring Firebase here
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState) // Makes appState available to all child views.
        }
    }
}
