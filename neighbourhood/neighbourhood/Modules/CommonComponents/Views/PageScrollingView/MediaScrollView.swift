//
//  MediaScrollView.swift
//  neighbourhood
//
//  Created by Artem Korzh on 14.09.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

class MediaScrollView: UIScrollView {

    public var views: [UIView] = [] {
        didSet { updateNestedViews() }
    }

    override func layoutSubviews() {
        updateNestedViewsSizes()
        super.layoutSubviews()
    }

    private func updateNestedViews() {
        self.subviews.forEach({ $0.removeFromSuperview() })
        views.forEach { (view) in
            self.addSubview(view)
        }
        updateNestedViewsSizes()
    }

    private func updateNestedViewsSizes() {
        let selfSize = bounds.size
        for (position, view) in views.enumerated() {
            let origin = CGPoint(x: CGFloat(position) * selfSize.width, y: 0)
            let size = selfSize
            view.frame = CGRect(origin: origin, size: size)
        }
        self.contentSize = CGSize(width: selfSize.width * CGFloat(views.count), height: selfSize.height)
    }


}
