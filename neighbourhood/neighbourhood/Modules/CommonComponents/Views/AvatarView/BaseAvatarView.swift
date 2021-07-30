//
//  BaseAvatarView.swift
//  neighbourhood
//
//  Created by Artem Korzh on 17.09.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

private let businessGradientColors: [UIColor?] = [R.color.avatarBusinessGradientInsideColor(),
                                      R.color.avatarBusinessGradientMiddleColor(),
                                      UIColor.white]
private let basicGradientColors: [UIColor?] = [R.color.avatarGradientInsideColor(),
                                   R.color.avatarGradientMiddleColor(),
                                   UIColor.white]

class BaseAvatarView: UIView {
    @IBOutlet weak var avatarPlaceholderView: RadialGradientView!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var initialsLabel: UILabel!
    @IBOutlet weak var strokeImageView: UIImageView!

    var strokeImage: UIImage? { isBusiness ? R.image.avatar_round_business() : R.image.avatar_round() }
    var placeholderImage: UIImage? { isBusiness ? R.image.logo_background_business() : R.image.logo_background() }
    var placeholderColors: [UIColor?] { isBusiness ? businessGradientColors : basicGradientColors }
    
    @IBInspectable public var noStroke: Bool = false {
        didSet { updateStrokeVisibility() }
    }
    @IBInspectable public var isBusiness: Bool = false {
        didSet { updateType() }
    }

    private func updateStrokeVisibility() {
        strokeImageView.isHidden = noStroke
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        setNeedsLayout()
    }

    private func updateType() {
        strokeImageView.image = strokeImage
        if !initialsLabel.isHidden {
            avatarImageView.image = nil
        }
        avatarPlaceholderView.setupColors(placeholderColors)
    }

    func updateWith(image: UIImage?, fullName: String) {
        setInitials(fullName: fullName)
        if let image = image {
            avatarImageView.image = image
            initialsLabel.isHidden = true
            self.avatarUpdated(withImage: true)
        }
    }

    func updateWith(imageURL: URL?, fullName: String) {
        setInitials(fullName: fullName)
        if let url = imageURL {
            avatarImageView.load(from: url, withLoader: true) {
                self.initialsLabel.isHidden = true
                self.avatarUpdated(withImage: true)
            }
        }
    }

    public func reset() {
        avatarImageView.image = nil
        initialsLabel.text = nil
    }

    private func setInitials(fullName: String) {
        avatarImageView.image = nil
        initialsLabel.isHidden = false
        initialsLabel.text = fullName.firstInitial
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
        initialsLabel.text = ""
        backgroundColor = .clear
        updateStrokeVisibility()
        updateType()
    }

    func updateCorners() {
        avatarImageView.cornerRadius = avatarImageView.bounds.size.width / 2
        avatarPlaceholderView.cornerRadius = avatarImageView.bounds.size.width / 2
    }

    public func avatarUpdated(withImage: Bool) {
        updateCorners()
    }
}
