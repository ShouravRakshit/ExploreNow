//
//  HelloWorldView.swift
//  LBTASwiftUIFirebase
//
//  Created by AM on 08/10/2024.
//

import SwiftUI

struct HelloWorldView: View {
    var body: some View {
        VStack {
            Text("Hello, World!")
                .font(.largeTitle)
                .padding()
            Spacer()
        }
        .navigationTitle("Hello World")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelloWorldView_Previews: PreviewProvider {
    static var previews: some View {
        HelloWorldView()
    }
}
