//
//  UserRow.swift
//  LBTASwiftUIFirebase
//
//  Created by Ivan on 2024-11-19.
//

import SwiftUICore
import SDWebImageSwiftUI

struct UserRow: View {
    let user: User
    let isBlocked: Bool

    var body: some View {
        HStack {
            // User profile image
            if let profileImageUrl = user.profileImageUrl, !profileImageUrl.isEmpty {
                WebImage(url: URL(string: profileImageUrl))
                    .resizable()
                    .frame(width: 50, height: 50)
                    .clipped()
                    .cornerRadius(25)
                    .overlay(RoundedRectangle(cornerRadius: 25)
                        .stroke(Color(.label), lineWidth: 2)
                    )
            } else {
                // Placeholder Image
                Image(systemName: "person.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .clipped()
                    .cornerRadius(25)
                    .overlay(RoundedRectangle(cornerRadius: 25)
                        .stroke(Color(.label), lineWidth: 2)
                    )
            }

            VStack(alignment: .leading) {
                Text(user.name)
                    .foregroundColor(Color(.label))
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
    }
}
