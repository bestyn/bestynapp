//
//  BusinessAddImageCell.swift
//  neighbourhood
//
//  Created by Dioksa on 15.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

final class BusinessAddImageCell: UICollectionViewCell {
    @IBOutlet private weak var addImageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addImageLabel.text = R.string.localizable.addImageTitle()
    }
}
