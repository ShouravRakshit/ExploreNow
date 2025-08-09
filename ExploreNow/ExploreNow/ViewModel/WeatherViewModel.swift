//
//  WeatherViewModel.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, -----------, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

// MARK: - WeatherViewModel

// The `WeatherViewModel` class is a shared, observable object that acts as a ViewModel to fetch and manage weather data.
// It conforms to the `ObservableObject` protocol, making it suitable for integration with SwiftUI to dynamically update the UI with weather information.

import Foundation
import Combine

// ViewModel to fetch weather data
class WeatherViewModel: ObservableObject {
    // MARK: - Singleton Instance
       
    // A shared instance of the `WeatherViewModel`, allowing for a centralized data source across the app.
    static let shared = WeatherViewModel()
    
    // MARK: - Published Properties
       
    // A published property to store the weather data.
    // Updates to this property will automatically notify SwiftUI views observing the `WeatherViewModel`.
    @Published var weather: Weather1?

    // MARK: - API Key
       
    // The API key for accessing the OpenWeatherMap API is securely fetched from the `Secrets.plist` file.
    // This ensures that sensitive information is not hardcoded in the source code.
    private let apiKey: String = {
        // Fetch the path for the `Secrets.plist` file in the app bundle.
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
              let key = dict["WEATHER_API_KEY"] as? String
        else {
            // If the key is not found, terminate the app with an error message.
            fatalError("Couldn't find API Key in Secrets.plist")
        }
        return key
    }()

    // MARK: - Initializer
        
    // Empty initializer for the ViewModel.
    // Using the shared instance is encouraged for consistent and centralized access.
    init() {}

    // MARK: - Fetch Weather Data
        
    // A function to fetch weather data for a given city from the OpenWeatherMap API.
    func fetchWeather(for city: String) {
        // Construct the API URL, including the city name, API key, and units set to metric.
        let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(city)&appid=\(apiKey)&units=metric"
        
        // Validate the URL string and ensure it is a valid URL.
        guard let url = URL(string: urlString) else {
            print("Invalid URL") // Log an error if the URL is invalid.
            return
        }
        
        // Log an error if the URL is invalid.
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            // Handle errors or missing data.
            guard let data = data, error == nil else {
                print("Error fetching weather data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            do {
                // Attempt to decode the JSON response into the `Weather1` model.
                let weatherData = try JSONDecoder().decode(Weather1.self, from: data)
                
                // Update the `weather` property on the main thread to reflect the new data in the UI.
                DispatchQueue.main.async {
                    self.weather = weatherData
                }
            } catch {
                // Log decoding errors for debugging purposes.
                print("Error decoding weather data: \(error)")
            }
        }

        // Start the data task.
        task.resume()
    }
}

