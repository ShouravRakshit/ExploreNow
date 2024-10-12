//  GradientBackground.swift
//  project
//  Completed by Qusai Dahodwalla, Shourav Rakshit Ivan, Manvi Juneja, Alisha Lalani, Alina Mansuri, Zaid Nissar, Shree Patel, Saadman Rahman, Vidhi Soni

import SwiftUI

struct GradientBackground: View {
    var body: some View {
        LinearGradient(gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.0, blue: 0.4), // Deep purple for the top
                    Color(red: 0.9, green: 0.7, blue: 1.0), // Lighter pinkish color for the middle
                    Color(red: 1.0, green: 0.8, blue: 0.8), // Even lighter, almost pastel-like, for the center
                    Color(red: 0.2, green: 0.0, blue: 0.4), // Deep purple
                    Color(red: 0.1, green: 0.1, blue: 0.1)  // Dark gray/black background for the very bottom
                    
                ]), startPoint: .topLeading, endPoint: .bottomTrailing)
            .edgesIgnoringSafeArea(.all)
    }
}