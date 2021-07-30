//
//  FontCell.swift
//  neighbourhood
//
//  Created by Artem Korzh on 08.01.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit

class FontCell: UICollectionViewCell {

    @IBOutlet weak var outerView: UIView!
    @IBOutlet weak var fontLabel: UILabel!

    override var isSelected: Bool {
        didSet {
            outerView.borderColor = isSelected ? UIColor.white : UIColor.black.withAlphaComponent(0.2)
            outerView.transform = isSelected ? .init(scaleX: 34/30, y: 34/30) : .identity
        }
    }

    public var font: UIFont! {
        didSet { updateFontLabel() }
    }

    private func updateFontLabel() {
        let attributedText = NSAttributedString(string: "Aa", attributes: [
            .font: font.withSize(14),
            .foregroundColor: UIColor.white,
            .strokeWidth: -5,
            .strokeColor: UIColor.black.withAlphaComponent(0.2)
        ])
        fontLabel.attributedText = attributedText
    }
}
