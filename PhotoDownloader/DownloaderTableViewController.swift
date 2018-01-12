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

class DownloaderTableViewController : CoreDataTableViewController<Asset, AssetTableViewCell>, DownloaderDelegate {
    
    let downloader = Downloader()
    
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
        
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        
        moc.performAndWait {
            let request: NSFetchRequest<Asset> = Asset.fetchRequest()
            request.returnsObjectsAsFaults = true
            for asset in try! request.execute() {
                moc.delete(asset)
            }
            moc.saveIfNeeded()
        }
        
        updateSearchResults(for: searchController)
        
        state = .waitForStart
    }
    
    enum State {
        case waitForStart, downloading, paused
    }
    
    var state = State.waitForStart {
        didSet {
            switch state {
            case .waitForStart:
                navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Start", comment: ""), style: .done, target: self, action: #selector(start))
            case .downloading:
                navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Pause", comment: ""), style: .done, target: self, action: #selector(pause))
                downloader.queue.isSuspended = false
            case .paused:
                navigationItem.rightBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Resume", comment: ""), style: .done, target: self, action: #selector(resume))
                downloader.queue.isSuspended = true
            }
        }
    }
    
    @objc private func start() {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async { [weak self] in
                if status == .authorized {
                    UIApplication.shared.isIdleTimerDisabled = true
                    self?.downloader.delegate = self
                    self?.downloader.startDownload()
                    self?.state = .downloading
                } else {
                    UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!)
                }
            }
        }
    }
    
    @objc private func pause() {
        state = .paused
    }
    
    @objc private func resume() {
        state = .downloading
    }
    
    override func updateSearchResults(for searchController: UISearchController) {
        super.updateSearchResults(for: searchController)
        
        let fetchRequest: NSFetchRequest<Asset> = Asset.fetchRequest()
        fetchRequest.predicate = NSPredicate.init(format: "failedToDownload != FALSE OR downloadProgress < 1.0")
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Asset.failedToDownload, ascending: true),
            NSSortDescriptor(keyPath: \Asset.creationDate, ascending: true),
        ]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsProvider = FetchedResultsProvider(fetchedResultsController: fetchedResultsController) // reload table automatically
    }
    
    override func bind(cell: AssetTableViewCell, withObject object: Asset) {
        cell.asset = object
    }
    
    override func didSelect(_ object: Asset, at indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
//        moc.perform {
//            let fetchOptions = PHFetchOptions()
//            fetchOptions.includeHiddenAssets = true
//            fetchOptions.includeAllBurstAssets = true
//            fetchOptions.includeAssetSourceTypes = [.typeUserLibrary, .typeCloudShared, .typeiTunesSynced]
//            fetchOptions.predicate = NSPredicate(format: "localIdentifier = %@", object.localIdentifier!)
//            
//            let result = PHAsset.fetchAssets(with: fetchOptions)
//            
//            PHPhotoLibrary.shared().performChanges({
//                PHAssetChangeRequest.deleteAssets(result)
//            }, completionHandler: { (success, error) in
//                print(success, error)
//            })
//        }
    }
    
    
    // MARK: - DownloaderDelegate
    
    func downloader(_ downloader: Downloader, failedToDownload asset: PHAsset, error: Error?) {
        moc.perform {
            Asset.asset(for: asset).failedToDownload = true
            Asset.asset(for: asset).downloadProgress = 0
            moc.saveIfNeeded()
        }
        print("error:", error as Any, "imageCreationDate:", asset.creationDate ?? Date())
    }
    
    func downloader(_ downloader: Downloader, downloading asset: PHAsset, version: DownloadVersion, downloadProgress: Double) {
        moc.perform {
            Asset.asset(for: asset).failedToDownload = false
            Asset.asset(for: asset).downloadProgress = downloadProgress
            moc.saveIfNeeded()
        }
    }
    
    func downloader(_ downloader: Downloader, update completeCount: Int, taskCount: Int) {
        DispatchQueue.main.async {
            self.title = "\(completeCount) / \(taskCount)"
        }
    }
    
    func downloaderDidFinish(_ downloader: Downloader) {
        DispatchQueue.main.async {
            self.state = .waitForStart
        }
    }
}


extension Asset {
    
    static func asset(for phAsset: PHAsset) -> Asset {
        var asset: Asset!
        moc.performAndWait {
            let request: NSFetchRequest<Asset> = fetchRequest()
            request.predicate = NSPredicate(format: "localIdentifier = %@", phAsset.localIdentifier)
            request.fetchLimit = 1
            
            if let existedAsset = (try! request.execute()).first {
                asset = existedAsset
            } else {
                asset = Asset(context: moc)
                asset.localIdentifier = phAsset.localIdentifier
                asset.creationDate = phAsset.creationDate
            }
        }
        return asset
    }
}

