//
//  NSLayoutConstraint+Extension.swift
//  neighbourhood
//
//  Created by Artem Korzh on 07.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

extension NSLayoutConstraint {

    func withMultiplier(_ multiplier: CGFloat) -> NSLayoutConstraint {
        return NSLayoutConstraint(
            item: self.firstItem!,
            attribute: self.firstAttribute,
            relatedBy: self.relation,
            toItem: self.secondItem,
            attribute: self.secondAttribute,
            multiplier: multiplier,
            constant: self.constant)
    }

    func replaceWith(_ constraint: NSLayoutConstraint) {
        NSLayoutConstraint.deactivate([self])
        NSLayoutConstraint.activate([constraint])
    }

}
