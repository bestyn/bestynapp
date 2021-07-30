//
//  PageScrollingHelper.swift
//  neighbourhood
//
//  Created by Dioksa on 21.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

private let SideSpace: CGFloat = 40.0
private let AspectRatio: CGFloat = 0.63
private let WidthSideSpace: CGFloat = 30.0
private let AdditionalHeightSpace: CGFloat = 120.0

final class PageScrollingHelper {
    public func createScrollPages(scrollView: UIScrollView, views: [UIView], completion: @escaping (_ scrollViewSetUp: Bool) -> ()) {
        let numberOfPages = views.count
        let viewWidth = scrollView.frame.size.width
        let viewHeight = scrollView.frame.size.height
        
        var x : CGFloat = 0
        var maxHeight: CGFloat = viewHeight
        
        for i in 0..<numberOfPages {
            let view = views[i]
            let size = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            maxHeight = max(maxHeight, (size.height + AdditionalHeightSpace))
        }
        
        for i in 0..<numberOfPages {
            let view = views[i]
            view.frame = CGRect(x: x, y: 0, width: viewWidth, height: maxHeight)
            scrollView.addSubview(view)
            x = view.frame.origin.x + viewWidth
        }
        
        scrollView.contentSize = CGSize(width: x, height: scrollView.frame.size.height + SideSpace)
        scrollView.heightAnchor.constraint(equalToConstant: maxHeight).isActive = true
        completion(true)
    }

    public func setActiveColors(bottomView: UIView, button: UIButton) {
        bottomView.backgroundColor = R.color.accentBlue()
        button.setTitleColor(R.color.accentBlue(), for: .normal)
    }
    
    public func setDefaultColors(bottomView: UIView, button: UIButton) {
        bottomView.backgroundColor = R.color.greyBackground()
        button.setTitleColor(R.color.greyMedium(), for: .normal)
    }
    
    public func configurePagingScroll(scrollView: UIScrollView, views: [UIView]) {
        let numberOfPages = views.count
        let viewWidth = scrollView.frame.size.width
        let viewHeight = scrollView.frame.size.height
        var x: CGFloat = 0

        for i in 0..<numberOfPages {
            let view = views[i]
            view.frame = CGRect(x: (UIScreen.main.bounds.width - SideSpace) * CGFloat(i), y: 0, width: (UIScreen.main.bounds.width - WidthSideSpace), height: (UIScreen.main.bounds.width - SideSpace) * AspectRatio)
            scrollView.addSubview(view)
            x = view.frame.origin.x + viewWidth
        }

        scrollView.contentSize = CGSize(width: x, height: viewHeight)
    }
}
