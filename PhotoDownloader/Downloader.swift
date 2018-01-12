//
//  Downloader.swift
//  PhotoDownloader
//
//  Created by Jonny Kuang on 1/12/18.
//  Copyright © 2018 Jonny Kuang. All rights reserved.
//

import Foundation
import Photos

protocol DownloaderDelegate : class {
    func downloader(_ downloader: Downloader, downloading asset: PHAsset, version: DownloadVersion, downloadProgress: Double)
    func downloader(_ downloader: Downloader, failedToDownload asset: PHAsset, error: Error?)
    func downloader(_ downloader: Downloader, update completeCount: Int, taskCount: Int)
    func downloaderDidFinish(_ downloader: Downloader)
}

enum DownloadVersion {
    case current, unadjusted, original
    
    init(_ version: PHImageRequestOptionsVersion) {
        switch version {
        case .current: self = .current
        case .original: self = .original
        case .unadjusted: self = .unadjusted
        }
    }
    
    init(_ version: PHVideoRequestOptionsVersion) {
        switch version {
        case .current: self = .current
        case .original: self = .original
        }
    }
}

class Downloader {
    
    weak var delegate: DownloaderDelegate?
    
    deinit {
        print("Deinit:", type(of: self))
        queue.cancelAllOperations()
    }
    
    let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .utility
        queue.maxConcurrentOperationCount = 4 // maxConcurrentDownloadTaskCount
        return queue
    }()
    
    func startDownload(earliestAssetCreationDate: Date? = nil) {
        
        var sumCount = 0
        var finishedCount = 0 {
            didSet {
                delegate?.downloader(self, update: finishedCount, taskCount: sumCount)
                if finishedCount == sumCount {
                    delegate?.downloaderDidFinish(self)
                }
            }
        }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.includeHiddenAssets = true
        fetchOptions.includeAllBurstAssets = true
        fetchOptions.includeAssetSourceTypes = [.typeUserLibrary, .typeCloudShared, .typeiTunesSynced]
        fetchOptions.sortDescriptors = [NSSortDescriptor(keyPath: \PHAsset.creationDate, ascending: true)]
        
        if let creationDate = earliestAssetCreationDate {
            fetchOptions.predicate = NSPredicate(format: "creationDate >= %@", creationDate as CVarArg)
        }
        
        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        sumCount = fetchResult.count
        finishedCount = 0
        
        let imageManager = PHImageManager.default()
        
        for index in 0 ..< fetchResult.count {
            let asset = fetchResult[index]
            
            queue.addOperation { [weak self] in
                guard let `self` = self else { return }
                
                defer { finishedCount += 1 }
                
                switch asset.mediaType {
                case .image:
                    let allVersions: [PHImageRequestOptionsVersion] = [.current, .unadjusted, .original]
                    
                    for version in allVersions {
                        let options = PHImageRequestOptions()
                        options.version = version
                        options.deliveryMode = .highQualityFormat
                        options.resizeMode = .exact
                        options.isNetworkAccessAllowed = true
                        options.isSynchronous = true
                        options.progressHandler = { [weak self] progress, error, stop, info in
                            guard let `self` = self else { return }
                            if let error = error {
                                self.delegate?.downloader(self, failedToDownload: asset, error: error)
                            } else {
                                self.delegate?.downloader(self, downloading: asset, version: DownloadVersion(version), downloadProgress: progress)
                            }
                        }
                        
                        imageManager.requestImageData(for: asset, options: options) { data, _, _, info in
                            let error = info?[PHImageErrorKey] as? Error
                            if data == nil {
                                self.delegate?.downloader(self, failedToDownload: asset, error: error)
                            }
                        }
                    }
                case .video, .audio:
                    let allVersions: [PHVideoRequestOptionsVersion] = [.current, .original]
                    
                    for version in allVersions {
                        let options = PHVideoRequestOptions()
                        options.isNetworkAccessAllowed = true
                        options.version = version
                        options.deliveryMode = .highQualityFormat
                        options.progressHandler = { [weak self] progress, error, stop, info in
                            guard let `self` = self else { return }
                            if let error = error {
                                self.delegate?.downloader(self, failedToDownload: asset, error: error)
                            } else {
                                self.delegate?.downloader(self, downloading: asset, version: DownloadVersion(version), downloadProgress: progress)
                            }
                        }
                        
                        // AVAssetExportPresetHighestQuality
                        
                        let semaphore = DispatchSemaphore(value: 0)
                        imageManager.requestAVAsset(forVideo: asset, options: options) { avAsset, audioMix, info in
                            semaphore.signal()
                            
                            let error = info?[PHImageErrorKey] as? Error
                            if avAsset == nil, audioMix == nil {
                                self.delegate?.downloader(self, failedToDownload: asset, error: error)
                            }
                        }
                        semaphore.wait()
                    }
                case .unknown:
                    print("asset.mediaType == .unknown - asset.localIdentifier == \(asset.localIdentifier)")
                }
            }
        }
    }
}
