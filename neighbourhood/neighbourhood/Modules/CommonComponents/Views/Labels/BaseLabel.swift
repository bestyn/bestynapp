//
//  BaseLabel.swift
//  neighbourhood
//
//  Created by Dioksa on 22.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

class BaseLabel: UILabel {

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    func setupView() {
       // textColor = R.color.primaryDark()
    }
}
