//
//  ClusterAnnotationView.swift
//  LBTASwiftUIFirebase
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The annotation view representing a cluster of event annotations.
*/
import MapKit

/// - Tag: ClusterAnnotationView
// This class represents a custom annotation view used for clustering annotations on
class ClusterAnnotationView: MKAnnotationView {
    
    // Custom initializer to set up the annotation view's properties.
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        // Setting the collision mode to circle, which determines how the annotation view interacts with other views during animation or collision detection.
        collisionMode = .circle
        
        // Setting the center offset of the annotation view. This moves the annotation's center point vertically upwards by 10 points.
        // This can help make the annotation appear more visually centered or improve animation when clustering markers.
        centerOffset = CGPoint(x: 0, y: -10) // Offset for better animation with marker annotations
    }

    // Required initializer for decoding, but it's not implemented because it's not needed for this specific use case.
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// - Tag: CustomCluster
    // This function is called when the annotation view is about to be displayed on the map.
    override func prepareForDisplay() {
        
        // Call the superclass's implementation of prepareForDisplay to ensure any default behavior is applied.
        super.prepareForDisplay()
        
        // Check if the annotation is of type MKClusterAnnotation. This is used for cluster annotations,
           // where multiple annotations are grouped together in one cluster on the map.
        if let cluster = annotation as? MKClusterAnnotation {
            // Retrieve the count of member annotations (i.e., the number of locations in this cluster).
            let totalLocations = cluster.memberAnnotations.count
            
            // Call the custom method `drawCluster(count:)` to generate an image based on the number of locations.
            // The image is then set for the annotation view, representing how the cluster should be displayed.
            image = drawCluster(count: totalLocations)
            
            // Set the display priority to `.defaultHigh`, which determines the relative priority for rendering the annotation.
            // A higher priority can ensure the cluster annotation is drawn on top of others.
            displayPriority = .defaultHigh
        }
    }

    private func drawCluster(count: Int) -> UIImage {
        
        // Step 1: Set up a graphics renderer for creating a custom image with size 40x40 points
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 40))
        
        // Step 2: Generate the image by drawing the required elements (circle, text) on it
        return renderer.image { _ in
            // Step 3: Fill the outer circle with a custom purple color (using RGBA values)
            UIColor(red: 140/255, green: 82/255, blue: 255/255, alpha: 0.81).setFill()
            UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 40, height: 40)).fill()

            // Step 4: Draw an inner white circle in the center
            UIColor.white.setFill()
            UIBezierPath(ovalIn: CGRect(x: 8, y: 8, width: 24, height: 24)).fill()

            // Step 5: Draw the count (number of locations) in the center of the circle
            let attributes = [NSAttributedString.Key.foregroundColor: UIColor.black,
                              NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20)]
            let text = "\(count)" // The count of locations to be displayed
            let size = text.size(withAttributes: attributes)  // Calculate the size of the text
            let rect = CGRect(x: 20 - size.width / 2, // Center the text horizontally
                              y: 20 - size.height / 2, // Center the text vertically
                              width: size.width,
                              height: size.height)
            
            // Step 6: Draw the text in the calculated rectangle
            text.draw(in: rect, withAttributes: attributes)
        }
    }
}

