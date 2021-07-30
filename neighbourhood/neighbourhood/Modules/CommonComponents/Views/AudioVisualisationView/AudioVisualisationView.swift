//
//  AudioVisualisationView.swift
//  neighbourhood
//
//  Created by Artem Korzh on 10.02.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit

@IBDesignable
class AudioVisualisationView: UIView {

    let bgImageView = UIImageView(image: R.image.bg_audio_visualisation())
    let activeBGImageView = UIImageView(image: R.image.bg_audio_visualisation())
    let maskLayer = CALayer()

    @IBInspectable public var min: CGFloat = 0 {
        didSet { updateMask() }
    }
    @IBInspectable  public var max: CGFloat = 0 {
        didSet { updateMask() }
    }

    @IBInspectable public var activeColor: UIColor = R.color.secondaryBlack()! {
        didSet { activeBGImageView.tintColor = activeColor }
    }

    @IBInspectable public var baseColor: UIColor = R.color.accentGreen()! {
        didSet { bgImageView.tintColor = baseColor }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        maskLayer.backgroundColor = UIColor.black.cgColor
        maskLayer.removeAllAnimations()
        activeBGImageView.layer.mask = maskLayer
        addSubview(bgImageView)
        addSubview(activeBGImageView)
        bgImageView.contentMode = .scaleToFill
            activeBGImageView.contentMode = .scaleToFill
        bgImageView.translatesAutoresizingMaskIntoConstraints = false
        activeBGImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bgImageView.topAnchor.constraint(equalTo: topAnchor),
            bgImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            bgImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bgImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            activeBGImageView.topAnchor.constraint(equalTo: topAnchor),
            activeBGImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            activeBGImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            activeBGImageView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        bgImageView.tintColor = baseColor
        activeBGImageView.tintColor = activeColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateMask()
    }

    private func updateMask() {
        maskLayer.frame = CGRect(
            x: activeBGImageView.frame.width * CGFloat(min),
            y: activeBGImageView.frame.minY,
            width: activeBGImageView.frame.width * CGFloat(max - min),
            height: activeBGImageView.frame.height)
        maskLayer.removeAllAnimations()
    }
}
