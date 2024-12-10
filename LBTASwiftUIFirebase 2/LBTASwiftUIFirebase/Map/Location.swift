
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

import MapKit

//simple location class to denote/store locations info
class Location: NSObject, Decodable, MKAnnotation {
    
    private var latitude: CLLocationDegrees = 0
    private var longitude: CLLocationDegrees = 0
    var name: String
    var rating: Double
    
    @objc dynamic var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }
    
    init(name: String, rating: Double, coordinate: CLLocationCoordinate2D) {
        self.name = name
        self.rating = rating

        super.init()
        self.coordinate = coordinate
    }
}
