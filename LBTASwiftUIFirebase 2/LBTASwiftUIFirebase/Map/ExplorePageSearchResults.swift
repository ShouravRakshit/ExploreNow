//
//  ExplorePageSearchResults.swift
//  hotspots
//
//  Created by Shree Patel on 2024-11-13.
//

import Foundation
import SwiftUI



struct ExplorePageSearchResults: View {
    var posts: [Post]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(posts) { post in
                    PostCard(post: post)
                        .padding(.horizontal)
                }
            }
            .padding(.top)
        }
        .navigationTitle("Search Results")
    }
}

struct PostCard: View {
    let post: Post
    @State private var currentImageIndex = 0
    
    var body: some View {
        NavigationLink(destination: PostView(post: post)) {
            VStack(alignment: .leading, spacing: 8) {
                // User info header
                HStack {
                    if let imageUrl = URL(string: post.userProfileImageUrl) {
                        WebImage(url: imageUrl)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)
                            .clipShape(Circle())
                    }
                    
                    Text(post.username)
                        .font(.headline)
                        .foregroundColor(.blue)  // Custom color for username
                    
                    Spacer()
                    
                    Text(formatDate(post.timestamp))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Post images
                if !post.imageUrls.isEmpty {
                    TabView(selection: $currentImageIndex) {
                        ForEach(post.imageUrls.indices, id: \.self) { index in
                            if let imageUrl = URL(string: post.imageUrls[index]) {
                                WebImage(url: imageUrl)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 300)
                                    .clipped()
                                    .tag(index)
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .frame(height: 300)
                    .cornerRadius(12)
                }
                
                // Post description
                Text(post.description)
                    .font(.body)
                
                // Interaction buttons (Likes and Comments)
                HStack {
                    Button(action: {
                        // Like action
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.blue)
                            Text("1.2k")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Comment action
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.right.fill")
                                .foregroundColor(.blue)
                            Text("600")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    // Location and rating
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.blue)
                        Text(post.locationAddress)
                            .font(.subheadline)
                            .lineLimit(1)
                        
                        Image(systemName: "star.fill")
                            .foregroundColor(.blue)
                        Text("\(post.rating)")
                            .font(.subheadline)
                    }
                    .foregroundColor(.gray)
                }
                .font(.subheadline)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(radius: 5)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

