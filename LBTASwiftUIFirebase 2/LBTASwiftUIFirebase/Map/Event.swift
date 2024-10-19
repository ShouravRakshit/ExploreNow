//
//  EventLocation.swift
//  LBTASwiftUIFirebase
//
//  Created by Saadman Rahman on 2024-10-18.
//


//import SwiftUI
//import MapKit
//
//struct EventLocation: Identifiable {
////    let id = UUID()
//    let coordinate: CLLocationCoordinate2D
//}
//
//class EventAnnotation: NSObject, MKAnnotation {
//    let coordinate: CLLocationCoordinate2D
//    
//    init(coordinate: CLLocationCoordinate2D) {
//        self.coordinate = coordinate
//    }
//}

import MapKit

class Event: NSObject, Decodable, MKAnnotation {
    
    private var latitude: CLLocationDegrees = 0
    private var longitude: CLLocationDegrees = 0
    
    // This property must be key-value observable, which the `@objc dynamic` attributes provide.
    @objc dynamic var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        set {
            // For most uses, `coordinate` can be a standard property declaration without the customized getter and setter shown here.
            // The custom getter and setter are needed in this case because of how it loads data from the `Decodable` protocol.
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }
    
    init(coordinate: CLLocationCoordinate2D) {
        super.init()
        self.coordinate = coordinate
    }
}
