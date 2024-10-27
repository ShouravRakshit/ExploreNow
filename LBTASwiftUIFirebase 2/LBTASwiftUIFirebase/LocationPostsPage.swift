//
//  LocationPostsPage.swift
//  LBTASwiftUIFirebase
//
//  Created by Manvi Juneja on 2024-10-27.
//


//
//  LocationPostsPage.swift
//  LBTASwiftUIFirebase
//
//  Created by Manvi Juneja on 2024-10-27.
//


import SwiftUI

struct LocationPostsPage: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header Image with location and rating
            ZStack(alignment: .bottom) {
                Image("banff") // Replace with your actual image
                    .resizable()
                    .scaledToFill()
                    .frame(height: 250)
                    .clipped()
                
                VStack {
                    Text("BANFF")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Text("4.5")
                            .font(.headline)
                            .foregroundColor(.black)
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                    .padding(6)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .shadow(radius: 3)
                }
                .padding(.bottom, 50)
            }

            ScrollView {
                VStack(spacing: 16) {
                    // Sample Post
                    ForEach(1..<6) { index in
                        PostView(userName: "User \(index)", location: "Location", likes: "1.2K", comments: "600")
                    }
                }
                .padding(.top)
            }
            
            Spacer()
        }
        .edgesIgnoringSafeArea(.top)
    }
}

struct PostView: View {
    var userName: String
    var location: String
    var likes: String
    var comments: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top section with user image and username
            HStack(alignment: .center) {
                Image("user_profile") // Replace with actual user image
                    .resizable()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                
                Text("User 1")
                    .font(.custom("Sansation", size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 5)
                    .background(Color(red: 140/255, green: 82/255, blue: 255/255))
                    .cornerRadius(15)
                
                Spacer()
            }
            .padding([.top, .horizontal])
            
            // Placeholder for post image
            Rectangle()
                .fill(Color(red: 217/255, green: 217/255, blue: 217/255))
                .frame(height: 150)
                .padding(.horizontal)
                .padding(.top, 6)
            
            // Bottom section with location, likes, and comments
            HStack {
                Image(systemName: "bubble.right").foregroundColor(Color.customPurple)
                Text("600")
                
                Spacer()
                    HStack(spacing: 10) {  // creating a separate HStack for the heart and location
                        Image(systemName: "heart.fill").foregroundColor(Color.customPurple)
                        Text("1.2k")
                        Image(systemName: "mappin.and.ellipse").foregroundColor(Color.customPurple)
                        Text("Location")
                    }
            }
            .font(.system(size: 14))
            .foregroundColor(.gray)
            .padding(.horizontal)
            .padding(.bottom, 8)
            .padding(.top, 5)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 5)
        
        // adding purple border
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.customPurple, lineWidth: 1))
    }
}

struct LocationPostsPage_Previews: PreviewProvider {
    static var previews: some View {
        LocationPostsPage()
    }
}
