//
//  ChatBackgroundCell.swift
//  neighbourhood
//
//  Created by Dioksa on 24.06.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

final class ChatBackgroundCell: UICollectionViewCell {
    @IBOutlet private weak var backgroundImageView: UIImageView!
    @IBOutlet private weak var selectedImageView: UIImageView!
    @IBOutlet private weak var backgrounTitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectedImageView.isHidden = true
        backgrounTitleLabel.isHidden = true
    }
    
    override var isSelected: Bool {
        didSet {
            selectedImageView.isHidden = self.isSelected ? false : true
        }
    }
    
    public func setImage(_ image: UIImage, isDefault: Bool = false) {
        backgrounTitleLabel.isHidden = !isDefault
        backgroundImageView.image = image
    }
}
