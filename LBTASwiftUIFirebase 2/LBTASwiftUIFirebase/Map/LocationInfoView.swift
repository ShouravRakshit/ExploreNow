import UIKit
import MapKit
import SwiftUI
import Firebase
import FirebaseFirestore

class LocationInfoView: UIView {
    private let locationLabel = UILabel() // Combined name and post count
    private let ratingLabel = UILabel()
    private var loadingIndicator: UIActivityIndicatorView?
    private var currentLocation: Location?
    private weak var userManager: UserManager?
    
    init(frame: CGRect, userManager: UserManager) {
        self.userManager = userManager
        super.init(frame: frame)
        setupUI()
        setupGesture()
    }
    
    required init?(coder: NSCoder) {
        self.userManager = nil
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
        
        // Configure labels with improved styling
        locationLabel.font = .systemFont(ofSize: 16, weight: .medium)
        locationLabel.textColor = .black
        locationLabel.numberOfLines = 0
        
        // Create rating container with icon
        let ratingIcon = UIImageView(image: UIImage(systemName: "star.fill"))
        ratingIcon.tintColor = UIColor(red: 140/255, green: 82/255, blue: 255/255, alpha: 1.0)
        ratingIcon.translatesAutoresizingMaskIntoConstraints = false
        ratingIcon.contentMode = .scaleAspectFit
        
        ratingLabel.font = .systemFont(ofSize: 14)
        ratingLabel.textColor = .gray
        
        let ratingStack = UIStackView(arrangedSubviews: [ratingIcon, ratingLabel])
        ratingStack.spacing = 4
        ratingStack.alignment = .center
        
        // Main horizontal stack
        let mainStack = UIStackView(arrangedSubviews: [locationLabel, ratingStack])
        mainStack.axis = .horizontal
        mainStack.spacing = 8
        mainStack.alignment = .center
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(mainStack)
        
        // Create and configure loading indicator
        loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator?.hidesWhenStopped = true
        loadingIndicator?.translatesAutoresizingMaskIntoConstraints = false
        if let loadingIndicator = loadingIndicator {
            addSubview(loadingIndicator)
        }

        // Set up constraints
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            
            ratingIcon.widthAnchor.constraint(equalToConstant: 16),
            ratingIcon.heightAnchor.constraint(equalToConstant: 16),
            
            loadingIndicator!.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator!.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        // Add purple border
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 140/255, green: 82/255, blue: 255/255, alpha: 1.0).cgColor
    }
    
    func configure(with location: Location) {
        self.currentLocation = location
        ratingLabel.text = String(format: "%.1f", location.rating)
        let coordinate = location.coordinate
        getPointOfInterest(for: coordinate)
        fetchPostCount(for: coordinate)
    }
    
    private func updateLocationLabel(name: String, postCount: Int) {
        locationLabel.text = "\(name) (\(postCount))"
    }
    
    private func fetchPostCount(for coordinate: CLLocationCoordinate2D) {
        let db = FirebaseManager.shared.firestore
        db.collection("locations")
            .whereField("location_coordinates", isEqualTo: [coordinate.latitude, coordinate.longitude])
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let locationDoc = snapshot?.documents.first {
                    let locationRef = locationDoc.reference
                    
                    // Fetch posts count for this location
                    db.collection("user_posts")
                        .whereField("locationRef", isEqualTo: locationRef)
                        .getDocuments { snapshot, error in
                            DispatchQueue.main.async {
                                let count = snapshot?.documents.count ?? 0
                                if let currentName = self.locationLabel.text?.components(separatedBy: " (").first {
                                    self.updateLocationLabel(name: currentName, postCount: count)
                                }
                            }
                        }
                }
            }
    }
    
    private func getPointOfInterest(for coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("Reverse geocoding error: \(error.localizedDescription)")
                    self.locationLabel.text = "Location not found"
                    return
                }
                
                if let placemark = placemarks?.first {
                    if let name = placemark.name {
                        self.locationLabel.text = name
                        // Trigger post count fetch after setting the name
                        self.fetchPostCount(for: coordinate)
                    } else if let thoroughfare = placemark.thoroughfare {
                        let locationName = placemark.subThoroughfare.map { "\($0) \(thoroughfare)" } ?? thoroughfare
                        self.locationLabel.text = locationName
                        // Trigger post count fetch after setting the name
                        self.fetchPostCount(for: coordinate)
                    } else {
                        self.locationLabel.text = "Unknown location"
                    }
                } else {
                    self.locationLabel.text = "No location found"
                }
            }
        }
    }

    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.addGestureRecognizer(tapGesture)
        self.isUserInteractionEnabled = true
    }
        
    @objc private func handleTap() {
        guard let location = currentLocation else { return }
        guard let userManager = self.userManager else { // Unwrap userManager
            print("DEBUG: UserManager not available")
            return
        }

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
                            .environmentObject(userManager)
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
