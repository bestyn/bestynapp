//
//  AdjustmentClipCell.swift
//  neighbourhood
//
//  Created by Artem Korzh on 24.12.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

class AdjustmentClipCell: UICollectionViewCell {

    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var durationLabel: UILabel!

    var thumbnail: UIImage! {
        didSet { thumbnailImageView.image = thumbnail }
    }
    var duration: Double! {
        didSet { durationLabel.text = String(format: "%.1fs", duration) }
    }
    var isCurrentPlaying: Bool = false {
        didSet {
            thumbnailImageView.borderWidth = isCurrentPlaying ? 2 : 0
        }
    }

}
