//
//  EventAnnotationView.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni


/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The annotation view that represents the event.
*/
import MapKit

private let locationClusterID = "locationCluster"

/// - Tag: EventAnnotationView
class LocationAnnotationView: MKMarkerAnnotationView {

    static let ReuseID = "locationAnnotation"

    /// - Tag: ClusterIdentifier
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = locationClusterID
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
        }
    }
}
