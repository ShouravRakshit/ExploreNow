import MapKit
import UIKit

protocol MapSearchControllerDelegate: AnyObject {
    func didSelectSearchResult(region: MKCoordinateRegion)
    func didStartSearch()
    func didEndSearch()
}

class MapSearchController: NSObject, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, MKLocalSearchCompleterDelegate {
    
    // MARK: - Properties
    private let mapView: MKMapView
    private weak var searchBar: UISearchBar?
    weak var delegate: MapSearchControllerDelegate?
    private var searchCompleter: MKLocalSearchCompleter
    private var searchResults: [MKLocalSearchCompletion] = []
    
    // MARK: - UI Constants
    private let cellHeight: CGFloat = 70
    private let maxTableHeight: CGFloat = 280
    
    // MARK: - UI Components
    private lazy var suggestionsTableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.delegate = self
        table.dataSource = self
        table.register(SearchSuggestionCell.self, forCellReuseIdentifier: "SuggestionCell")
        table.isHidden = true
        table.layer.cornerRadius = 12
        table.backgroundColor = .systemBackground
        table.layer.masksToBounds = false // Important for shadow
        table.layer.borderWidth = 1
        table.layer.borderColor = UIColor.systemGray5.cgColor
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = false
        table.bounces = true
        
        // Shadow
        table.layer.shadowColor = UIColor.black.cgColor
        table.layer.shadowOffset = CGSize(width: 0, height: 4)
        table.layer.shadowRadius = 8
        table.layer.shadowOpacity = 0.1
        
        return table
    }()
    
    // MARK: - Initialization
    init(mapView: MKMapView, searchBar: UISearchBar) {
        self.mapView = mapView
        self.searchBar = searchBar
        self.searchCompleter = MKLocalSearchCompleter()
        super.init()
        
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.pointOfInterest, .address, .query]
        setupSuggestionsTableView()
        customizeSearchBar()
    }
    
    // MARK: - Setup Methods
    private func setupSuggestionsTableView() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            suggestionsTableView.translatesAutoresizingMaskIntoConstraints = false
            window.addSubview(suggestionsTableView)
        }
    }
    
    private func customizeSearchBar() {
        searchBar?.searchTextField.backgroundColor = .systemBackground
        searchBar?.searchTextField.tintColor = .systemBlue
        searchBar?.tintColor = .systemBlue

        if let searchIconView = searchBar?.searchTextField.leftView as? UIImageView {
            searchIconView.tintColor = .systemBlue
        }
    }
    
    // MARK: - Search Bar Delegate Methods
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
        
        UIView.animate(withDuration: 0.3) {
            self.suggestionsTableView.frame = CGRect(
                x: searchBarFrame.origin.x + 16,
                y: searchBarFrame.maxY + 8,
                width: searchBarFrame.width - 32,
                height: min(CGFloat(self.searchResults.count) * self.cellHeight, self.maxTableHeight)
            )
        }
    }
    
    // MARK: - Table View Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SuggestionCell", for: indexPath) as! SearchSuggestionCell
        let result = searchResults[indexPath.row]
        cell.configure(with: result)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
    
    // MARK: - Table View Delegate
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
            self.searchBar?.resignFirstResponder()
        }
    }
    
    // MARK: - Search Completer Delegate
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        suggestionsTableView.reloadData()
        
        if let searchBar = self.searchBar {
            updateSuggestionsTableFrame(searchBar)
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error)")
    }
    
    // MARK: - Public Methods
    func hideSuggestions() {
        suggestionsTableView.isHidden = true
        searchBar?.resignFirstResponder()
    }
}

// MARK: - Search Suggestion Cell
class SearchSuggestionCell: UITableViewCell {
    // UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let locationIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "mappin.circle.fill")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = UIColor(red: 140/255, green: 82/255, blue: 255/255, alpha: 1.0)
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Setup
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(locationIcon)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            locationIcon.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            locationIcon.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            locationIcon.widthAnchor.constraint(equalToConstant: 24),
            locationIcon.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: locationIcon.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // Selection state
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor(red: 140/255, green: 82/255, blue: 255/255, alpha: 0.1)
        selectedBackgroundView = backgroundView
    }
    
    func configure(with result: MKLocalSearchCompletion) {
        titleLabel.text = result.title
        subtitleLabel.text = result.subtitle
    }
}
