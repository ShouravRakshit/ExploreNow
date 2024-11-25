//
//  HotspotsPage.swift
//  LBTASwiftUIFirebase
//
//  Created by Manvi Juneja on 2024-11-24.
//

import Foundation
import SwiftUI



struct Hotspots: View {
    @State private var place: String = ""
    @State private var offset: CGFloat = 0
    
    @State private var displayedSuggestions: [(String, String)] = []
    @State private var currentPage: Int = 0
    @State private var isLoading: Bool = false

    
    let suggestions = [
        ("Jasper", "Jasper, Canada"), ("Banff", "Banff, Canada"), ("Korea", "Seoul, Korea"), ("Paris", "Paris, France"), ("Drumheller", "Drumheller, Canada"), ("Canmore", "Canmore, Canada"), ("Toronto", "Toronto, Canada"), ("Calgary", "Calgary, Canada"), ("Japan", "Kyoto, Japan"), ("Italy", "Venice, Italy")
    ]
    
    let gridItems = [GridItem(.flexible()), GridItem(.flexible())]
    
    
    func loadMoreSuggestions() {
        guard !isLoading else { return } // Prevent loading if already fetching
        
        isLoading = true
        
        // Simulate delay for loading more items (replace with network call)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let startIndex = currentPage * 6
            let endIndex = min((currentPage + 1) * 6, suggestions.count)
            
            if startIndex < suggestions.count {
                let newSuggestions = Array(suggestions[startIndex..<endIndex])
                displayedSuggestions.append(contentsOf: newSuggestions)
                currentPage += 1
            }
            
            isLoading = false
        }
    }

        
    var body: some View {
        ScrollView{
            VStack(alignment: .leading, spacing: 2) {
                Text("TRENDING")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(Color(hex: "8C52FF"))
                    //.padding(.top, -60)
                    .padding(.leading, 2)
                
                
                // Suggested locations view
                VStack{
                    LazyVGrid(columns: gridItems, spacing: 0) {
                        ForEach(displayedSuggestions, id: \.0) { image in
                            NavigationLink(destination: SuggestionPage(suggestionName: image.1)) {
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
                            .onAppear {
                                if let lastItem = displayedSuggestions.last, image == lastItem {
                                    loadMoreSuggestions()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, -5)
                .padding(.top, 1)
                .onAppear{
                    loadMoreSuggestions()
                }
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


// Displays lcoation suggestion posts
struct SuggestionPage: View {
    let suggestionName: String
    
    var body: some View {
        VStack {
            Text("Welcome to \(suggestionName)")
                .font(.largeTitle)
                .padding()
            
        }
        .navigationTitle(suggestionName)
    }
}
