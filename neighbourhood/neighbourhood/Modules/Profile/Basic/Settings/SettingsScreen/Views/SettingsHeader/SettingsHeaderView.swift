//
//  SettingsHeaderView.swift
//  neighbourhood
//
//  Created by Artem Korzh on 08.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

@objc protocol SettingsHeaderViewDelegate: class {
    func settingsHeaderDidTap(headerView: SettingsHeaderView)
}

@IBDesignable
class SettingsHeaderView: UIView {

    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var arrowImageView: UIImageView!
    
    @IBInspectable var icon: UIImage? {
        didSet { iconImageView.image = icon?.withRenderingMode(.alwaysTemplate) }
    }

    @IBInspectable var title: String? {
        didSet { titleLabel.text = title }
    }
    
    @IBInspectable var open: Bool = false {
        didSet { updateViewState() }
    }

    @IBOutlet public weak var delegate: SettingsHeaderViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }

    private func initView() {
        loadFromXib(R.nib.settingsHeaderView.name, contextOf: SettingsHeaderView.self)
        arrowImageView.image = R.image.arrow_down()?.withRenderingMode(.alwaysTemplate)
    }

    @IBAction func didTapView(_ sender: Any) {
        delegate?.settingsHeaderDidTap(headerView: self)
    }

    private func updateViewState() {
        if open {
            iconImageView.tintColor = R.color.accentBlue()
            titleLabel.textColor = R.color.accentBlue()
            arrowImageView.tintColor = R.color.accentBlue()
            arrowImageView.transform = CGAffineTransform(rotationAngle: .pi)
        } else {
            iconImageView.tintColor = R.color.secondaryBlack()
            titleLabel.textColor = R.color.mainBlack()
            arrowImageView.tintColor = R.color.secondaryBlack()
            arrowImageView.transform = .identity
        }
    }
}
