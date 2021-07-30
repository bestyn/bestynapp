//
//  WhiteButton.swift
//  neighbourhood
//
//  Created by Dioksa on 03.06.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

class WhiteButton: BaseButton {

    override func setupView() {
        super.setupView()
        setTitleColor(R.color.mainBlack(), for: .normal)
        backgroundColor = R.color.whiteBackground()
    }
}
