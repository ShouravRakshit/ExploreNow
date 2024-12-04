//
//  SuggestionPageView.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 04/12/2024.
//


import SwiftUI
import Combine

struct SuggestionPage: View {
    let city: String
    @StateObject private var viewModel: SuggestionPageViewModel
    @StateObject private var weatherViewModel = WeatherViewModel()
    
    init(city: String) {
        self.city = city
        _viewModel = StateObject(wrappedValue: SuggestionPageViewModel(city: city)) // Initialize the ViewModel
    }
    
    var body: some View {
        VStack {
            Text("Welcome to \(viewModel.selectedCity)") // Use the ViewModel's city
                .font(.largeTitle)
                .padding()
            
            // Show weather details if fetched
            if let weather = weatherViewModel.weather {
                // Show the temperature
                Text("Temperature: \(weather.main.temp, specifier: "%.1f")°C")
                    .font(.headline)
                    .padding()
                
                // Align the icon and condition text on the same baseline
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    // Show the weather icon
                    AsyncImage(url: URL(string: "https://openweathermap.org/img/wn/\(weather.weather.first?.icon ?? "01d")@2x.png")) { img in
                        img.resizable()
                            .frame(width: 40, height: 40)
                            .alignmentGuide(.firstTextBaseline) { d in d[.bottom] } // Align the image to the bottom
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    
                    // Show the weather condition text
                    Text(weather.weather.first?.description.capitalized ?? "")
                        .font(.subheadline)
                        .padding(.bottom)
                }
            } else {
                // Display a loading message or some placeholder if the weather data is not fetched
                Text("Fetching weather data...")
                    .padding()
            }
            
            // ScrollView containing detailed images
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(viewModel.detailedImages, id: \.webformatURL) { image in
                        AsyncImage(url: URL(string: image.webformatURL ?? "")) { img in
                            img.resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipped()
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .onAppear {
            // Fetch weather and images when the view appears
            weatherViewModel.fetchWeather(for: city)
            viewModel.fetchDetailedImages(for: city)
        }
    }
}
