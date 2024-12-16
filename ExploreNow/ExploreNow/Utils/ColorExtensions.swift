//
//  ColorExtensions.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

import UIKit

// MARK: - UIColor Extension for Hex Initialization
extension UIColor {
    /// Convenience initializer for creating a UIColor instance from a hex string.
       /// The hex string can be in either RGB (3 characters) or RRGGBB (6 characters) format.
       ///
       /// - Parameter hex: A string representing a color in hexadecimal format.
       ///                  The string can optionally start with a "#" symbol.
       /// - Returns: An optional UIColor object initialized with the provided hex color.
       ///           Returns nil if the hex format is invalid.
    convenience init?(hex: String) {
        // Variables to store red, green, and blue values as CGFloat
        let r, g, b: CGFloat

        // Remove any whitespaces or newline characters from the hex string
        var hexColor = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        // Remove the "#" character if present (common in hex color codes)
        hexColor = hexColor.replacingOccurrences(of: "#", with: "")
        // Variable to hold the integer representation of the hex string
        var rgb: UInt64 = 0
        // Use Scanner to convert the hex string to a numeric value
        Scanner(string: hexColor).scanHexInt64(&rgb)

        // Handle two possible valid hex string formats:
        switch hexColor.count {
        case 3: // RGB format (e.g., "#RGB")
            // Extract red, green, and blue components from the 3-character hex string
            r = CGFloat((rgb >> 16) & 0xFF) / 255.0  // Red value is in the top 4 bits
            g = CGFloat((rgb >> 8) & 0xFF) / 255.0 // Green value is in the middle 4 bits
            b = CGFloat(rgb & 0xFF) / 255.0     // Blue value is in the bottom 4 bits
        case 6: // RRGGBB format (e.g., "#RRGGBB")
            // Extract red, green, and blue components from the 6-character hex string
            r = CGFloat((rgb >> 16) & 0xFF) / 255.0 // Red value in the top 8 bits
            g = CGFloat((rgb >> 8) & 0xFF) / 255.0  // Green value in the middle 8 bits
            b = CGFloat(rgb & 0xFF) / 255.0  // Blue value in the bottom 8 bits
        default:
            // Return nil if the hex string is not in a valid format (neither 3 nor 6 characters)
            return nil
        }
        // Initialize UIColor with the extracted RGB values and set alpha to 1 (fully opaque)
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

