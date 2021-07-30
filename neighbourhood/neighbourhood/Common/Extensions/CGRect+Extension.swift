//
//  CGRect+Extension.swift
//  neighbourhood
//
//  Created by Administrator on 27.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import CoreGraphics

extension CGRect {
    func scale(_ multiplier: CGFloat) -> CGRect {
        return CGRect(x: origin.x * multiplier,
                      y: origin.y * multiplier,
                      width: width * multiplier,
                      height: height * multiplier)
    }
}
