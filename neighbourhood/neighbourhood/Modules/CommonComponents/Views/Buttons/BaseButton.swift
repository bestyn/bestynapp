//
//  BaseButton.swift
//  neighbourhood
//
//  Created by Dioksa on 22.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

@IBDesignable
class BaseButton: UIButton {

    private var originalTitle: String?
    private var imageOffset: CGFloat = 25

    @IBInspectable var isLoading: Bool = false {
        didSet {
            if isLoading {
                originalTitle = title(for: .normal)
                setTitle(nil, for: .normal)
            } else if let originalTitle = originalTitle {
                setTitle(originalTitle, for: .normal)
                self.originalTitle = nil
            }
            indicator.isHidden = !isLoading
            indicator.isAnimating = isLoading
            isEnabled = !isLoading
        }
    }

    @IBInspectable var isBigTitle: Bool = false {
        didSet {
            titleLabel?.font = R.font.poppinsSemiBold(size: 14)
        }
    }

    private let indicator = LoadingIndicatorView()

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
        titleLabel?.font = R.font.poppinsSemiBold(size: 14)
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        setupView()
    }

    func setupView() {
        addSubview(indicator)
        bringSubviewToFront(indicator)
        indicator.isHidden = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        indicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        indicator.heightAnchor.constraint(equalToConstant: 20).isActive = true
        indicator.widthAnchor.constraint(equalToConstant: 20).isActive = true

        imageView?.contentMode = .scaleAspectFit

        setBackgroundColor(color: R.color.greyStroke()!, forState: .disabled)

        setTitleColor(.black, for: .disabled)

        cornerRadius = frame.size.height / 2
    }

    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        let imageRect = super.imageRect(forContentRect: contentRect)
        let titleRect = self.titleRect(forContentRect: contentRect)
        let offset = titleRect.minX - imageRect.width - contentEdgeInsets.left - imageOffset
        return imageRect.offsetBy(dx: -offset, dy: 0)
    }
}
