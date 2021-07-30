//
//  RadialGradientView.swift
//  neighbourhood
//
//  Created by Administrator on 26.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

@IBDesignable
class RadialGradientView: UIView {

    @IBInspectable var insideColor: UIColor = UIColor.clear
    @IBInspectable var middleColor: UIColor = UIColor.clear
    @IBInspectable var outsideColor: UIColor = UIColor.clear

    override func draw(_ rect: CGRect) {
        drawGradient([insideColor, middleColor, outsideColor])
    }
    
    func setupColors(_ colors: [UIColor?]) {
        let strColors = colors.compactMap {$0}
        guard strColors.count > 1 else {
            return
        }
        insideColor = strColors[0]
        
        if strColors.count == 2 {
            outsideColor = strColors[1]
        }
        else if strColors.count == 3 {
            middleColor = strColors[1]
            outsideColor = strColors[2]
        }
        setNeedsDisplay()
    }
    
    func drawGradient(_ colors: [UIColor]) {
        let cgColors = colors.map {$0.cgColor}
        let endRadius = min(frame.width, frame.height) / 2
        let center = CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
        let gradient = CGGradient(colorsSpace: nil, colors: cgColors  as CFArray, locations: nil)
        UIGraphicsGetCurrentContext()?.drawRadialGradient(gradient!, startCenter: center, startRadius: 0.0, endCenter: center, endRadius: endRadius, options: CGGradientDrawingOptions.drawsBeforeStartLocation)
        cornerRadius = bounds.size.width / 2
    }
}
