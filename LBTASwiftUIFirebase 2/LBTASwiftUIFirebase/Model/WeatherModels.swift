//
//  WeatherModels.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 04/12/2024.
//

import Foundation

struct WeatherResponse: Codable {
    let main: Main
    let weather: [Weather]
}

struct Main: Codable {
    let temp: Double
    let humidity: Double
}

struct Weather: Codable {
    let description: String
    let icon: String
}
