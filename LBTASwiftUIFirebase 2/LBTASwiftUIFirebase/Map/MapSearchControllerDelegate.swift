//
//  MapSearchControllerDelegate.swift
//  LBTASwiftUIFirebase
//
//  Created by Saadman Rahman on 2024-10-20.
//


import MapKit
import UIKit

protocol MapSearchControllerDelegate: AnyObject {
    func didSelectSearchResult(region: MKCoordinateRegion)
    func didStartSearch()
    func didEndSearch()
}

// all about search functionality

class MapSearchController: NSObject, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, MKLocalSearchCompleterDelegate {
    private let mapView: MKMapView
    private weak var searchBar: UISearchBar?
    weak var delegate: MapSearchControllerDelegate?
    private var searchCompleter: MKLocalSearchCompleter
    private var searchResults: [MKLocalSearchCompletion] = []
    
    private lazy var suggestionsTableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "SuggestionCell")
        table.isHidden = true
        table.layer.cornerRadius = 8
        table.backgroundColor = .systemBackground
        table.layer.masksToBounds = true
        table.layer.borderWidth = 1
        table.layer.borderColor = UIColor.systemGray5.cgColor
        return table
    }()

    init(mapView: MKMapView, searchBar: UISearchBar) {
        self.mapView = mapView
        self.searchBar = searchBar
        self.searchCompleter = MKLocalSearchCompleter()
        super.init()
        
        searchBar.tintColor = .systemBlue
        searchBar.searchTextField.tintColor = .systemBlue 

        
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.pointOfInterest, .address, .query]
        setupSuggestionsTableView()
    }
    
    private func setupSuggestionsTableView() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            suggestionsTableView.translatesAutoresizingMaskIntoConstraints = false
            window.addSubview(suggestionsTableView)
        }
    } 
    
    // MARK: - UISearchBarDelegate
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        delegate?.didStartSearch()
        updateSuggestionsTableFrame(searchBar)
        suggestionsTableView.isHidden = false
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            searchResults.removeAll()
            suggestionsTableView.isHidden = true
            return
        }
        
        searchCompleter.queryFragment = searchText
        suggestionsTableView.isHidden = false
        updateSuggestionsTableFrame(searchBar)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        suggestionsTableView.isHidden = true
        delegate?.didEndSearch()
    }
    
    private func updateSuggestionsTableFrame(_ searchBar: UISearchBar) {
        guard let searchBarFrame = searchBar.superview?.convert(searchBar.frame, to: nil) else { return }
        
        suggestionsTableView.frame = CGRect(
            x: searchBarFrame.origin.x,
            y: searchBarFrame.maxY + 8,
            width: searchBarFrame.width,
            height: min(CGFloat(searchResults.count * 44), 220) // Maximum height of 220 points
        )
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SuggestionCell", for: indexPath)
        let result = searchResults[indexPath.row]
        
        cell.textLabel?.text = result.title + ", " + result.subtitle
//        cell.detailTextLabel?.text = result.subtitle
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
//        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
//        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.backgroundColor = .clear
        print(result.title)
        print(result.subtitle)
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let completion = searchResults[indexPath.row]
        
        searchBar?.text = completion.title
        
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { [weak self] (response, error) in
            guard let self = self,
                  let mapItem = response?.mapItems.first else { return }
            
            let region = MKCoordinateRegion(
                center: mapItem.placemark.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
            
            self.delegate?.didSelectSearchResult(region: region)
            self.suggestionsTableView.isHidden = true
        }
    }
    
    // MARK: - MKLocalSearchCompleterDelegate
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        suggestionsTableView.reloadData()
        
        if let searchBar = completer.delegate as? UISearchBar {
            updateSuggestionsTableFrame(searchBar)
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error)")
    }
    
    func hideSuggestions() {
        suggestionsTableView.isHidden = true
        searchBar?.resignFirstResponder()
    }
}
