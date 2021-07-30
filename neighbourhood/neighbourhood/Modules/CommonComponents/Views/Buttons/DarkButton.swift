//
//  DarkButton.swift
//  neighbourhood
//
//  Created by Dioksa on 22.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

class DarkButton: BaseButton {

    override func setupView() {
        super.setupView()
        setTitleColor(.white, for: .normal)
        backgroundColor = R.color.blueButton()
    }
}
