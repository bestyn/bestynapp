//
//  ColorCell.swift
//  neighbourhood
//
//  Created by Artem Korzh on 11.01.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit

class ColorCell: UICollectionViewCell {

    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var clearColorImageVIew: UIImageView!

    public var color: UIColor! {
        didSet {
            if color == .clear {
                colorView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
                clearColorImageVIew.isHidden = false
            } else {
                colorView.backgroundColor = color
                clearColorImageVIew.isHidden = true
            }
        }
    }

    override var isSelected: Bool {
        didSet { colorView.transform = isSelected ? .init(scaleX: 4/3, y: 4/3) : .identity }
    }
}
