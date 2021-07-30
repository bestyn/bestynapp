//
//  GalleryCell.swift
//  neighbourhood
//
//  Created by Artem Korzh on 21.12.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

class GalleryCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var videoInfoView: UIView!
    @IBOutlet weak var videoDurationLabel: UILabel!
    @IBOutlet weak var selectedLabel: UILabel!
    @IBOutlet weak var loadingStateImageView: UIImageView!

    var asset: GallerySelectionAsset!
    {
        didSet { fillData() }
    }

    private func fillData() {
        print("asset updated")
        GalleryService().image(asset: asset.asset, size: self.imageView.frame.size) { [weak self] (image) in
            self?.imageView.image = image
        }
        videoInfoView.isHidden = asset.asset.mediaType != .video
        setVideoDuration()
        if let index = asset.selectedIndex {
            selectedLabel.text = "\(index + 1)"
            selectedLabel.isHidden = false
        } else {
            selectedLabel.isHidden = true
        }
        loadingStateImageView.image = nil
        loadingStateImageView.layer.removeAllAnimations()
        switch asset.loadingState {
        case .loading:
            loadingStateImageView.image = R.image.gallery_loading_icon()
            let rotation : CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
            rotation.toValue = NSNumber(value: Double.pi * 2)
            rotation.duration = 1
            rotation.isCumulative = true
            rotation.repeatCount = .greatestFiniteMagnitude
            loadingStateImageView.layer.add(rotation, forKey: "rotationAnimation")
        case .loaded:
            loadingStateImageView.image = R.image.gallery_loaded_icon()
        default:
            break
        }
    }

    private func setVideoDuration() {
        guard asset.asset.mediaType == .video else {
            return
        }
        let totalSeconds = Int(asset.asset.duration)
        let hours: String? = totalSeconds / 3600 > 0 ? String(totalSeconds / 3600) : nil
        let minutes = String(format: "%02d", (totalSeconds % 3600) / 60)
        let seconds = String(format: "%02d", totalSeconds % 60)

        videoDurationLabel.text = [hours, minutes, seconds].compactMap({$0}).joined(separator: ":")
    }
}
