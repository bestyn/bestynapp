//
//  CircularProgressView.swift
//  neighbourhood
//
//  Created by iphonovv on 26.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

class CircularProgressView: UIView {
    
    var progressLyr = CAShapeLayer()
    var trackLyr = CAShapeLayer()
    
    var progressClr = UIColor(red: 0.268, green: 0.746, blue: 0.18, alpha: 1) {
       didSet {
          progressLyr.strokeColor = progressClr.cgColor
       }
    }
    
    var trackClr = UIColor.white {
       didSet {
          trackLyr.strokeColor = trackClr.cgColor
       }
    }

    
    required init?(coder aDecoder: NSCoder) {
       super.init(coder: aDecoder)
       makeCircularPath()
    }
    
    private func makeCircularPath() {
        self.backgroundColor = UIColor.clear
        self.layer.cornerRadius = self.frame.size.width/2
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: frame.size.width/2, y: frame.size.height/2), radius: (frame.size.width - 1.5)/2, startAngle: CGFloat(-0.5 * .pi), endAngle: CGFloat(1.5 * .pi), clockwise: true)
        progressLyr.path = circlePath.cgPath
        progressLyr.fillColor = UIColor.clear.cgColor
        progressLyr.strokeColor = progressClr.cgColor
        progressLyr.lineWidth = 1.0
        progressLyr.strokeEnd = 0
        progressLyr.borderWidth = 1
        progressLyr.borderColor = UIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 0.2).cgColor
        layer.addSublayer(progressLyr)
    }
    
    func setProgressWithAnimation(value: Float) {
        DispatchQueue.main.async {
            let finalValue = CGFloat(value)
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.progressLyr.strokeEnd = finalValue
            CATransaction.commit()
        }
    }
    
    func pauseAnimation(){
        let pausedTime = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = 0.0
        layer.timeOffset = pausedTime
    }
    
    func resumeAnimation(){
        let pausedTime = layer.timeOffset
        layer.speed = 1.0
        layer.timeOffset = 0.0
        layer.beginTime = 0.0
        let timeSincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        layer.beginTime = timeSincePause
    }
}
