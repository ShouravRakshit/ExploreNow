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
        MapControllerRepresentable()
            .edgesIgnoringSafeArea(.all) // Optional: To make it full screen
    }
}
