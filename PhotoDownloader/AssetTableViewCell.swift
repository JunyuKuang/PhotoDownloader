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
                downloadState = .failed
            } else {
                downloadState = .inProgress(asset.downloadProgress)
            }
            
            assetIdentifier = phAsset.localIdentifier
            updateThumbnail(for: phAsset)
        }
    }
    
    private enum DownloadState {
        case inProgress(Double)
        case failed
    }
    
    private var downloadState = DownloadState.inProgress(0) {
        didSet {
            switch downloadState {
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
        let state = self.downloadState
        self.downloadState = state
    }
    
    enum ThumbnailLoadingState {
        case loading(identifier: String)
        case loaded(identifier: String, image: UIImage)
    }
    
    var thumbnailLoadingState = ThumbnailLoadingState.loading(identifier: "")
}

private extension AssetTableViewCell {
    
    static let thumbnailPointSize = CGSize(width: 88, height: 88)
    static let thumbnailPixelSize = CGSize(width: thumbnailPointSize.width * UIScreen.main.scale,
                                           height: thumbnailPointSize.height * UIScreen.main.scale)
    static let placeholderImage: UIImage = {
        let rect = CGRect(origin: .zero, size: thumbnailPointSize)
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        
        return UIGraphicsImageRenderer(bounds: rect, format: format).image { context in
            context.cgContext.setFillColor(UIColor(white: 0.95, alpha: 1).cgColor)
            context.cgContext.fill(rect)
        }
    }()
    
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
        
        guard phAsset.mediaType == .image else {
            imageView?.image = AssetTableViewCell.placeholderImage
            return
        }
        
        // skip if thumbnail is loading or loaded
        switch thumbnailLoadingState {
        case .loading(let identifier):
            if identifier == phAsset.localIdentifier {
                return
            }
        case .loaded(let identifier, let image):
            if identifier == phAsset.localIdentifier {
                imageView?.image = image
                return
            }
        }
        
        imageView?.image = AssetTableViewCell.placeholderImage
        thumbnailLoadingState = .loading(identifier: phAsset.localIdentifier)
        
        let options = PHImageRequestOptions()
        options.version = .current
        options.deliveryMode = .opportunistic
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true
        
        let assetIdentifier = phAsset.localIdentifier
        
        PHImageManager.default().requestImage(for: phAsset, targetSize: AssetTableViewCell.thumbnailPixelSize, contentMode: .aspectFill, options: options) { [weak self] image, info in
            
            guard let `self` = self,
                self.assetIdentifier == assetIdentifier,
                let image = image,
                let cgImage = image.cgImage else { return }
            
            let imageOrientation = image.imageOrientation
            let modifiedImage = UIImage(cgImage: cgImage,
                                        scale: UIScreen.main.scale,
                                        orientation: imageOrientation)
            
            self.imageView?.image = modifiedImage
            self.thumbnailLoadingState = .loaded(identifier: phAsset.localIdentifier, image: modifiedImage)
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
            return NSLocalizedString("From iCloud Photo Sharing\nRequires manual download in Photos app", comment: "")
        case .typeiTunesSynced:
            return NSLocalizedString("From iTunes", comment: "")
        default:
            return NSLocalizedString("Unknown Source", comment: "")
        }
    }
}

//class ImageView : UIImageView {
//
//    override var intrinsicContentSize: CGSize {
//        return CGSize(width: 44 * 2, height: 44 * 2)
//    }
//}

