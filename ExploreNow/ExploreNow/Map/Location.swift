
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, -------------, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, ----------, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni

import MapKit

//simple location class to denote/store locations info
class Location: NSObject, Decodable, MKAnnotation {
    
    // Private variables to store latitude and longitude as separate values
    private var latitude: CLLocationDegrees = 0
    private var longitude: CLLocationDegrees = 0
    
    // Public properties for the location's name and rating
    var name: String
    var rating: Double
    
    // Computed property to return and set the location's coordinates
    @objc dynamic var coordinate: CLLocationCoordinate2D {
        get {
            // Return CLLocationCoordinate2D object using stored latitude and longitude
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        set {
            // Set latitude and longitude from the new CLLocationCoordinate2D value
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }
    
    // Designated initializer for the class
    init(name: String, rating: Double, coordinate: CLLocationCoordinate2D) {
        self.name = name
        self.rating = rating

        // Call the superclass initializer
        super.init()
        self.coordinate = coordinate
    }
}
