//
//  SearchUserView.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 03/12/2024.
//

import SwiftUI
import SwiftUI
import SDWebImageSwiftUI

struct SearchUserView: View {
    @StateObject private var viewModel = SearchUserViewModel()
    var didSelectUser: (ChatUser) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar with purple border
            HStack {
                TextField("Search", text: $viewModel.searchQuery)
                    .foregroundColor(.gray)
                    .padding(.leading, 12)
                    .padding(.vertical, 10)
                
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .padding(.trailing, 10)
            }
            .background(Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.customPurple, lineWidth: 1)
            )
            .padding(.horizontal)
            .padding(.bottom, 20)
            
            // Users List
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.filteredUsers) { user in
                        Button(action: {
                            didSelectUser(user)
                        }) {
                            UserRowView(user: user)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            .background(Color(.systemGray6))
        }
        .onChange(of: viewModel.searchQuery) { newValue in
            viewModel.filterUsers(query: newValue)
        }
    }
}
