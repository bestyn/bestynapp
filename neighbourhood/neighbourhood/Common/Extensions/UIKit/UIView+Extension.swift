//
//  UIView+Extension.swift
//  neighbourhood
//
//  Created by Dioksa on 23.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

extension UIView {
    
    class var identifier: String {
        return String(describing: self)
    }
    
    var name: String {
        return NSStringFromClass(self.classForCoder).components(separatedBy: ".").last!
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            clipsToBounds = newValue > 0
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            guard let cgColor = layer.borderColor else {
                return nil
            }
            return UIColor(cgColor: cgColor)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
    func dropShadow(color: UIColor = .gray, opacity: Float = 1, offSet: CGSize = CGSize(width: 0, height: 0), radius: CGFloat = 50) {
        layer.masksToBounds = false
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offSet
        layer.shadowRadius = radius
    }
    
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        if #available(iOS 11.0, *) {
            clipsToBounds = true
            layer.cornerRadius = radius
            layer.maskedCorners = CACornerMask(rawValue: corners.rawValue)
        } else {
            let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            layer.mask = mask
        }
    }
    
    func loadFromXib(_ nibName: String, contextOf: UIView.Type) {
        let nibView = Bundle(for: contextOf).loadNibNamed(nibName, owner: self, options: nil)!.first as! UIView
        
        nibView.frame = CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height)
        nibView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(nibView)
        nibView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        nibView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        nibView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        nibView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    var screenshot: UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
        drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    var exactScreenshot: UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.frame.size, false, UIScreen.main.scale)
        drawHierarchy(in: self.frame.offsetBy(dx: -frame.minX, dy: -frame.minY), afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    func fadeIn(duration: TimeInterval = 0.5,
                delay: TimeInterval = 0.0,
                completion: @escaping ((Bool) -> Void) = {(finished: Bool) -> Void in }) {
      UIView.animate(withDuration: duration,
                     delay: delay,
                     options: .curveEaseIn,
                     animations: {
        self.alpha = 1.0
      }, completion: completion)
    }

    func fadeOut(duration: TimeInterval = 0.5,
                 delay: TimeInterval = 0.0,
                 completion: @escaping (Bool) -> Void = {(finished: Bool) -> Void in }) {
      UIView.animate(withDuration: duration,
                     delay: delay,
                     options: .curveEaseIn,
                     animations: {
        self.alpha = 0.0
      }, completion: completion)
    }
    
    func addGradientLayer(colors: [UIColor]) -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors.map({ $0.cgColor })
        gradientLayer.startPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 1.0)
        
        self.layer.insertSublayer(gradientLayer, at: 0)
        return gradientLayer
    }

    var frameWithTransform: CGRect {
        var rect = bounds
        let path = CGMutablePath()
        rect.origin = .zero
        path.addRect(rect, transform: transform)
        return path.boundingBox
    }
    
    func addRadialGradientLayer(colors: [UIColor]) -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors.map({ $0.cgColor })
        gradientLayer.startPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 1.0)
        
        self.layer.insertSublayer(gradientLayer, at: 0)
        return gradientLayer
    }
}
