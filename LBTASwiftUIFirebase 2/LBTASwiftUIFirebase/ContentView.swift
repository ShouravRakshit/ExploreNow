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
            if appState.isLoggedIn
                {
                //MainMessagesView()
                //    .environmentObject(appState)
                NavBar ()
                    .environmentObject (userManager)
                }
            else
                {
                LoginView()
                    .environmentObject (appState)
                    .environmentObject (userManager)
                }
        }
    }
}
