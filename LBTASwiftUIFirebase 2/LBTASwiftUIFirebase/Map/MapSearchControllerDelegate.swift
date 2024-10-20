//
//  MapSearchControllerDelegate.swift
//  LBTASwiftUIFirebase
//
//  Created by Saadman Rahman on 2024-10-20.
//


import MapKit
import UIKit

protocol MapSearchControllerDelegate: AnyObject {
    func didSelectSearchResult(_ coordinate: CLLocationCoordinate2D)
}

class MapSearchController: NSObject, UISearchBarDelegate {

    private let mapView: MKMapView
    weak var delegate: MapSearchControllerDelegate?

    init(mapView: MKMapView) {
        self.mapView = mapView
    }

    // MARK: - UISearchBarDelegate
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text, !searchText.isEmpty else { return }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText

        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            guard let response = response, error == nil, let self = self else { return }

            if let mapItem = response.mapItems.first {
                let coordinate = mapItem.placemark.coordinate
                self.delegate?.didSelectSearchResult(coordinate)
                searchBar.resignFirstResponder()
            }
        }
    }
}
