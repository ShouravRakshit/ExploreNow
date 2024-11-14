import Foundation
import SwiftUI
import Firebase
import MapKit



struct hotspots: View {
    @State private var place: String = ""
    @State private var offset: CGFloat = 0
    @State private var searchResults: [Post] = []
    @State private var showSearchResults = false

    
    let destinations = [
        ("Trending", "Trending Destinations"), ("Food", "Food Destinations"), ("Shopping", "Shopping Destinations"), ("Hotel", "Hotels"), ("Attraction", "Attractions"), ("Activities", "Activities")
    ]
    
    let suggestions = [
        ("Jasper", "Jasper, Canada"), ("Banff", "Banff, Canada"), ("Korea", "Seoul, Korea"), ("Paris", "Paris, France"), ("Drumheller", "Drumheller, Canada"), ("Canmore", "Canmore, Canada"), ("Toronto", "Toronto, Canada")
    ]
    
    let gridItems = [GridItem(.flexible()), GridItem(.flexible())]
    
    @State private var isNavigatingToDetailPage: Bool = false
    
    // Helper function to get coordinates based on the image name
    func locationCoordinatesForImage(_ locationName: String) -> [Double] {
        // Define coordinates for each location (latitude, longitude)
        let coordinates: [String: [Double]] = [
            "Jasper": [52.8734, -118.0810],
            "Banff": [51.1784, -115.5708],
            "Seoul": [37.5665, 126.9780],
            "Paris": [48.8566, 2.3522],
            "Drumheller": [51.4658, -112.7101],
            "Canmore": [51.0890, -115.3550],
            "Toronto": [43.65107, -79.347015]
        ]
        
        return coordinates[locationName] ?? [0.0, 0.0] // Default to [0.0, 0.0] if not found
    }

    // Function to handle the tap for suggested locations
    @objc private func handleTap(locationName: String, coordinates: [Double]) {
        guard coordinates.count == 2 else {
               print("Invalid coordinates")
               return
           }
           
           let latitude = coordinates[0]
           let longitude = coordinates[1]
         
         let db = FirebaseManager.shared.firestore
         db.collection("locations")
             .whereField("location_coordinates", isEqualTo: [latitude, longitude])
             .getDocuments { [weak self] snapshot, error in
                 guard let self = self else { return }
                 self.hideLoading()
                 
                 if let error = error {
                     print("Error fetching location: \(error.localizedDescription)")
                     return
                 }
                 
                 if let locationDoc = snapshot?.documents.first {
                     let locationRef = locationDoc.reference
                     let locationPostsPage = UIHostingController(rootView:
                         LocationPostsPage(locationRef: locationRef)
                     )
                     
                     if let parentVC = self.parentViewController {
                         parentVC.present(locationPostsPage, animated: true, completion: nil)
                     } else {
                         print("No parent view controller found!")
                     }
                 } else {
                     print("Location not found in database!")
                 }
             }
     }
    
    
    
    private func performSearch() {
           searchPosts { posts in
               searchResults = posts
               showSearchResults = true
           }
       }

    private func searchPosts() {
        let db = FirebaseManager.shared.firestore
        let keywords = place.split(separator: " ").map { String($0).lowercased() }
        
        db.collection("posts")
            .whereField("description", arrayContainsAny: keywords)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error searching posts: \(error.localizedDescription)")
                    return
                }
                
                guard let snapshot = snapshot else { return }
                var searchResults: [Post] = []
                
                for document in snapshot.documents {
                    let data = document.data()
                    guard let description = data["description"] as? String,
                          let rating = data["rating"] as? Int,
                          let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() else { continue }
                    
                    let post = Post(id: document.documentID, description: description, rating: rating, timestamp: timestamp)
                    searchResults.append(post)
                }
                
                navigateToSearchResultsPage(posts: searchResults)
            }
    }

    private func navigateToSearchResultsPage(posts: [Post]) {
        NavigationLink(destination: ExplorePageSearchResults(posts: posts)) {
            Text("Search Results")
        }
    }


    
    var body: some View {
        ScrollView{
            VStack(alignment: .leading, spacing: 2) {
                Text("WHERE TO?")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(Color(hex: "8C52FF"))
                    .padding(.top, -20)
                    .padding(.leading, 15)
                
                // Displaying search bar
                ZStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color(hex: "8C52FF"))
                            .padding(.leading, 15)
                        
                        TextField("Places, hotels, restaurants, friends", text: $place, onCommit: performSearch)
                            .font(.custom("Sansation", size: 20))
                            .padding(.trailing, 17)
                            .frame(height: 50)
                    }
                    .background(        // Border of the search bar
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(hex: "8C52FF"), lineWidth: 2)
                            .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
                    )
                }
                .padding(.horizontal, 10)
                .padding(.top, 15)
                .padding(.bottom, -13)
                
                // Horizontal scroll of destinaton types
                VStack {
                    HStack {
                        // Photos in the horizontal scroll
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                // Padding for the left most image
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: 5, height: 100)
                                
                                // Displaying the destionation type images
                                ForEach(destinations, id: \.0) { image in
                                    NavigationLink(destination: Text("Detail for \(image.1)")) {
                                        ZStack {
                                            // Displaying image
                                            Image(image.0)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 168, height: 142)
                                                .clipped()
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .overlay(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.3)))

                                            // Displaying text
                                            Text(image.1)
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.white)
                                                .multilineTextAlignment(.leading)
                                                .frame(width: 140, alignment: .leading)
                                                .offset(y: 40)
                                        }
                                    }
                                    .id("item\(String(describing: index))")
                                    .buttonStyle(PlainButtonStyle())
                                }
                                
                                // Padding for the right most image
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: 5, height: 100)
                            }
                            .padding(.leading, -5)
                            .offset(x: -offset)
                        }
                        .frame(width: UIScreen.main.bounds.width * 1)
                    }
                }
                .frame(height: 200)
                .padding(.vertical, 8)
                
                
                Text("You might like")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(Color(hex: "8C52FF"))
                    .padding(.top, -15)
                    .padding(.leading, 10)
                
                
                // Suggested locations view
                VStack{
                    LazyVGrid(columns: gridItems, spacing: 0) {
                        ForEach(suggestions, id: \.0) { image in
                            ZStack(alignment: .bottomLeading) {
                                // Displaying image
                                Image(image.0)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 174, height: 142)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.1)))
                                    .padding(.bottom, 18)
                                
                                //Displaying Text
                                Text(image.1)
                                    .font(.system(size: 25, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .padding(.horizontal, 10)
                                    .frame(width: 163, alignment: .leading)
                                    .padding(.bottom, 20)
                            }
                            .onTapGesture {
                                let locationCoordinates = locationCoordinatesForImage(image.0) // Function to get the coordinates
                                handleTap(locationName: image.0, coordinates: locationCoordinates)
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 22)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .onChange(of: place) { newValue in
                if newValue.isEmpty {
                    isSearching = false
                }
            }
        }
        
    }
}


// The purple color used
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.currentIndex = hex.startIndex
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}
