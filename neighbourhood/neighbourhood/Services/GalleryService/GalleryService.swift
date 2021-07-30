//
//  GalleryService.swift
//  neighbourhood
//
//  Created by Artem Korzh on 04.01.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import Foundation
import Photos
import UIKit
import AVFoundation

enum GalleryAssetType {
    case all
    case photo
    case video
}

struct GalleryService {

    func fetchAssets(type: GalleryAssetType) -> PHFetchResult<PHAsset> {
        let assets: PHFetchResult<PHAsset>
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        switch type {
        case .all:
            fetchOptions.predicate = NSPredicate(format: "mediaType = %d || mediaType = %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
            assets = PHAsset.fetchAssets(with: fetchOptions)
        case .photo:
            assets = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)
        case .video:
            assets = PHAsset.fetchAssets(with: PHAssetMediaType.video, options: fetchOptions)
        }

        return assets
    }

    func image(asset: PHAsset, size: CGSize, completion: @escaping (UIImage?) -> Void) {
        PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: nil) { (image, _) in
            completion(image)
        }
    }
}

