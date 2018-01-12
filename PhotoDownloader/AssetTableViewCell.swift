//
//  AssetTableViewCell.swift
//  PhotoDownloader
//
//  Created by Jonny Kuang on 1/12/18.
//  Copyright © 2018 Jonny Kuang. All rights reserved.
//

import UIKit
import Photos
import CoreData

class AssetTableViewCell : UITableViewCell {
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        
        textLabel?.numberOfLines = 0
        textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        textLabel?.adjustsFontForContentSizeCategory = true
        
        imageView?.contentMode = .scaleAspectFill
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var assetIdentifier = ""
    
    var asset: Asset? {
        didSet {
            guard let asset = asset,
                let phAsset = fetchPHAsset(with: asset.localIdentifier!) else { return }
            
            let dateString = DateFormatter.localizedString(from: asset.creationDate ?? Date(),
                                                           dateStyle: .medium,
                                                           timeStyle: .medium)
            
            textLabel?.text = [dateString,
                               phAsset.mediaType.kjy_description,
                               phAsset.sourceType.kjy_description].joined(separator: "\n")
            
            
            if asset.failedToDownload {
                state = .failed
            } else {
                state = .inProgress(asset.downloadProgress)
            }
            
            updateThumbnail(for: phAsset)
        }
    }
    
    private enum DownloadState {
        case inProgress(Double)
        case failed
    }
    
    private var state = DownloadState.inProgress(0) {
        didSet {
            switch state {
            case .inProgress(let progress):
                var frame = contentView.bounds
                frame.size.width = frame.width * CGFloat(progress)
                stateIndicationView.frame = frame
                stateIndicationView.backgroundColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1).withAlphaComponent(0.15)
            case .failed:
                stateIndicationView.frame = contentView.bounds
                stateIndicationView.backgroundColor = UIColor.red.withAlphaComponent(0.15)
            }
        }
    }
    
    private let stateIndicationView = UIView()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if stateIndicationView.superview == nil {
            contentView.insertSubview(stateIndicationView, at: 0)
        }
        
        // force trigger `state.didSet` to update stateIndicationView's frame based on latest contentView size.
        let state = self.state
        self.state = state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        textLabel?.text = ""
        imageView?.image = nil
        contentView.backgroundColor = nil
        assetIdentifier = ""
    }
}

private extension AssetTableViewCell {
    
    static let thumbnailSize = CGSize(width: 44 * UIScreen.main.scale, height: 44 * UIScreen.main.scale)
    
    func fetchPHAsset(with identifier: String) -> PHAsset? {
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.includeHiddenAssets = true
        fetchOptions.includeAllBurstAssets = true
        fetchOptions.includeAssetSourceTypes = [.typeUserLibrary, .typeCloudShared, .typeiTunesSynced]
        fetchOptions.predicate = NSPredicate(format: "localIdentifier = %@", identifier)
        
        fetchOptions.fetchLimit = 1
        
        return PHAsset.fetchAssets(with: fetchOptions).firstObject
    }
    
    func updateThumbnail(for phAsset: PHAsset) {
        imageView?.image = nil
        
        guard phAsset.mediaType == .image else { return }
        
        let options = PHImageRequestOptions()
        options.version = .current
        options.deliveryMode = .opportunistic
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true
        
        let assetIdentifier = phAsset.localIdentifier
        self.assetIdentifier = assetIdentifier
        
        PHImageManager.default().requestImage(for: phAsset, targetSize: AssetTableViewCell.thumbnailSize, contentMode: .aspectFill, options: options) { [weak self] image, _ in
            
            guard let image = image,
                let `self` = self,
                self.assetIdentifier == assetIdentifier else { return }
            
            self.imageView?.image = image
        }
    }
}

private extension PHAssetMediaType {
    
    var kjy_description: String {
        switch self {
        case .image:
            return NSLocalizedString("Image", comment: "")
        case .video:
            return NSLocalizedString("Video", comment: "")
        case .audio:
            return NSLocalizedString("Audio", comment: "")
        case .unknown:
            return NSLocalizedString("Unknown Media Type", comment: "")
        }
    }
}

private extension PHAssetSourceType {
    
    var kjy_description: String {
        switch self {
        case .typeUserLibrary:
            return NSLocalizedString("Photo Library", comment: "")
        case .typeCloudShared:
            return NSLocalizedString("iCloud Photo Sharing", comment: "")
        case .typeiTunesSynced:
            return NSLocalizedString("iTunes Synced", comment: "")
        default:
            return NSLocalizedString("Unknown Source Type", comment: "")
        }
    }
}
