//
//  BottomPullableView.swift
//  neighbourhood
//
//  Created by Artem Korzh on 11.12.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

typealias ViewConfiguration = ((UIView) -> ())
class BottomPullableView: UIView {

    var configureBackView: ViewConfiguration = {_ in }
    {
        didSet { self.configureBackView(self) }
    }
    var configureIndicatorView: ViewConfiguration = {_ in }
    {
        didSet { self.configureIndicatorView(indicatorView) }
    }

    var onPullDown: () -> Void = {}

    let indicatorView = UIView()

    init(nestedView: UIView) {
        super.init(frame: .zero)
        backgroundColor = .white
        addSubview(indicatorView)
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.backgroundColor = R.color.greyStroke()
        NSLayoutConstraint.activate([
            indicatorView.heightAnchor.constraint(equalToConstant: 5),
            indicatorView.widthAnchor.constraint(equalToConstant: 40),
            indicatorView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            indicatorView.topAnchor.constraint(equalTo: self.topAnchor, constant: 8)
        ])
        indicatorView.cornerRadius = 2.5
        roundCorners(corners: [.topRight, .topLeft], radius: 20)

        addSubview(nestedView)
        nestedView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nestedView.bottomAnchor.constraint(equalTo: bottomAnchor),
            nestedView.leadingAnchor.constraint(equalTo: leadingAnchor),
            nestedView.trailingAnchor.constraint(equalTo: trailingAnchor),
            nestedView.topAnchor.constraint(equalTo: topAnchor, constant: 30)
        ])

        self.configureIndicatorView(indicatorView)
        self.configureBackView(self)
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureHandler(recognizer:)))
        superview?.addGestureRecognizer(panRecognizer)
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureHandler(recognizer:)))
        superview?.addGestureRecognizer(tapRecognizer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func tapGestureHandler(recognizer: UIPanGestureRecognizer) {
        onPullDown()
    }

    @objc private func panGestureHandler(recognizer: UIPanGestureRecognizer) {
        guard let containerView = superview else {
            return
        }
        switch recognizer.state {
        case .changed:
            let translation = recognizer.translation(in: containerView)
            guard translation.y > 0 else {
                return
            }
            print(translation.y)
            frame.origin = CGPoint(x: 0, y: containerView.bounds.height - frame.height + translation.y)
        case .ended:
            if frame.minY < 100 {
                onPullDown()
                return
            }
            let velocity = recognizer.velocity(in: containerView)
            if velocity.y > 1000 {
                onPullDown()
            } else {
                UIView.animate(withDuration: 0.2) {
                    self.frame.origin = CGPoint(x: 0, y: containerView.bounds.height - self.frame.height)
                }
            }
        default:
            break
        }
    }

}
