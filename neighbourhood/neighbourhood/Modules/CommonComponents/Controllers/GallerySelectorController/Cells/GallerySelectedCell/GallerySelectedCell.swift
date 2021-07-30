//
//  SelectedCollectionViewCell.swift
//  neighbourhood
//
//  Created by iphonovv on 02.12.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import Photos

protocol GallerySelectedCellDelegate: class {
    func selectedAssetRemoved(_ asset: PHAsset)
}

class GallerySelectedCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    weak var delegate: GallerySelectedCellDelegate?
    
    var asset: PHAsset!
    {
        didSet {
            GalleryService().image(asset: asset, size: imageView.bounds.size) { (image) in
                self.imageView.image = image
            }
        }
    }

    @IBAction func didTapRemove(_ sender: Any) {
        delegate?.selectedAssetRemoved(asset)
    }
}
