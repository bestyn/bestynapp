//
//  LightButton.swift
//  neighbourhood
//
//  Created by Artem Korzh on 25.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

class LightButton: BaseButton {

    override func setupView() {
        super.setupView()
        setTitleColor(R.color.blueButton(), for: .normal)
        backgroundColor = R.color.lightButton()
    }
}
