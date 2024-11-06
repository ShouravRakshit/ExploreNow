import UIKit
import MapKit
import SwiftUI
import Firebase
import FirebaseFirestore

class LocationInfoView: UIView {
    private let ratingLabel = UILabel()
    private let poiLabel = UILabel()
    private var loadingIndicator: UIActivityIndicatorView?
    private var currentLocation: Location? // Add this to store the location

    
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
        
        // Configure labels
        poiLabel.font = .systemFont(ofSize: 16, weight: .medium)
        poiLabel.textColor = .black
        ratingLabel.font = .systemFont(ofSize: 14)
        ratingLabel.textColor = .gray
        
        let stackView = UIStackView(arrangedSubviews: [poiLabel, ratingLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create a rectangle as the background of the card
        let cardBackground = UIView()
        cardBackground.backgroundColor = UIColor(red: 217/255, green: 217/255, blue: 217/255, alpha: 1.0)
        cardBackground.layer.cornerRadius = 12
        
        addSubview(cardBackground)
        cardBackground.translatesAutoresizingMaskIntoConstraints = false
        
        // Add stack view to the card background
        cardBackground.addSubview(stackView)
        
        // Create and configure loading indicator
        loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator?.hidesWhenStopped = true
        loadingIndicator?.translatesAutoresizingMaskIntoConstraints = false
        if let loadingIndicator = loadingIndicator {
            cardBackground.addSubview(loadingIndicator)
        }

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
            
            loadingIndicator!.centerXAnchor.constraint(equalTo: cardBackground.centerXAnchor),
            loadingIndicator!.centerYAnchor.constraint(equalTo: cardBackground.centerYAnchor)
        ])
        
        // Add a border around the card
        cardBackground.layer.borderColor = UIColor(red: 140/255, green: 82/255, blue: 255/255, alpha: 1.0).cgColor
        cardBackground.layer.borderWidth = 1
    }
    
    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.addGestureRecognizer(tapGesture)
        self.isUserInteractionEnabled = true
    }
        
    @objc private func handleTap() {
        guard let location = currentLocation else { return }
        showLoading()
        
        let db = FirebaseManager.shared.firestore
        db.collection("locations")
            .whereField("location_coordinates", isEqualTo: [location.coordinate.latitude, location.coordinate.longitude])
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.hideLoading()
                
                if let error = error {
                    print("Error fetching location: \(error.localizedDescription)")
                    return
                }
                
                if let locationDoc = snapshot?.documents.first {
                    let locationRef = locationDoc.reference
                    let locationPostsPage = UIHostingController(rootView:
                        LocationPostsPage(locationRef: locationRef)
                        // Removed .environmentObject(UserManager.shared)
                    )
                    
                    if let parentVC = self.parentViewController {
                        parentVC.present(locationPostsPage, animated: true, completion: nil)
                    } else {
                        print("No parent view controller found!")
                    }
                } else {
                    print("Location not found in database!")
                }
            }
    }

    private func showLoading() {
        if loadingIndicator == nil {
            loadingIndicator = UIActivityIndicatorView(style: .medium)
            loadingIndicator?.translatesAutoresizingMaskIntoConstraints = false
            addSubview(loadingIndicator!)
            
            NSLayoutConstraint.activate([
                loadingIndicator!.centerXAnchor.constraint(equalTo: centerXAnchor),
                loadingIndicator!.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        }
        loadingIndicator?.startAnimating()
        isUserInteractionEnabled = false
    }
    
    private func hideLoading() {
        loadingIndicator?.stopAnimating()
        isUserInteractionEnabled = true
    }

    func configure(with location: Location) {
        self.currentLocation = location // Store the location
        ratingLabel.text = "Rating: \(location.rating)"
        let coordinate = location.coordinate
        getPointOfInterest(for: coordinate)
    }

    private func getPointOfInterest(for coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("Reverse geocoding error: \(error.localizedDescription)")
                    self.poiLabel.text = "Location not found"
                    return
                }
                
                if let placemark = placemarks?.first {
                    // Try to get the most specific address component available
                    if let name = placemark.name {
                        self.poiLabel.text = name
                    } else if let thoroughfare = placemark.thoroughfare {
                        if let subThoroughfare = placemark.subThoroughfare {
                            self.poiLabel.text = "\(subThoroughfare) \(thoroughfare)"
                        } else {
                            self.poiLabel.text = thoroughfare
                        }
                    } else {
                        self.poiLabel.text = "Unknown location"
                    }
                } else {
                    self.poiLabel.text = "No location found"
                }
            }
        }
    }
}

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
