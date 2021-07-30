//
//  NewsHeaderCollectionCell.swift
//  neighbourhood
//
//  Created by Andrii Zakhliupanyi on 11.08.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

class NewsHeaderCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var detailsButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        detailsButton.setTitle(R.string.localizable.details(), for: .normal)
    }
    
    static func size() -> CGSize {
        let width = UIScreen.main.bounds.width
        let widthCell = 235.0 / 375.0 * width
        let heightCell = 275.0 / 375.0 * width
        return CGSize(width: widthCell, height: heightCell)
    }
    
}
