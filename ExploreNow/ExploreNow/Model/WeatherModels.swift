//
//  WeatherModels.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni


import SwiftUI

// Define a model to represent weather data
struct Weather1: Codable {
    // This struct represents the overall weather data and conforms to Codable to allow easy
    // encoding and decoding from JSON or other data formats.

    let main: Main           // Main weather data like temperature.
    let weather: [WeatherDescription] // List of weather conditions (e.g., rain, sunny, etc.)
    
    // MARK: - Nested Structures
    // The `Weather1` struct includes two nested structs to represent the weather data more granularly.

    // Main weather data (like temperature, pressure, etc.)
    struct Main: Codable {
        let temp: Double  // Temperature in Kelvin (or another unit depending on the API).
    }
    
    // Weather conditions, such as the description (e.g., "clear sky") and the icon used for UI.
    struct WeatherDescription: Codable {
        let description: String // A human-readable description of the weather (e.g., "clear sky").
        let icon: String        // A reference to an icon, typically used for displaying weather icons in the UI.
    }
}

