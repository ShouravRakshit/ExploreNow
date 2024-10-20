//
//  EventAnnotationView.swift
//  LBTASwiftUIFirebase
//
//  Created by Saadman Rahman on 2024-10-18.
//


/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The annotation view that represents the event.
*/
import MapKit

private let eventClusterID = "eventCluster"

/// - Tag: EventAnnotationView
class EventAnnotationView: MKMarkerAnnotationView {

    static let ReuseID = "eventAnnotation"

    /// - Tag: ClusterIdentifier
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = eventClusterID
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForDisplay() {
        super.prepareForDisplay()
        displayPriority = .defaultHigh
        markerTintColor = UIColor(red: 140/255, green: 82/255, blue: 255/255, alpha: 0.81)
        if let eventImage = UIImage(named: "event") {
            glyphImage = eventImage
        } else {
            print("Warning: 'event' image not found.")
        }
    }
}
