//
//  HeadingLabel.swift
//  neighbourhood
//
//  Created by Dioksa on 22.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

@IBDesignable
class HeadingLabel: BaseLabel {

    @objc enum HeadingSize: Int {
        case size1
        case size2
        case size3
        case size4
    }

    private var size: HeadingSize = .size1

    @IBInspectable var sizeAdapter: Int {
        get {
            return size.rawValue
        }
        set {
            size = HeadingSize(rawValue: newValue) ?? .size4
        }
    }

    override func setupView() {
        super.setupView()
//        switch size {
//        case .size1:
//            font = UIFont.h1
//        case .size2:
//            font = UIFont.h2
//        case .size3:
//            font = UIFont.h3
//        case .size4:
//            font = UIFont.h4
//        }
    }
}
