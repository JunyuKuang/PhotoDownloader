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
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var asset: Asset? {
        didSet {
            guard let asset = asset else { return }
            let dateString = DateFormatter.localizedString(from: asset.creationDate ?? Date(),
                                                           dateStyle: .medium,
                                                           timeStyle: .medium)
            let progressString = "\(Int(round(asset.downloadProgress * 100)))%"
            textLabel?.text = dateString + progressString
        }
    }
}

