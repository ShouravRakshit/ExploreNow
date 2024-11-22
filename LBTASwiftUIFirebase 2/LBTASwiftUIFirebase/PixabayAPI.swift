//
//  PixabayAPI.swift
//  LBTASwiftUIFirebase
//
//  Created by Ivan on 2024-11-21.
//

import Foundation
import Combine

class PixabayAPI {
    static let shared = PixabayAPI()
    private let apiKey = "47197466-e97591543dd5d0d29999d6d75" // Replace with your API key

    private init() {}

    func searchImages(query: String) -> AnyPublisher<[PixabayImage], Error> {
        let urlString = "https://pixabay.com/api/?key=\(apiKey)&q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&image_type=photo"
        
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: PixabayResponse.self, decoder: JSONDecoder())
            .map { $0.hits }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
