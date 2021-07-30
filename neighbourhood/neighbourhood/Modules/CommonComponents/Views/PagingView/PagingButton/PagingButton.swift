//
//  PagingButton.swift
//  neighbourhood
//
//  Created by Artem Korzh on 07.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

@IBDesignable
class PagingButton: UIButton {

    @IBInspectable override var isSelected: Bool {
        didSet { updateState() }
    }

    private lazy var underline: UIView = {
        let view = UIView()
        addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 2),
            view.bottomAnchor.constraint(equalTo: bottomAnchor),
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        view.backgroundColor = R.color.blueButton()
        view.isHidden = true
        return view
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        setupView()
    }

    private func setupView() {
        titleLabel?.font = R.font.poppinsMedium(size: 12)
        setTitleColor(R.color.greyMedium(), for: .normal)
        updateState()
    }

    private func updateState() {
        setTitleColor(isSelected ? R.color.blueButton() : R.color.greyMedium(), for: .normal)
        underline.isHidden = !isSelected
    }
}
