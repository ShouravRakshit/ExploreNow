
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, Alina Mansuri, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni 

import UIKit
import MapKit
import SwiftUI
import Firebase
import FirebaseFirestore

//this class is the little location information cards that pop up when an annotation or cluster is clicked

class LocationInfoView: UIView {
    private let locationLabel = UILabel()
    private let ratingLabel = UILabel()
    private let postCountLabel = UILabel()
    private var loadingIndicator: UIActivityIndicatorView?
    private var currentLocation: Location?
    private weak var userManager: UserManager?
    
    // MARK: - Custom Colors
    private let primaryPurple = UIColor(red: 140/255, green: 82/255, blue: 255/255, alpha: 1.0)
    private let lightPurple = UIColor(red: 140/255, green: 82/255, blue: 255/255, alpha: 0.1)
    
    // MARK: - Initialization
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
    
    // MARK: - UI Setup
    private func setupUI() {
        // Main Container Setup
        backgroundColor = .white
        layer.cornerRadius = 16
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8
        
        // Location Container
        let locationContainer = UIView()
        locationContainer.backgroundColor = .clear
        locationContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Location Icon
        let locationIcon = UIImageView(image: UIImage(systemName: "mappin.circle.fill"))
        locationIcon.tintColor = primaryPurple
        locationIcon.contentMode = .scaleAspectFit
        locationIcon.translatesAutoresizingMaskIntoConstraints = false
        
        // Location Label Setup
        locationLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        locationLabel.textColor = .black
        locationLabel.numberOfLines = 2
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Post Count Label Setup
        postCountLabel.font = .systemFont(ofSize: 14)
        postCountLabel.textColor = .gray
        postCountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Rating Container
        let ratingContainer = UIView()
        ratingContainer.backgroundColor = lightPurple
        ratingContainer.layer.cornerRadius = 12
        ratingContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Rating Icon
        let ratingIcon = UIImageView(image: UIImage(systemName: "star.fill"))
        ratingIcon.tintColor = .systemYellow
        ratingIcon.contentMode = .scaleAspectFit
        ratingIcon.translatesAutoresizingMaskIntoConstraints = false
        
        // Rating Label Setup
        ratingLabel.font = .systemFont(ofSize: 14, weight: .medium)
        ratingLabel.textColor = primaryPurple
        ratingLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        addSubview(locationContainer)
        locationContainer.addSubview(locationIcon)
        locationContainer.addSubview(locationLabel)
        locationContainer.addSubview(postCountLabel)
        
        addSubview(ratingContainer)
        ratingContainer.addSubview(ratingIcon)
        ratingContainer.addSubview(ratingLabel)
        
        // Loading Indicator Setup
        loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator?.hidesWhenStopped = true
        loadingIndicator?.translatesAutoresizingMaskIntoConstraints = false
        if let loadingIndicator = loadingIndicator {
            addSubview(loadingIndicator)
        }
        
        // Setup Constraints
        NSLayoutConstraint.activate([
            // Location Container
            locationContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            locationContainer.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            locationContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            
            // Location Icon
            locationIcon.leadingAnchor.constraint(equalTo: locationContainer.leadingAnchor),
            locationIcon.centerYAnchor.constraint(equalTo: locationContainer.centerYAnchor),
            locationIcon.widthAnchor.constraint(equalToConstant: 24),
            locationIcon.heightAnchor.constraint(equalToConstant: 24),
            
            // Location Label
            locationLabel.leadingAnchor.constraint(equalTo: locationIcon.trailingAnchor, constant: 8),
            locationLabel.topAnchor.constraint(equalTo: locationContainer.topAnchor),
            
            // Post Count Label
            postCountLabel.leadingAnchor.constraint(equalTo: locationIcon.trailingAnchor, constant: 8),
            postCountLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 2),
            postCountLabel.bottomAnchor.constraint(equalTo: locationContainer.bottomAnchor),
            
            // Rating Container
            ratingContainer.leadingAnchor.constraint(greaterThanOrEqualTo: locationLabel.trailingAnchor, constant: 12),
            ratingContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            ratingContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            ratingContainer.heightAnchor.constraint(equalToConstant: 32),
            
            // Rating Icon
            ratingIcon.leadingAnchor.constraint(equalTo: ratingContainer.leadingAnchor, constant: 12),
            ratingIcon.centerYAnchor.constraint(equalTo: ratingContainer.centerYAnchor),
            ratingIcon.widthAnchor.constraint(equalToConstant: 16),
            ratingIcon.heightAnchor.constraint(equalToConstant: 16),
            
            // Rating Label
            ratingLabel.leadingAnchor.constraint(equalTo: ratingIcon.trailingAnchor, constant: 4),
            ratingLabel.trailingAnchor.constraint(equalTo: ratingContainer.trailingAnchor, constant: -12),
            ratingLabel.centerYAnchor.constraint(equalTo: ratingContainer.centerYAnchor),
            
            // Loading Indicator
            loadingIndicator!.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator!.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    // MARK: - Configuration
    func configure(with location: Location) {
        self.currentLocation = location
        ratingLabel.text = String(format: "%.1f", location.rating)
        let coordinate = location.coordinate
        getPointOfInterest(for: coordinate)
        fetchPostCount(for: coordinate)
    }
    
    private func updateLocationLabel(name: String, postCount: Int) {
        locationLabel.text = name
        postCountLabel.text = "\(postCount) posts"
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
        // Fetch location document to get the address
        let db = FirebaseManager.shared.firestore
        db.collection("locations")
            .whereField("location_coordinates", isEqualTo: [coordinate.latitude, coordinate.longitude])
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error fetching location: \(error.localizedDescription)")
                        self.locationLabel.text = "Location not found"
                        return
                    }
                    
                    if let locationDoc = snapshot?.documents.first,
                       let address = locationDoc.data()["address"] as? String {
                        // Take the address up to the first comma
                        let locationName = address.components(separatedBy: ",")[0].trimmingCharacters(in: .whitespaces)
                        self.locationLabel.text = locationName
                        // Trigger post count fetch after setting the name
                        self.fetchPostCount(for: coordinate)
                    } else {
                        self.locationLabel.text = "Unknown location"
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
