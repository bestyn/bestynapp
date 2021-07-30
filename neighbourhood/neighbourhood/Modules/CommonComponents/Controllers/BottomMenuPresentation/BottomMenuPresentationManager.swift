//
//  BottomMenuPresentationManager.swift
//  neighbourhood
//
//  Created by Artem Korzh on 16.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

protocol BottomMenuPresentable where Self: UIViewController {
    var transitionManager: BottomMenuPresentationManager! { get set }
    var presentedViewHeight: CGFloat { get }
}

class BottomMenuPresentationManager: NSObject, UIViewControllerTransitioningDelegate {
    
    var configureBackView: ViewConfiguration = {_ in }
    var configureIndicatorView: ViewConfiguration = {_ in }
    var configureDimingView: ViewConfiguration = {_ in }
    var onDismiss: () -> Void = {}
    
    var topMargin: CGFloat = 30

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let controller = BottomMenuPresentationController(presentedViewController: presented, presenting: presenting)
        controller.topMargin = self.topMargin
        
        controller.configureBackView = self.configureBackView
        controller.configureIndicatorView = self.configureIndicatorView
        controller.configureDimingView = self.configureDimingView
        controller.onDismiss = self.onDismiss
        
        return controller
    }
}

extension BottomMenuPresentationManager {
    static func present(
        _ controller: BottomMenuPresentable,
        from presenter: UIViewController,
        topMargin: CGFloat? = nil,
        configureBackView: ((UIView) -> ())? = nil,
        configureIndicatorView: ((UIView) -> ())? = nil,
        configureDimingView: ((UIView) -> ())? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        let controller = controller
        let transitionManager = controller.transitionManager
        controller.transitioningDelegate = controller.transitionManager
        if let configureBackView = configureBackView {
            transitionManager?.configureBackView  = configureBackView
        }
        transitionManager?.topMargin = topMargin ?? 30
        if let configureIndicatorView = configureIndicatorView {
            transitionManager?.configureIndicatorView = configureIndicatorView
        }
        if let configureDimingView = configureDimingView {
            transitionManager?.configureDimingView = configureDimingView
        }
        if let onDismiss = onDismiss {
            transitionManager?.onDismiss = onDismiss
        }
        controller.transitionManager = transitionManager

        controller.modalPresentationStyle = .custom
        
        presenter.present(controller, animated: true)
    }
}
