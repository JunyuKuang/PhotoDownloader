//
//  DownloaderTableViewController.swift
//  PhotoDownloader
//
//  Created by Jonny Kuang on 1/12/18.
//  Copyright © 2018 Jonny Kuang. All rights reserved.
//

import UIKit
import Photos
import CoreData

class DownloaderTableViewController : CoreDataTableViewController<Asset, AssetTableViewCell> {
    
    override var hintForEmptyTable: String {
        return NSLocalizedString("No Download Session", comment: "")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
        } else {
            tableView.estimatedRowHeight = 64
            tableView.rowHeight = UITableViewAutomaticDimension
        }
        
        updateSearchResults(for: searchController)
    }
    
    override func updateSearchResults(for searchController: UISearchController) {
        super.updateSearchResults(for: searchController)
        
        let fetchRequest: NSFetchRequest<Asset> = Asset.fetchRequest()
        fetchRequest.predicate = NSPredicate.init(format: "downloadProgress < 1.0")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Asset.creationDate, ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsProvider = FetchedResultsProvider(fetchedResultsController: fetchedResultsController) // reload table automatically
    }
    
    override func bind(cell: AssetTableViewCell, withObject object: Asset) {
        
    }
    
    override func didSelect(_ object: ReadingItem, at indexPath: IndexPath) {
        guard let readerContainer = readerContainer else { return }
        let readingItem = object
        let url = readingItem.url
        
        let completionHandler = { [weak self] (isCompleted: Bool) in
            guard let `self` = self,
                let indexPath = self.tableView.indexPathForSelectedRow else { return }
            self.tableView.deselectRow(at: indexPath, animated: self.view.window != nil)
        }
        
        if let currentReaderController = readerContainer.readerViewControllers.last,
            currentReaderController.shortURL == url,
            currentReaderController.readingItem == readingItem
        {
            readerContainer.setActiveChild(.detail, animated: true, completionHandler: completionHandler)
        } else {
            readerContainer.showReader(withURL: url, readingItem: readingItem, completionHandler: completionHandler)
        }
    }
}

class AssetTableViewCell : UITableViewCell {
    
}
