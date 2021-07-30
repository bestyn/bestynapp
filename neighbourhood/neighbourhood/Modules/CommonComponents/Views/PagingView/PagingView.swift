//
//  PagingView.swift
//  neighbourhood
//
//  Created by Artem Korzh on 07.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

class PagingView: UIView {

    struct PagingChildView {
        let buttonTitle: String
        let view: UIView
    }

    @IBOutlet weak var buttonsStackView: UIStackView!
    @IBOutlet weak var viewsStackView: UIStackView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var viewsStackViewWidthConstraint: NSLayoutConstraint!

    public var views: [PagingChildView] = [] {
        didSet { updateViews() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }

    private func initView() {
        loadFromXib(R.nib.pagingView.name, contextOf: PagingView.self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    private func updateViews() {
        buttonsStackView.arrangedSubviews.forEach({$0.removeFromSuperview()})
        viewsStackView.arrangedSubviews.forEach({$0.removeFromSuperview()})
        for view in views {
            let button = createButton(for: view)
            buttonsStackView.addArrangedSubview(button)
            viewsStackView.addArrangedSubview(view.view)
        }
        
        let newConstraint = viewsStackViewWidthConstraint.withMultiplier(CGFloat(views.count))
        viewsStackViewWidthConstraint.replaceWith(newConstraint)
        viewsStackViewWidthConstraint = newConstraint
        (buttonsStackView.arrangedSubviews.first as? PagingButton)?.isSelected = true
        setNeedsLayout()
    }

    private func createButton(for view: PagingChildView) -> UIButton {
        let button = PagingButton()
        button.setTitle(view.buttonTitle, for: .normal)
        button.addTarget(self, action: #selector(didTapButton(sender:)), for: .touchUpInside)
        return button
    }

    @objc private func didTapButton(sender: PagingButton) {
        guard let index = buttonsStackView.arrangedSubviews.firstIndex(of: sender) else {
            return
        }
        setSelectedButton(at: index)
        let offset = CGFloat(index) * scrollView.frame.size.width
        scrollView.setContentOffset(CGPoint(x: offset, y: 0) , animated: true)
    }

    private func setSelectedButton(at selectedIndex: Int) {
        for (index, button) in buttonsStackView.arrangedSubviews.compactMap({$0 as? PagingButton}).enumerated() {
            button.isSelected = index == selectedIndex
        }
    }
}

extension PagingView: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let index = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        setSelectedButton(at: index)
    }
}
