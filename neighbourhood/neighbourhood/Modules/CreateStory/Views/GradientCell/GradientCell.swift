//
//  GradientCell.swift
//  neighbourhood
//
//  Created by Artem Korzh on 15.01.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit

class GradientCell: UICollectionViewCell {

    @IBOutlet weak var gradientView: UIView!

    public var gradient: StoryGradient! {
        didSet { updateGradient() }
    }

    private lazy var gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.cornerRadius = 12
        gradientView.layer.insertSublayer(layer, at: 0)
        return layer
    }()

    override var isSelected: Bool {
        didSet { gradientView.transform = isSelected ? .init(scaleX: 4/3, y: 4/3) : .identity }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        resizeGradient()
    }

    private func updateGradient() {
        gradientLayer.colors = gradient.cgColors
        gradientLayer.locations = gradient.locations
        gradientLayer.startPoint = gradient.startPoint
        gradientLayer.endPoint = gradient.endPoint
        gradientLayer.transform = gradient.cgTransform
        resizeGradient()
    }

    private func resizeGradient() {
        gradientLayer.frame = gradientView.bounds.insetBy(dx: -0.5 * gradientView.bounds.width, dy: -0.5 * gradientView.bounds.height)
    }

}
