//
//  PopoverViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 09.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

protocol PopoverPresentedView where Self: UIView {
    var popoverPresenter: PopoverViewController? { get set }
}

protocol PopoverPresentedViewController where Self: UIViewController {
    var popoverPresenter: PopoverViewController? { get set }
}

typealias PopoverClosed = () -> Void

class PopoverViewController: UIViewController {

    @IBOutlet weak var dimmingView: UIView!
    @IBOutlet weak var popoverView: UIView!
    @IBOutlet weak var containerView: UIView!

    private var childView: UIView
    private var origin: CGPoint = .zero


    static func present(with view: PopoverPresentedView, from presenter: UIViewController) {
        let controller = PopoverViewController(view: view)
        presenter.present(controller, animated: false, completion: nil)
    }

    init(view: PopoverPresentedView) {
        childView = view
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .crossDissolve
        view.popoverPresenter = self
    }

    init(viewController: PopoverPresentedViewController) {
        childView = viewController.view
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overCurrentContext
        modalTransitionStyle = .crossDissolve
        viewController.popoverPresenter = self
        addChild(viewController)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        setupPopoverView()
        setupChildView()
        setupGestures()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        popoverView.transform = CGAffineTransform(translationX: 0, y: popoverView.bounds.height)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        origin = popoverView.frame.origin
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showPopover()
    }
}

extension PopoverViewController {
    public func close(completion: PopoverClosed? = nil) {
        closePopover(completion: completion)
    }
}

// MARK: - Private functions

extension PopoverViewController {
    private func setupPopoverView() {
        popoverView.roundCorners(corners: [.topLeft, .topRight], radius: 20)
    }

    private func setupChildView() {
        containerView.addSubview(childView)
        childView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            childView.topAnchor.constraint(equalTo: containerView.topAnchor),
            childView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            childView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            childView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
    }

    private func setupGestures() {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureHandler))
        popoverView.addGestureRecognizer(gesture)
        gesture.delegate = self

    }

    @objc private func panGestureHandler(_ recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .ended {
            closePopover()
            return
        }
        let translation = recognizer.translation(in: popoverView)
        let moveY = (translation.y + popoverView.frame.minY) > origin.y ? translation.y : 0
        popoverView.transform = CGAffineTransform(translationX: 0, y: moveY)
    }

    private func showPopover() {
        UIView.animate(withDuration: 0.5) {
            self.dimmingView.alpha = 1
            self.popoverView.transform = .identity
        }
    }

    private func closePopover(completion: PopoverClosed? = nil) {
        UIView.animate(withDuration: 0.5) {
            self.dimmingView.alpha = 0
            self.popoverView.transform = CGAffineTransform(translationX: 0, y: self.popoverView.bounds.height)
        } completion: { (_) in
            self.dismiss(animated: false) {
                completion?()
            }
        }
    }
}

extension PopoverViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}
