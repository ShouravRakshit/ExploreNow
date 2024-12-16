//
//  PixabayAPI.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni


import Foundation
import Combine

// MARK: - PixabayAPI: ObservableObject
/// A class to handle interactions with the Pixabay API, enabling image search functionality.
/// It uses Combine framework to provide reactive data flow.
class PixabayAPI: ObservableObject {
    // MARK: - Singleton Instance
    /// A singleton instance of PixabayAPI to ensure there's only one shared instance of the class.
    static let shared = PixabayAPI()
    // MARK: - Private API Key Handling
        private let apiKey: String = {
            // Fetch the API key from a Secrets.plist file stored in the app's bundle
            guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
                  let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
                  let key = dict["PIXABAY_API_KEY"] as? String
            else {
                // Fatal error if the API key cannot be found
                fatalError("Couldn't find API Key in Secrets.plist")
            }
            // Return the API key
            return key
        }()

    // MARK: - Initialization
    /// The initializer for the PixabayAPI class.
    init() {}

    // MARK: - Image Search Functionality
    /// A function to search for images on Pixabay based on a query string.
    ///
    /// - Parameter query: A search term string to find relevant images.
    /// - Returns: A Combine publisher that emits an array of `PixabayImage` objects when the data is successfully fetched and decoded.
    func searchImages(query: String) -> AnyPublisher<[PixabayImage], Error> {
        // Construct the URL for the Pixabay API endpoint, including the query and API key.
        let urlString = "https://pixabay.com/api/?key=\(apiKey)&q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&image_type=photo"

        // Ensure the URL string is valid and create a URL object
        guard let url = URL(string: urlString) else {
            // If the URL creation fails, return a failed publisher
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }

        // Perform a network request using Combine's `dataTaskPublisher` to fetch data from the API
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { data, response in
                // Print the full URL string for debugging purposes
                print("URL String: \(urlString)")
                    return data
            }
        // Decode the response into a `PixabayResponse` object
            .decode(type: PixabayResponse.self, decoder: JSONDecoder())
            .map { $0.hits } // Extract the list of `PixabayImage` from the response
            .receive(on: DispatchQueue.main)  // Ensure the response is received on the main thread (UI updates)
            .eraseToAnyPublisher() // Return an AnyPublisher to allow downstream consumers to handle the result
    }
}
