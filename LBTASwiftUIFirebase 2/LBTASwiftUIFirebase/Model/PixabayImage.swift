//
//  PixabayImage.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

import Foundation

// MARK: - PixabayResponse
// A structure representing the response from the Pixabay API. It contains metadata
// about the search results including total number of results, total hits, and the list of image data.
struct PixabayResponse: Codable {
    let total: Int               // Total number of images available for the search query.
    let totalHits: Int           // The total number of hits (results) returned for the search query.
    let hits: [PixabayImage]     // An array of `PixabayImage` objects containing the image details.
}

// MARK: - PixabayImage
// A structure representing an individual image from the Pixabay API response.
// It includes properties for various image URLs, metadata, and user information.
struct PixabayImage: Codable, Identifiable {
    let id: Int                  // Unique identifier for the image.
    let pageURL: String?         // URL to the image's page on Pixabay.
    let type: String?            // Type of image (e.g., photo, illustration, etc.).
    let tags: String?            // Tags associated with the image (e.g., nature, sunset, etc.).
    let previewURL: String?      // URL for the preview image.
    let previewWidth: Int?       // Width of the preview image.
    let previewHeight: Int?      // Height of the preview image.
    let webformatURL: String?    // URL for the web format version of the image.
    let webformatWidth: Int?     // Width of the web format image.
    let webformatHeight: Int?    // Height of the web format image.
    let largeImageURL: String?   // URL for the large version of the image.
    let imageWidth: Int?         // Width of the full image.
    let imageHeight: Int?        // Height of the full image.
    let imageSize: Int?          // Size of the full image in bytes.
    let views: Int?              // Number of views the image has received.
    let downloads: Int?          // Number of times the image has been downloaded.
    let likes: Int?              // Number of likes the image has received.
    let comments: Int?           // Number of comments the image has received.
    let user_id: Int?            // Unique identifier for the user who uploaded the image.
    let user: String?            // The name of the user who uploaded the image.
    let userImageURL: String?    // URL to the user's profile image.
}
