//
//  SplashScreen.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, --------, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 


import SwiftUI

// SplashScreen view that takes a binding to control its visibility
struct SplashScreen: View {
    @Binding var isActive: Bool // Binding to control the visibility of the splash screen

    @State private var airplaneOffset = -UIScreen.main.bounds.width // Initial off-screen position for the airplane image
    @State private var cloudOffset = UIScreen.main.bounds.width  // Initial off-screen position for the cloud

    var body: some View {
        ZStack {
//            LinearGradient(gradient: Gradient(colors: [Color.customPurple, Color(UIColor(hex: "#483D8B") ?? .purple)]), startPoint: .bottom, endPoint: .top)
//                            .edgesIgnoringSafeArea(.all)

            // Background gradient: A radial gradient with custom colors for a smooth transition effect
            RadialGradient(gradient: Gradient(colors: [Color.customPurple, Color(UIColor(hex: "#4B0082")?.withAlphaComponent(0.8) ?? .purple)]), center: .center, startRadius: 50, endRadius: UIScreen.main.bounds.height)
                            .edgesIgnoringSafeArea(.all) // Make the gradient background extend to the edges of the screen

            // Airplane icon (using SF Symbols) to create the moving animation
            Image(systemName: "airplane")
                .font(.system(size: 100)) // Set the size of the airplane icon
                .foregroundColor(.white) // Set the airplane color to white for visibility
                .offset(x: airplaneOffset, y: -100) // Apply an offset to position the airplane off-screen initially
                .onAppear {
                    // Start the airplane animation when the view appears
                    withAnimation(Animation.linear(duration: 5.0)) {
                        self.airplaneOffset = UIScreen.main.bounds.width  // Move the airplane across the screen over 5 seconds
                    }
                }

            Image(systemName: "cloud.fill") // Cloud image
                .font(.system(size: 100)) // Set the font size
                .foregroundColor(.white) // Set the color to white
                .offset(x: cloudOffset, y: 50) // Offset for animation effect
                .onAppear {  // Trigger when the view appears
                    withAnimation(Animation.linear(duration: 5.0)) { // Linear animation over 5 seconds
                        self.cloudOffset = -UIScreen.main.bounds.width  // Move cloud off-screen
                    }
                }

            Image(systemName: "moon.stars.fill")  // Moon with stars image
                .font(.system(size: 150)) // Set the font size
                .foregroundColor(.yellow) // Set the color to yellow
                .offset(x: 100, y: -UIScreen.main.bounds.height / 3) // Position the moon image

            VStack { // Vertical stack to hold the title
                Spacer() // Push content to the bottom
                Text("ExploreNow")  // Display the "ExploreNow" text
                    .font(.system(size: 40)) // Set the font size
                    .fontWeight(.bold) // Make the font bold
                    .foregroundColor(.white) // Set the text color to white
                    .padding(.bottom, 100)  // Add space at the bottom
            }
        }
        .onAppear { // Trigger when the view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { // Set a delay of 5 seconds
                self.isActive = false // After 5 seconds, change the 'isActive' state to false
            }
        }
    }
}
