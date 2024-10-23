
import MapKit

class Location: NSObject, Decodable, MKAnnotation {
    
    private var latitude: CLLocationDegrees = 0
    private var longitude: CLLocationDegrees = 0
    var name: String
    var rating: Double
    
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
    
    init(name: String, rating: Double, coordinate: CLLocationCoordinate2D) {
        self.name = name
        self.rating = rating

        super.init()
        self.coordinate = coordinate
    }
}
