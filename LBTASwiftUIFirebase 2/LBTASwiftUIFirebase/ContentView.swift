//
//  ContentView.swift
//  LBTASwiftUIFirebase
//
//  Created by Ivan on 2024-10-17.
//

import SwiftUI

struct ContentView: View {
//    @EnvironmentObject var appState: AppState

    var body: some View {
//        Group {
//            if appState.isLoggedIn {
//                MainMessagesView()
//                    .environmentObject(appState)
//            } else {
//                LoginView()
//                    .environmentObject(appState)
//            }
//        }
        MapViewControllerWrapper()
            .edgesIgnoringSafeArea(.all)
    }
}

struct MapViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MapController {
        return MapController() // Initialize the view controller
    }

    func updateUIViewController(_ uiViewController: MapController, context: Context) {
        // No update needed in this example
    }
}
