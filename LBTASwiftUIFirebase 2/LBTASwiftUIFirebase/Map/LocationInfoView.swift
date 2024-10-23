//
//  LocationInfoView.swift
//  LBTASwiftUIFirebase
//
//  Created by Saadman Rahman on 2024-10-21.
//


import UIKit

class LocationInfoView: UIView {
    private let nameLabel = UILabel()
    private let ratingLabel = UILabel()
    private let coordinatesLabel = UILabel()
    
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
        
        let stackView = UIStackView(arrangedSubviews: [nameLabel, ratingLabel, coordinatesLabel])
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
        coordinatesLabel.text = "Coordinates: \(location.coordinate.latitude), \(location.coordinate.longitude)"
    }
}
