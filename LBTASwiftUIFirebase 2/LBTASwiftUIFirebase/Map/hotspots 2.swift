import Foundation
import SwiftUI



struct hotspots: View {
    @State private var place: String = ""
    @State private var offset: CGFloat = 0

    
    let destinations = [
        ("Trending", "Trending Destinations"), ("Food", "Food Destinations"), ("Shopping", "Shopping Destinations"), ("Hotel", "Hotels"), ("Attraction", "Attractions"), ("Activities", "Activities")
    ]
    
    let suggestions = [
        ("Jasper", "Jasper, Canada"), ("Banff", "Banff, Canada"), ("Korea", "Seoul, Korea"), ("Paris", "Paris, France"), ("Drumheller", "Drumheller, Canada"), ("Canmore", "Canmore, Canada"), ("Toronto", "Toronto, Canada")
    ]
    
    let gridItems = [GridItem(.flexible()), GridItem(.flexible())]
    
    @State private var isNavigatingToDetailPage: Bool = false
    
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
                        
                        TextField("Places, hotels, restaurants, friends", text: $place)
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
                            NavigationLink(destination: LocationPage(locationName: image.0)) {
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
                            
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                }
                .padding(.horizontal, 10)
                .padding(.top, 22)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .topLeading)
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
