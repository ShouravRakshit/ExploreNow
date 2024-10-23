//
//  MapControllerRepresentable.swift
//  LBTASwiftUIFirebase
//
//  Created by Saadman Rahman on 2024-10-19.
//


import SwiftUI
import MapKit

struct MapControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MapController {
        return MapController() // Return an instance of your MapController
    }

    func updateUIViewController(_ uiViewController: MapController, context: Context) {
        // Update the view controller if needed
    }
}
