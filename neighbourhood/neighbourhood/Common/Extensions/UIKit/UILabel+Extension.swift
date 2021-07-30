//
//  UILabel+Extension.swift
//  neighbourhood
//
//  Created by Dioksa on 14.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

extension UILabel {
    func setStrokeText(
        _ text: String,
        font: UIFont,
        color: UIColor,
        strokeWidth: Float,
        strokeColor: UIColor
    ) {
        let label = self
        label.textColor = color
        label.font = font
            

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 0.95
        paragraphStyle.alignment = .center

        label.attributedText = NSMutableAttributedString(
            string: text,
            attributes: [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.strokeWidth: -strokeWidth,
                NSAttributedString.Key.strokeColor: strokeColor
            ]
        )
    }
}
