//
//  ParagraphLabel.swift
//  neighbourhood
//
//  Created by Dioksa on 22.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

@IBDesignable
class ParagraphLabel: BaseLabel {

    @objc enum ParagraphSize: Int {
        case size1
        case size2
    }

    private var size: ParagraphSize = .size1

    @IBInspectable var sizeAdapter: Int {
        get {
            return size.rawValue
        }
        set {
            size = ParagraphSize(rawValue: newValue) ?? .size2
        }
    }

    override func setupView() {
        super.setupView()
//        switch size {
//        case .size1:
//            font = UIFont.p1
//        case .size2:
//            font = UIFont.p2
//        }
    }
}
