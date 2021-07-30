//
//  CategoryScrollView.swift
//  neighbourhood
//
//  Created by Dioksa on 11.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import TagListView

protocol CategoryItemDelegate: AnyObject {
    func addNewItem(with title: String, and id: Int)
}

final class CategoryScrollView: UIView {
    @IBOutlet private weak var categoryTitleButton: UIButton!
    @IBOutlet private weak var tagView: TagListView!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var tagViewWidthConstraint: NSLayoutConstraint!
    
    weak var itemDelegate: CategoryItemDelegate?
    
    private var allCategories: [CategoriesData]?
     
      override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }
    
    private func initView() {
        loadFromXib(R.nib.categoryScrollView.name, contextOf: CategoryScrollView.self)
        tagView.delegate = self
        tagView.textFont = R.font.poppinsMedium(size: 13)!
        tagView.tagBackgroundColor = R.color.greyBackground()!
        tagView.textColor = R.color.secondaryBlack()!
    }

    public func addCategoryTags(title: String, items: [CategoriesData], userInterests: [CategoriesData]?) {
        categoryTitleButton.setTitle(title.capitalizingFirstLetter(), for: .normal)
        allCategories = items
        
        items.forEach {
            tagView.addTag($0.title)
        }
        
        userInterests?.forEach { (interest) in
            if (items.first(where: { $0.title == interest.title }) != nil) {
                tagView.tagViews.forEach {
                    if $0.titleLabel?.text == interest.title {
                        $0.tagBackgroundColor = R.color.aliceBlue()!
                        $0.textColor = R.color.accentBlue()!
                    }
                }
            }
        }
        
        let width = tagView.tagViews.map { $0.frame.width }.reduce(0, +)
        tagViewWidthConstraint.constant = width + (CGFloat(tagView.tagViews.count) * 6.0) + 20.0
    }
    
    public func changeColorAfterRemove(tagTitle: String) {
        tagView.tagViews.forEach {
            if $0.titleLabel?.text == tagTitle {
                $0.tagBackgroundColor = R.color.greyBackground()!
                $0.textColor = R.color.secondaryBlack()!
            } 
        }
    }
    
    public func changeToInactiveColor(tagTitle: String) {
        tagView.tagViews.forEach {
            if $0.titleLabel?.text == tagTitle {
                $0.tagBackgroundColor = R.color.aliceBlue()!
                $0.textColor = R.color.accentBlue()!
            }
        }
    }
}

// MARK: - TagListViewDelegate
extension CategoryScrollView: TagListViewDelegate {
    func tagPressed(_ title: String, tagView: TagView, sender: TagListView) -> Void {
        
        guard let tappedTag = allCategories?.first(where: { $0.title == title }) else {
            return
        }
        
        tagView.tagBackgroundColor = R.color.aliceBlue()!
        tagView.textColor = R.color.accentBlue()!
        
        itemDelegate?.addNewItem(with: title, and: tappedTag.id)
    }
}
