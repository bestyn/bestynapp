//
//  LoadingIndicatorView.swift
//  neighbourhood
//
//  Created by Dioksa on 22.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

@IBDesignable
final class LoadingIndicatorView: UIView {

    @IBInspectable var isAnimating: Bool = false {
        didSet {
            if isAnimating {
                startAnimating()
            } else {
                stopAnimating()
            }
        }
    }

    private let imageView = UIImageView(image: R.image.ic_loading())
    private let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation.z")

    override func willMove(toSuperview newSuperview: UIView?) {
        setupView()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }

    private func setupView() {
        imageView.contentMode = .scaleAspectFit
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.frame = bounds
        addSubview(imageView)
        rotateAnimation.toValue = CGFloat.pi * 2
        rotateAnimation.isCumulative = true
        rotateAnimation.repeatCount = .infinity
        rotateAnimation.speed = 0.2
        if isAnimating {
            startAnimating()
        }
    }

    public func startAnimating() {
        imageView.layer.add(rotateAnimation, forKey: "rotate")
    }

    public func stopAnimating() {
        imageView.layer.removeAllAnimations()
    }
}
