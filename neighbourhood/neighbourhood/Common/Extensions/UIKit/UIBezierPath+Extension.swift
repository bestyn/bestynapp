//
//  UIBezierPath+Extension.swift
//  neighbourhood
//
//  Created by Artem Korzh on 07.04.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit

extension UIBezierPath {

    public static func verticalSymmetricShape(bounds: CGRect, leftRadius: CGFloat, rightRadius: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: bounds.minX + leftRadius, y: bounds.minY))
        path.addLine(to: CGPoint(x: bounds.maxX - rightRadius, y: bounds.minY))
        path.addArc(withCenter: CGPoint(x: bounds.maxX - rightRadius, y: bounds.minY + rightRadius), radius: rightRadius, startAngle: 3 * .pi / 2, endAngle: 0, clockwise: true)
        path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY - rightRadius))
        path.addArc(withCenter: CGPoint(x: bounds.maxX - rightRadius, y: bounds.maxY - rightRadius), radius: rightRadius, startAngle: 0, endAngle: .pi / 2, clockwise: true)
        path.addLine(to: CGPoint(x: bounds.minX + leftRadius, y: bounds.maxY))
        path.addArc(withCenter: CGPoint(x: bounds.minX + leftRadius, y: bounds.maxY - leftRadius), radius: leftRadius, startAngle: .pi / 2, endAngle: .pi, clockwise: true)
        path.addLine(to: CGPoint(x: bounds.minX, y: bounds.minY + leftRadius))
        path.addArc(withCenter: CGPoint(x: bounds.minX + leftRadius, y: bounds.minY + leftRadius), radius: leftRadius, startAngle: .pi, endAngle: 3 * .pi / 2, clockwise: true)
        path.close()
        return path
    }
}
