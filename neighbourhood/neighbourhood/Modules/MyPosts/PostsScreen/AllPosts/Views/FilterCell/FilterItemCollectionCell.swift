//
//  FilterItemCollectionCell.swift
//  neighbourhood
//
//  Created by Dioksa on 26.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

final class FilterItemCollectionCell: UICollectionViewCell {
    @IBOutlet private weak var filterRoundedView: UIView!
    @IBOutlet private weak var filterTitleLabel: UILabel!
    
    override var isSelected: Bool {
        didSet { updateSelectedState() }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        updateSelectedState()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        filterRoundedView.cornerRadius = 15
    }
    
    func setFilterTitle(_ title: String) {
        filterTitleLabel.text = title
    }
    
    func getFilterTitle() -> TypeOfPost {
        switch filterTitleLabel.text {
        case R.string.localizable.generalPostsFilter():
            return .general
        case R.string.localizable.newsFilter():
            return .news
        case R.string.localizable.crimeFilter():
            return .crime
        case R.string.localizable.businessFilter():
            return .onlyBusiness
        case R.string.localizable.eventFilter():
            return .event
        case R.string.localizable.offersFilter():
            return .offer
        case R.string.localizable.mediaFilter():
            return .media
        default:
            return .general
        }
    }

    private func updateSelectedState() {
        if isSelected {
            filterRoundedView.backgroundColor = R.color.blueButton()
            filterTitleLabel.textColor = .white
        } else {
            filterRoundedView.backgroundColor = R.color.greyBackground()
            filterTitleLabel.textColor = R.color.secondaryBlack()
        }
    }
}
