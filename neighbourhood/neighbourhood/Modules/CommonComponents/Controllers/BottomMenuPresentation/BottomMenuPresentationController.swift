//
//  BottomMenuPresentationController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 16.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

class BottomMenuPresentationController: UIPresentationController {

    var configureBackView: ViewConfiguration = {_ in }
    var configureIndicatorView: ViewConfiguration = {_ in }
    var configureDimingView: ViewConfiguration = {_ in }
    var onDismiss: () -> Void = {}
    
    var topMargin: CGFloat = 30
    
    var presentedViewHeight: CGFloat {
        let maxHeight = UIScreen.main.bounds.height - 50
        var height = (presentedViewController as? BottomMenuPresentable)?.presentedViewHeight ??
            presentedView?.frame.height ?? maxHeight
        if #available(iOS 11.0, *) {
            let safeAreaInset = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
            height += safeAreaInset
        }
        return min(height, maxHeight)
    }

    override var presentedView: UIView? {
        guard let sourceView = super.presentedView else {
            return nil
        }
        if let view = sourceView.superview {
            return view
        }
        if pullableView == nil {
            pullableView = BottomPullableView(nestedView: sourceView)
        }
        containerView?.addSubview(pullableView)
        pullableView.configureBackView = configureBackView
        pullableView.configureIndicatorView = configureIndicatorView
        pullableView.onPullDown = { self.dismissPresentedController() }

        return pullableView
    }

    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
    override func containerViewDidLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        presentedView?.frame = frameOfPresentedViewInContainerView
    }

    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        return CGSize(width: parentSize.width, height: presentedViewHeight + self.topMargin)
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        var frame: CGRect = .zero
        guard let containerView = containerView else {
            return frame
        }
        frame.size = size(forChildContentContainer: presentedViewController, withParentContainerSize: containerView.bounds.size)
        frame.origin = CGPoint(x: 0, y: containerView.bounds.height - frame.size.height)

        return frame
    }

    private lazy var dimmingView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        view.alpha = 0
        self.configureDimingView(view)
        return view
    }()

    private var pullableView: BottomPullableView!

    override func presentationTransitionWillBegin() {
        guard let containerView = containerView else {
            return
        }
        containerView.insertSubview(dimmingView, at: 0)

        NSLayoutConstraint.activate([
            dimmingView.topAnchor.constraint(equalTo: containerView.topAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])

        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 1.0
            return
        }

        coordinator.animate { (_) in
            self.dimmingView.alpha = 1.0
        }
    }

    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 0.0
            return
        }

        coordinator.animate { (_) in
            self.dimmingView.alpha = 0.0
        }
    }

    @objc private func dismissPresentedController() {
        presentedViewController.dismiss(animated: true)
        onDismiss()
    }
}
