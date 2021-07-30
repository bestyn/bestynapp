//
//  LightButton.swift
//  neighbourhood
//
//  Created by Dioksa on 22.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

class GreyButton: BaseButton {

    override func setupView() {
        super.setupView()
        setTitleColor(R.color.whiteBackground(), for: .normal)
        backgroundColor = R.color.greyMedium()
    }
}
