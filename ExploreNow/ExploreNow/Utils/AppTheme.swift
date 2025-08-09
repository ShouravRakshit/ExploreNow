//
//  AppTheme.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, ---------, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 


import SwiftUI

// The AppTheme struct defines the main colors and utility functions for the app's visual style.
struct AppTheme {
    // Main colors
    // 'primaryPurple' is the main color of the app, using a custom hex value for a vibrant purple color.
    static let primaryPurple = Color(UIColor(hex: "8C52FF") ?? .purple) // Fallback to .purple if hex value is invalid
    
    // Color variations
    // 'lightPurple' is a lighter version of 'primaryPurple', with reduced opacity (10% opacity).
    static let lightPurple = primaryPurple.opacity(0.1)
    
    // 'darkPurple' represents a darker shade of purple for UI elements that need a more subdued or "pressed" appearance.
    static let darkPurple = Color(UIColor(hex: "6B3EC2") ?? .purple)  // Darker shade for pressed states
    
    // Background colors
    // 'background' represents the default background color for views, using system-defined background color for light/dark mode.
    static let background = Color(.systemBackground)
    
    // 'secondaryBackground' is a slightly gray background color, useful for separating sections within views.
    static let secondaryBackground = Color(.systemGray6)
    
    // Text colors
    // 'primaryText' is the default text color for most text elements, using the system-defined label color.
    static let primaryText = Color(.label)
    // 'secondaryText' is a color for secondary or less important text, using the system's secondary label color.
    static let secondaryText = Color(.secondaryLabel)
    
    // Status colors
    // 'success' represents a green color, typically used for success messages or positive feedback.
    static let success = Color.green
    // 'error' represents a red color, commonly used for error messages or warnings.
    static let error = Color.red
    // 'warning' represents a yellow color, commonly used for warnings or caution messages.
    static let warning = Color.yellow
    
    // Utility function to create a gradient background using the primary purple and dark purple colors.
    // The gradient can have customizable start and end points for flexibility.
    static func purpleGradient(startPoint: UnitPoint = .topLeading,
                             endPoint: UnitPoint = .bottomTrailing) -> LinearGradient {
        // The gradient is created using 'primaryPurple' and 'darkPurple' as the two colors.
        LinearGradient(
            gradient: Gradient(colors: [primaryPurple, darkPurple]),
            startPoint: startPoint, // Default to top-left corner as the start point.
            endPoint: endPoint // Default to bottom-right corner as the end point.
        )
    }
}
