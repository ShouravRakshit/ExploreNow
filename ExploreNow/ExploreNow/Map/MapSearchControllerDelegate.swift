//
//  MapSearchControllerDelegate.swift
//  ExploreNow
//
//  Shourav Rakshit Ivan, Alisha Lalani, Saadman Rahman, ----------, Manvi Juneja,
//  Zaid Nissar, Qusai Dahodwalla, Shree Patel, Vidhi Soni


import MapKit
import UIKit

// MARK: - MapSearchControllerDelegate Protocol

/// A protocol that defines the communication methods for a Map Search controller.
/// This protocol allows the controller to inform its delegate about search events,
/// such as when a search result is selected or when the search has started or ended.

protocol MapSearchControllerDelegate: AnyObject {
    /// Notifies the delegate that a search result was selected.
    /// - Parameter region: The region corresponding to the selected search result.
    func didSelectSearchResult(region: MKCoordinateRegion)
    /// Notifies the delegate that the search has started.
    func didStartSearch()
    /// Notifies the delegate that the search has ended.
    func didEndSearch()
}

// all about search functionality

class MapSearchController: NSObject, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, MKLocalSearchCompleterDelegate {
    // MARK: - Properties

    // The map view that the search controller interacts with.
    private let mapView: MKMapView
    // The search bar used for entering search queries.
    private weak var searchBar: UISearchBar?
    // The delegate that conforms to `MapSearchControllerDelegate` protocol to handle search results.
    weak var delegate: MapSearchControllerDelegate?
    // The search completer used to fetch location suggestions based on the search query.
    private var searchCompleter: MKLocalSearchCompleter
    // Array to store search results.
    private var searchResults: [MKLocalSearchCompletion] = []
    
    // Lazy-loaded table view for displaying search suggestions.
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
    
    // MARK: - Initializer

    // Initializes the search controller with a map view and search bar.

    init(mapView: MKMapView, searchBar: UISearchBar) {
        self.mapView = mapView
        self.searchBar = searchBar
        self.searchCompleter = MKLocalSearchCompleter()
        super.init()
        
        // Set the search bar color properties.
        searchBar.tintColor = .systemBlue
        searchBar.searchTextField.tintColor = .systemBlue

        // Set up the search completer delegate and result types.
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.pointOfInterest, .address, .query]
        // Set up the suggestions table view.
        setupSuggestionsTableView()
    }
    
    private func setupSuggestionsTableView() {
        // Attempt to retrieve the window scene from the connected scenes
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            // Disable the automatic conversion of autoresizing mask into constraints
            suggestionsTableView.translatesAutoresizingMaskIntoConstraints = false
            // Add the suggestionsTableView as a subview of the window
            window.addSubview(suggestionsTableView)
        }
    }
    
    // MARK: - UISearchBarDelegate

    // This method is called when the user begins editing the search bar (i.e., when the user taps on the search bar).
    // It notifies the delegate that the search has started, updates the suggestions table frame, and makes the
    // suggestions table view visible.
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        // Notify the delegate that the user has started searching
        delegate?.didStartSearch()
        // Update the suggestions table view frame to ensure it appears correctly below the search bar
        updateSuggestionsTableFrame(searchBar)
        // Make the suggestions table view visible
        suggestionsTableView.isHidden = false
    }
    
    // This method is called every time the text in the search bar changes (as the user types).
    // It updates the search query and shows the suggestions table view with new results, or hides it if the text is empty.
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // If the search text is empty, clear the search results and hide the suggestions table
        if searchText.isEmpty {
            searchResults.removeAll()  // Remove any previous search results
            suggestionsTableView.isHidden = true // Hide the suggestions table view
            return
        }
        // If the search text is not empty, update the query fragment for the search completer.
        searchCompleter.queryFragment = searchText
        
        // Show the suggestions table view and update its frame
        suggestionsTableView.isHidden = false
        updateSuggestionsTableFrame(searchBar)
    }
    
    // This method is called when the cancel button on the search bar is clicked.
    // It clears the search text, resigns the search bar as the first responder (hides the keyboard),
    // hides the suggestions table view, and notifies the delegate that the search has ended.
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // Clear the search bar text
        searchBar.text = ""
        // Resign the search bar as the first responder, hiding the keyboard
        searchBar.resignFirstResponder()
        // Hide the suggestions table view
        suggestionsTableView.isHidden = true
        // Notify the delegate that the search has ended
        delegate?.didEndSearch()
    }
    
    // This method is responsible for updating the position and size of the suggestions table view
    // based on the search bar's frame. It ensures the table view is placed correctly relative to the search bar
    // and adjusts its height based on the number of search results (with a maximum height).
    private func updateSuggestionsTableFrame(_ searchBar: UISearchBar) {
        // Convert the search bar's frame to the global coordinate system (relative to the entire screen)
        guard let searchBarFrame = searchBar.superview?.convert(searchBar.frame, to: nil) else { return }
        
        
        // Update the frame of the suggestions table view
        suggestionsTableView.frame = CGRect(
            x: searchBarFrame.origin.x, // Position the table view horizontally aligned with the search bar
            y: searchBarFrame.maxY + 8, // Position the table view just below the search bar with an 8-point gap
            width: searchBarFrame.width, // Set the width of the table view to match the search bar
            height: min(CGFloat(searchResults.count * 44), 220)  // Limit the height to a maximum of 220 points
        )
    }
    
    // MARK: - UITableViewDataSource

    // This method is required by the UITableViewDataSource protocol.
    // It returns the number of rows in the given section, which corresponds to the number of search results.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    // This method is required by the UITableViewDataSource protocol.
    // It configures the cell for each row at the given indexPath.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Dequeue a reusable cell with the identifier "SuggestionCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: "SuggestionCell", for: indexPath)
        // Get the search result for the current row at indexPath
        let result = searchResults[indexPath.row]
        
        // Set the text for the cell's primary label (textLabel)
        // Combining the result's title and subtitle to form a full description of the suggestion
        cell.textLabel?.text = result.title + ", " + result.subtitle
        // Set the font for the primary label
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
//        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
//        cell.detailTextLabel?.textColor = .secondaryLabel
        
        // Set the background color of the cell to clear (no background color)
        cell.backgroundColor = .clear
        // Print the title and subtitle of the current search result to the console for debugging
        print(result.title)
        print(result.subtitle)
        // Return the configured cell to be displayed in the table view
        return cell
    }
    
    // MARK: - UITableViewDelegate

    // This method is called when a row in the suggestions table view is selected by the user.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect the row with an animation after it is selected
        tableView.deselectRow(at: indexPath, animated: true)
        // Get the selected completion (search result) from the search results array
        let completion = searchResults[indexPath.row]
        
        // Set the text of the search bar to the title of the selected search result
        searchBar?.text = completion.title
        
        // Create an MKLocalSearch request using the selected completion
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        
        // Start the search
        search.start { [weak self] (response, error) in
            // Ensure self is still available and the response contains valid map items
            guard let self = self,
                  let mapItem = response?.mapItems.first else { return }
            
            // Create a region centered on the selected location's coordinates
            let region = MKCoordinateRegion(
                center: mapItem.placemark.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
            // Inform the delegate about the selected search result by passing the region
            self.delegate?.didSelectSearchResult(region: region)
            // Hide the suggestions table view after the result has been selected
            self.suggestionsTableView.isHidden = true
        }
    }
    
    // MARK: - MKLocalSearchCompleterDelegate

    // This function is called when the search results are updated in the search completer.
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Updates the search results array with the new results from the completer
        searchResults = completer.results
        
        // Reloads the data in the suggestions table view to reflect the updated search results
        suggestionsTableView.reloadData()
        
        // If the completer's delegate is a UISearchBar, update the table view frame accordingly
        if let searchBar = completer.delegate as? UISearchBar {
            updateSuggestionsTableFrame(searchBar)
        }
    }
    
    // This function handles errors if the search completer fails to fetch results.
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Prints the error message to the console for debugging purposes
        print("Search completer error: \(error)")
    }
    
    // This function hides the suggestions table view and dismisses the search bar.
    func hideSuggestions() {
        // Hides the table view that shows the search suggestions
        suggestionsTableView.isHidden = true
        // Resigns the first responder status of the search bar, which hides the keyboard
        searchBar?.resignFirstResponder()
    }
}
