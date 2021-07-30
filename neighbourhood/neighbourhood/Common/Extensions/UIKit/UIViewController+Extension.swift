//
//  UIViewController+Extension.swift
//  neighbourhood
//
//  Created by Dioksa on 22.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

extension UIViewController {

    @objc var canHideKeyboard: Bool { true }
    
    var name: String {
        return NSStringFromClass(self.classForCoder).components(separatedBy: ".").last!
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        if canHideKeyboard {
            view.endEditing(true)
        }
    }
    
    func add(child: UIViewController, to viewParent: UIView) {
        addChild(child)
        child.view.frame = viewParent.bounds
        child.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewParent.addSubview(child.view)
        child.didMove(toParent: self)
    }
    
    func remove() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
}

