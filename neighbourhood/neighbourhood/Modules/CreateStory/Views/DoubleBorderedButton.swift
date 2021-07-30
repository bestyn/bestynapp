//
//  DoubleBorderedButton.swift
//  neighbourhood
//
//  Created by Artem Korzh on 26.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

class DoubleBorderedButton: UIButton {

    @IBInspectable var outerBorderColor: UIColor = UIColor.black.withAlphaComponent(0.2)
    { didSet { outerBorderLayer.borderColor = outerBorderColor.cgColor }}
    @IBInspectable var outerBorderWidth: CGFloat = 1
    { didSet { outerBorderLayer.borderWidth = outerBorderWidth } }

    @IBInspectable var innerBorderColor: UIColor = UIColor.white.withAlphaComponent(0.6)
    { didSet { innerBorderLayer.borderColor = innerBorderColor.cgColor }}
    @IBInspectable var innerBorderWidth: CGFloat = 1
    { didSet { innerBorderLayer.borderWidth = innerBorderWidth }}

    private let innerBorderLayer = CALayer()
    private let outerBorderLayer = CALayer()


    override func awakeFromNib() {
        super.awakeFromNib()
        setupBorderLayers()
        setTitle(title(for: .normal), for: .normal)
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupBorderLayers()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        adjustBorderLayers()
    }

    private func setupBorderLayers() {
        innerBorderLayer.borderColor = innerBorderColor.cgColor
        innerBorderLayer.borderWidth = innerBorderWidth

        outerBorderLayer.borderColor = outerBorderColor.cgColor
        outerBorderLayer.borderWidth = outerBorderWidth

        layer.addSublayer(outerBorderLayer)
        layer.addSublayer(innerBorderLayer)

        adjustBorderLayers()
    }

    private func adjustBorderLayers() {
        outerBorderLayer.frame = bounds.insetBy(dx: -outerBorderWidth, dy: -outerBorderWidth)
        innerBorderLayer.frame = bounds
        outerBorderLayer.cornerRadius = layer.cornerRadius + outerBorderWidth
        innerBorderLayer.cornerRadius = layer.cornerRadius
    }

    override func setTitle(_ title: String?, for state: UIControl.State) {
        guard let title = title else {
            self.setAttributedTitle(nil, for: state)
            return
        }
        let attributeString = NSAttributedString(string: title, attributes: [
            .foregroundColor: UIColor.white,
            .strokeWidth: -4,
            .strokeColor: UIColor.black.withAlphaComponent(0.2),
            .font: titleLabel?.font
        ])
        self.setAttributedTitle(attributeString, for: state)
    }


}
