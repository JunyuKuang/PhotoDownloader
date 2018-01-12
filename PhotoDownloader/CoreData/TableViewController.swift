//
//  TableViewController.swift
//  LibraryManager
//
//  Created by Jonny on 12/28/16.
//  Copyright © 2016 Jonny. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate {
    
    // MARK: - Properties
    
    var hintForEmptyTable: String {
        return "No Contents"
    }
    
    var hintForNoSearchResult: String {
        return "No Search Result"
    }
    
    var searchBarPlaceholder: String? {
        return nil
    }
    
    /// Return true to configure search controller and show search bar. Default is false.
    var isSearchable: Bool {
        return false
    }
    
    private(set) lazy var hintLabel: UILabel = { [unowned self] in
        
        let label = UILabel()
        label.textColor = UIColor.darkGray
        label.font = UIFont.preferredFont(forTextStyle: .title1)
        label.text = self.hintForEmptyTable
        label.sizeToFit()
        
        self.view.addSubview(label)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: -80 - (self.isSearchable ? 44 : 0)), // minus search bar's height.
            ])
        
        return label
    }()
    
    private(set) lazy var searchController: UISearchController = {
        
        let searchController = UISearchController(searchResultsController: nil)
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.dimsBackgroundDuringPresentation = false
        
        searchController.searchBar.placeholder = self.searchBarPlaceholder
        searchController.searchBar.delegate = self
        searchController.searchResultsUpdater = self
        
        return searchController
    }()
    
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.cellLayoutMarginsFollowReadableWidth = true
        
        if isSearchable {
            if #available(iOS 11.0, *) {
                navigationItem.searchController = searchController
                navigationItem.hidesSearchBarWhenScrolling = false
            } else {
                tableView.tableHeaderView = searchController.searchBar
            }
        }
    }
    
    private var previousSearchText: String?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let previousSearchText = self.previousSearchText else { return }
        
        DispatchQueue.main.async {
            // workaround: controller receive updateSearchResults(for:) with searchController.isActive == false after we set the isActive to true, if we don't async dispatch. ** It just works™ **
            self.searchController.searchBar.text = previousSearchText
            self.searchController.isActive = true
            self.previousSearchText = nil
            
            DispatchQueue.main.async {
                // workaround: search bar won't become first responder if we don't async dispatch orz
                self.searchController.searchBar.becomeFirstResponder()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard isSearchable else { return }
        guard searchController.isActive else { return }
        
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            previousSearchText = searchText
        }
        
        searchController.isActive = false
    }
    
    
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        if searchController.isActive {
            hintLabel.text = hintForNoSearchResult
        } else {
            hintLabel.text = hintForEmptyTable
        }
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
    }

}
