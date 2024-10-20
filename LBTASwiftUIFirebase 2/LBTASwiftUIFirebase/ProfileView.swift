//
//  ProfileView.swift
//  LBTASwiftUIFirebase
//
//  Created by Ivan on 2024-10-19.
//


import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack {
            Text("Profile Page")
                .font(.largeTitle)
                .padding()

            Spacer()
        }
        .navigationTitle("Profile")
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
