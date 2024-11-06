//
//  HomeViewTest.swift
//  LBTASwiftUIFirebase
//
//  Created by Alisha Lalani on 2024-10-21.
//

import SwiftUI

struct HomeViewTest: View {
    @EnvironmentObject var userManager: UserManager
    @State private var hasNotifications = false // Toggle this state to test notification statuses
    @State private var navigateToNotifications = false

    var body: some View {
        ZStack {
            // Your main content (e.g., Home Page content)
            VStack {
                Spacer()
                Text("Home View")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            
            // Notification icon in the top right
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        // Action when the notification icon is tapped
                        print("Notification icon tapped!")
                        navigateToNotifications = true
                        // Add your navigation or action here
                    }) {
                        ZStack {
                            // The bell icon
                            Image(systemName: "bell.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(Color(red: 140/255, green: 82/255, blue: 255/255)) // Bell color

                            // The red dot for new notifications
                            if hasNotifications {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 10, height: 10)
                                    .offset(x: 10, y: -10) // Position the red dot
                            }
                        }
                        .padding (.top, 50)
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 16) // Adjust padding as needed
                }
                Spacer()
            }
        }
        .edgesIgnoringSafeArea(.top) // To avoid clipping at the top edge of the screen
        .fullScreenCover(isPresented: $navigateToNotifications) {
            NotificationView()
                .environmentObject(userManager)
        }
    }
    
}

struct HomeViewTest_Preview: PreviewProvider
    {
    static var previews: some View
        {
        HomeViewTest()
        }
    }



