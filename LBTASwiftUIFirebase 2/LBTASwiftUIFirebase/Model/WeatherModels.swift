//
//  WeatherModels.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 04/12/2024.
//

import SwiftUI

// Define a model to represent weather data
struct Weather1: Codable {
    let main: Main
    let weather: [WeatherDescription]
    
    struct Main: Codable {
        let temp: Double
    }
    
    struct WeatherDescription: Codable {
        let description: String
        let icon: String
    }
}
