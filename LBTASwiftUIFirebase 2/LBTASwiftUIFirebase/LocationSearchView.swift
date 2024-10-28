//
//  LocationSearchView.swift
//  LBTASwiftUIFirebase
//
//  Created by Manvi Juneja on 2024-10-24.
//

import Foundation
import SwiftUI

struct LocationSearchView: View {
    @Binding var selectedLocation: String // Binding to update the selected location
    @Environment(\.presentationMode) var presentationMode // For dismissing the view

    @State private var searchText: String = "" // Search text input
    private var suggestions: [String] { // Filtered suggestions based on search text
        let allLocations = [
            "New York", "Los Angeles", "Chicago", "Houston", "Phoenix",
            "Philadelphia", "San Antonio", "San Diego", "Dallas", "San Jose"
        ]
        return allLocations.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack {
            Spacer()
            Text("Search Location")
                .font(.largeTitle)
                .padding()

            TextField("Type a location...", text: $searchText)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            List(suggestions, id: \.self) { location in
                Button(action: {
                    selectedLocation = location  // Set the selected location
                    presentationMode.wrappedValue.dismiss() // Close the pop-up
                }) {
                    Text(location)
                }
            }
        }
        .padding()
        
        Spacer()
        
    }
}

// Preview for testing
struct LocationSearchView_Previews: PreviewProvider {
    static var previews: some View {
        LocationSearchView(selectedLocation: .constant(""))
    }
}
