//
//  ShadowRoundedView.swift
//  neighbourhood
//
//  Created by Dioksa on 23.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

@IBDesignable
class ShadowRoundedView: UIView {
    
    @IBInspectable var isRotated: Bool = false {
        didSet {
            roundedView.transform = isRotated ? CGAffineTransform(rotationAngle: .pi) : .identity
        }
    }
    
    private let roundedView = UIView()
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    private func setupView() {
        roundedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        roundedView.backgroundColor = .white
        roundedView.frame = bounds
        roundedView.roundCorners(corners: [.topLeft, .topRight], radius: 30)
        insertSubview(roundedView, at: 0)
        backgroundColor = .clear
        clipsToBounds = false
        dropShadow(offSet: CGSize(width: 0, height: 0), radius: 0)
    }
}
