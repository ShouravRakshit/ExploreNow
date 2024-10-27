//
//  LocationInfoView.swift
//  LBTASwiftUIFirebase
//
//  Created by Saadman Rahman on 2024-10-21.
//

import UIKit
import MapKit
import SwiftUI

class LocationInfoView: UIView {
//    private let nameLabel = UILabel()
    private let ratingLabel = UILabel()
    private let poiLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGesture()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupGesture()
    }
    
    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 4
        
        let stackView = UIStackView(arrangedSubviews: [poiLabel, ratingLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create a rectangle as the background of the card
        let cardBackground = UIView()
        cardBackground.backgroundColor = UIColor(hex: "#D9D9D9")
        cardBackground.layer.cornerRadius = 12
        
        addSubview(cardBackground)
        cardBackground.translatesAutoresizingMaskIntoConstraints = false
        
        // Add stack view to the card background
        cardBackground.addSubview(stackView)

        // Set up constraints
        NSLayoutConstraint.activate([
            cardBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardBackground.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardBackground.topAnchor.constraint(equalTo: topAnchor),
            cardBackground.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            stackView.leadingAnchor.constraint(equalTo: cardBackground.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: cardBackground.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: cardBackground.topAnchor, constant: 16),
            stackView.bottomAnchor.constraint(equalTo: cardBackground.bottomAnchor, constant: -16),
        ])
        
        // Add a border around the card
        cardBackground.layer.borderColor = Color.customPurple.cgColor
        cardBackground.layer.borderWidth = 1
    }
    
    private func setupGesture() {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            self.addGestureRecognizer(tapGesture)
            self.isUserInteractionEnabled = true // Enable user interaction for this view
        }
        
        @objc private func handleTap() {
            print("Card tapped!") // Debug print
            if poiLabel.text == "224 Banff Ave" {
                let locationPostsPage = UIHostingController(rootView: LocationPostsPage())
                    if let parentVC = self.parentViewController {
                        parentVC.present(locationPostsPage, animated: true, completion: nil)
                    } else {
                        print("No parent view controller found!")
                    }
            } else {
                print("Location is not Banff!") // Debug print
            }
        }
    
    func configure(with location: Location) {
//        nameLabel.text = location.name
        ratingLabel.text = "Rating: \(location.rating)"
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

// Helper to find the parent view controller
extension UIView {
    var parentViewController: UIViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            responder = responder?.next
            if let viewController = responder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}
