//
//  PixabayAPI.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 


import Foundation
import Combine

class PixabayAPI: ObservableObject {
    static let shared = PixabayAPI()
        
        private let apiKey: String = {
            guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
                  let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
                  let key = dict["PIXABAY_API_KEY"] as? String
            else {
                fatalError("Couldn't find API Key in Secrets.plist")
            }
            return key
        }()

    init() {}

    func searchImages(query: String) -> AnyPublisher<[PixabayImage], Error> {
        let urlString = "https://pixabay.com/api/?key=\(apiKey)&q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&image_type=photo"

        
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL))
                .eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: url)
            .map { data, response in
                print("URL String: \(urlString)")
                    return data
            }
            .decode(type: PixabayResponse.self, decoder: JSONDecoder())
            .map { $0.hits }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
