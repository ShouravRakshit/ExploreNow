//
//  AppTheme.swift
//  LBTASwiftUIFirebase
//
//  Created by Saadman Rahman on 2024-11-21.
//


import SwiftUI

struct AppTheme {
    // Main colors
    static let primaryPurple = Color(UIColor(hex: "8C52FF") ?? .purple) // 140, 82, 255
    
    // Color variations
    static let lightPurple = primaryPurple.opacity(0.1)
    static let darkPurple = Color(UIColor(hex: "6B3EC2") ?? .purple)  // Darker shade for pressed states
    
    // Background colors
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.systemGray6)
    
    // Text colors
    static let primaryText = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    
    // Status colors
    static let success = Color.green
    static let error = Color.red
    static let warning = Color.yellow
    
    // Utility function to create gradient
    static func purpleGradient(startPoint: UnitPoint = .topLeading, 
                             endPoint: UnitPoint = .bottomTrailing) -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [primaryPurple, darkPurple]),
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
}
