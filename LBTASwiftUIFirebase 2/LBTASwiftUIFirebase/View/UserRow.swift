//
//  UserRow.swift
//  LBTASwiftUIFirebase
//
//  Created by Ivan on 2024-11-19.
//

import SwiftUI
import SDWebImageSwiftUI

struct UserRow: View {
    let user: User
    let isBlocked: Bool

    var body: some View {
        NavigationLink(destination: ProfileView(user_uid: user.uid)) {
            HStack {
                // User profile image
                if let profileImageUrl = user.profileImageUrl, !profileImageUrl.isEmpty {
                    WebImage(url: URL(string: profileImageUrl))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipped()
                        .cornerRadius(25)
                        .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color(.label), lineWidth: 2))
                } else {
                    // Placeholder Image
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipped()
                        .cornerRadius(25)
                        .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color(.label), lineWidth: 2))
                }

                VStack(alignment: .leading) {
                    Text(user.name)
                        .foregroundColor(Color(.label))
                        .font(.system(size: 16, weight: .bold))
                    Text("@\(user.username)")
                        .foregroundColor(.gray)
                        .font(.system(size: 12))
                }

                Spacer()

                if isBlocked {
                    Text("Blocked")
                        .foregroundColor(.red)
                        .padding(.trailing)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .contentShape(Rectangle()) // Ensures the entire HStack is tappable
        }
        .buttonStyle(PlainButtonStyle()) // Disables default button styling to make it look like a list item
    }
}

