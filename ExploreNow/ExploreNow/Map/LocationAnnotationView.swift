//
//  EventAnnotationView.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, --------, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni


/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The annotation view that represents the event.
*/
import MapKit

private let locationClusterID = "locationCluster"  // Identifier for clustering events

/// - Tag: EventAnnotationView
class LocationAnnotationView: MKMarkerAnnotationView {

    static let ReuseID = "locationAnnotation" // Reuse identifier for marker annotation views

    /// - Tag: ClusterIdentifier
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = locationClusterID // Assign clustering identifier for MapKit clustering
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented") // Required initializer for NSCoder, but not used here
    }
    
    override func prepareForDisplay() {
        super.prepareForDisplay()
        displayPriority = .defaultHigh  // Sets a higher priority for displaying this annotation view
        markerTintColor = UIColor(red: 140/255, green: 82/255, blue: 255/255, alpha: 0.81)  // Custom color for the marker
        if let eventImage = UIImage(named: "event") {
            glyphImage = eventImage // Sets a custom image for the marker glyph (event image)
        }
    }
}
