//
//  WeatherViewModel.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

import Foundation
import Combine

// ViewModel to fetch weather data
class WeatherViewModel: ObservableObject {
    static let shared = WeatherViewModel()
    @Published var weather: Weather1?

    private let apiKey: String = {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
              let key = dict["WEATHER_API_KEY"] as? String
        else {
            fatalError("Couldn't find API Key in Secrets.plist")
        }
        return key
    }()

    init() {}

    // Function to fetch weather data
    func fetchWeather(for city: String) {
        let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(city)&appid=\(apiKey)&units=metric" // Modify the URL to match OpenWeatherMap API format
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching weather data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            do {
                let weatherData = try JSONDecoder().decode(Weather1.self, from: data)
                DispatchQueue.main.async {
                    self.weather = weatherData
                }
            } catch {
                print("Error decoding weather data: \(error)")
            }
        }

        task.resume()
    }
}

