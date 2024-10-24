//
//  LocationInfoView.swift
//  LBTASwiftUIFirebase
//
//  Created by Saadman Rahman on 2024-10-21.
//


import UIKit
import MapKit

class LocationInfoView: UIView {
    private let nameLabel = UILabel()
    private let ratingLabel = UILabel()
//    private let coordinatesLabel = UILabel()
    private let poiLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = UIColor.white.withAlphaComponent(0.9)
        layer.cornerRadius = 10
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 4
        
        let stackView = UIStackView(arrangedSubviews: [nameLabel, ratingLabel, poiLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
        ])
    }
    
    func configure(with location: Location) {
        nameLabel.text = location.name
        ratingLabel.text = "Rating: \(location.rating)"
//        coordinatesLabel.text = "Coordinates: \(location.coordinate.latitude), \(location.coordinate.longitude)"
        let coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        getPointOfInterest(for: coordinate)
    }
    
    private func getPointOfInterest(for coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            if let error = error {
                print("Reverse geocoding error: \(error.localizedDescription)")
                self.poiLabel.text = "Location not found"
                return
            }

            if let placemark = placemarks?.first {
                // Display the point of interest or the address
                let poi = placemark.name ?? "Unknown location"
                self.poiLabel.text = poi
            } else {
                self.poiLabel.text = "No POI found"
            }
        }
    }
}
