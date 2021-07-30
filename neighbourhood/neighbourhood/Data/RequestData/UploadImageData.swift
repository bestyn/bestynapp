//
//  UploadImageData.swift
//  neighbourhood
//
//  Created by Artem Korzh on 02.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

struct UploadImageData {
    let image: UIImage
    let crop: Rect
}

struct Rect: Encodable {
    let x: Int
    let y: Int
    let width: Int
    let height: Int

    init(cgRect: CGRect) {
        x = Int(cgRect.origin.x)
        y = Int(cgRect.origin.y)
        width = Int(cgRect.size.width)
        height = Int(cgRect.size.height)
    }

    var cgRect: CGRect {
        return .init(x: CGFloat(x), y: CGFloat(y), width: CGFloat(width), height: CGFloat(height))
    }
}
