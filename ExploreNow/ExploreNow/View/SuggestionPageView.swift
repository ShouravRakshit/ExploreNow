//
//  SuggestionPageView.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

//  When a location is clicked, the location page view for that location
//  can be displayed (similar to how it is displayed in the Explore page),
//  so that the user can view all posts present in that location.

// Unfinished implementation-  What still needs to be done: View all posts present in that location


import SwiftUI
import Combine

struct SuggestionPage: View {
    let city: String // This is the city passed to the view when it is initialized
    @StateObject private var viewModel: SuggestionPageViewModel  // ViewModel that will manage the suggestion page data
    @StateObject private var weatherViewModel = WeatherViewModel() // ViewModel that handles fetching weather data
    
    init(city: String) {
        self.city = city // Initialize the city property
        _viewModel = StateObject(wrappedValue: SuggestionPageViewModel(city: city)) // Initialize the ViewModel with the city
    }
    
    var body: some View {
        VStack { // Vertical stack to arrange UI components
            Text("Welcome to \(viewModel.selectedCity)") // Display the selected city using the ViewModel's city
                .font(.largeTitle) // Set the font size to large
                .padding()  // Add padding around the text
            
            // Conditional rendering of weather details if available
            if let weather = weatherViewModel.weather { // Check if weather data is available
                // Display the temperature value from the weather data
                Text("Temperature: \(weather.main.temp, specifier: "%.1f")°C")
                    .font(.headline) // Set the font to headline style
                    .padding() // Add padding around the temperature text
                
                // Align the icon and condition text on the same baseline
                HStack(alignment: .firstTextBaseline, spacing: 0) { // Use HStack to arrange the elements horizontally with alignment set to firstTextBaseline
                    // Show the weather icon
                    AsyncImage(url: URL(string: "https://openweathermap.org/img/wn/\(weather.weather.first?.icon ?? "01d")@2x.png")) { img in
                        img.resizable()  // Make the image resizable
                            .frame(width: 40, height: 40) // Set the frame of the image to 40x40
                            .alignmentGuide(.firstTextBaseline) { d in d[.bottom] } // Align the image to the bottom of the first text baseline
                    } placeholder: {
                        Color.gray.opacity(0.2) // Show a placeholder with a light gray color while the image is loading
                    }
                    
                    // Show the weather condition text
                    Text(weather.weather.first?.description.capitalized ?? "") // Display the weather description, capitalized. Default to an empty string if unavailable.
                        .font(.subheadline)  // Set the font to subheadline size
                        .padding(.bottom) // Add padding at the bottom to adjust the spacing
                }
            } else {
                // Display a loading message or some placeholder if the weather data is not fetched
                Text("Fetching weather data...")
                    .padding()
            }
            
            // ScrollView containing detailed images
            ScrollView {
                // VStack to arrange the images vertically with spacing between each item
                VStack(spacing: 16) {
                    // Loop through each image URL in the viewModel's detailedImages array
                    ForEach(viewModel.detailedImages, id: \.webformatURL) { image in
                        // Load and display the image asynchronously
                        AsyncImage(url: URL(string: image.webformatURL ?? "")) { img in
                            img.resizable() // Make the image resizable to fill the designated frame
                                .scaledToFill() // Scale the image to fill the frame, potentially clipping the edges
                                .frame(height: 200)  // Set the height of each image to 200
                                .clipped() // Clip the image to fit the frame, cropping if necessary
                        } placeholder: {
                            Color.gray.opacity(0.2) // Display a gray placeholder while the image is loading
                        }
                        .cornerRadius(8) // Apply a corner radius to give the image rounded edges
                    }
                }
            }
        }
        .padding() // Add padding around the ScrollView and VStack
        .onAppear {
            // Fetch weather and images when the view appears
            weatherViewModel.fetchWeather(for: city) // Call the method to fetch the weather data for the city
            viewModel.fetchDetailedImages(for: city) // Call the method to fetch detailed images for the city
        }
    }
}
