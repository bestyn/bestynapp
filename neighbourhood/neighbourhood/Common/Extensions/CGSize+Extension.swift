//
//  CGSize+Extension.swift
//  neighbourhood
//
//  Created by Artem Korzh on 09.12.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

extension CGSize {

    var rotated: CGSize {
        return .init(width: height, height: width)
    }

    func multiplied(scale: CGFloat) -> CGSize {
        return .init(width: width * scale, height: height * scale)
    }
}
