//
//  CheckBoxView.swift
//  neighbourhood
//
//  Created by Dioksa on 24.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

@objc protocol CheckBoxViewDelegate: class {
    func checkBoxDidChange(checkBox: CheckBoxView, isChecked: Bool)
}

@IBDesignable
final class CheckBoxView: UIView {

    @IBOutlet public weak var checkBoxViewDelegate: CheckBoxViewDelegate?

    private let imageView = UIImageView()
    private let button = UIButton()

    @IBInspectable var isChecked: Bool = false {
        didSet {
            updateState()
        }
    }

    @IBInspectable var isEnabled: Bool = true {
        didSet {
            updateState()
        }
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    private func setupView() {
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.frame = bounds
        addSubview(imageView)
        imageView.cornerRadius = bounds.width / 2
        updateState()
        button.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        button.frame = bounds
        addSubview(button)
        button.addTarget(self, action: #selector(didTapCheckBox), for: .touchUpInside)
        updateAccesabilityLabel()
    }

    private func updateState() {
        imageView.borderWidth = 0
        imageView.backgroundColor = nil
        imageView.image = nil
        switch (isChecked, isEnabled) {
        case (true, true):
            imageView.image = R.image.checkbox_checked()
        case (false, true):
            imageView.image = R.image.checkbox_unchecked()
        case (true, false):
            imageView.image = R.image.checkbox_unchecked()
        case (false, false):
            imageView.image = R.image.checkbox_unchecked()
        }
        updateAccesabilityLabel()
    }

    private func updateAccesabilityLabel() {
        let checkedLabel = isChecked ? "Checked" : "Unchecked"
        self.button.accessibilityLabel = "\(checkedLabel)"
        self.button.accessibilityTraits = isEnabled ? .button : [.button, .notEnabled]
    }

    @objc private func didTapCheckBox() {
        guard isEnabled else {
            return
        }
        isChecked = !isChecked
        checkBoxViewDelegate?.checkBoxDidChange(checkBox: self, isChecked: isChecked)
        updateState()
    }
}
