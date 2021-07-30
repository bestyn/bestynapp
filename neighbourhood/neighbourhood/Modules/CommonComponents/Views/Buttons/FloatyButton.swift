//
//  FloatyButton.swift
//  neighbourhood
//
//  Created by Dioksa on 24.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import Floaty

protocol FloatyButtonActionDelegate: AnyObject {
    func itemWasTapped(type: TypeOfPost)
}

final class FloatyButton: Floaty {
    
    weak var delegate: FloatyButtonActionDelegate?

    public func configureFloatyButton() {
        respondsToKeyboard = false
        paddingY = 60
        paddingX = 24
        buttonColor = R.color.blueButton()!
        itemTitleColor = .white
        plusColor = .white
        overlayColor = UIColor.black.withAlphaComponent(0.6)
    }
    
    public func configureFabAction() {
        items.forEach { removeItem(item: $0) }
        
        func addAction(buttonTitle: String, icon: UIImage?) {
            addItem(buttonTitle, icon: icon, handler: { [weak self] _ in
                guard let strongSelf = self else { return }
                strongSelf.delegate?.itemWasTapped(type: strongSelf.getPostTypeByTitle(buttonTitle))
            })
        }

        addAction(buttonTitle: R.string.localizable.generalFloatyTitle(), icon: R.image.general_post_fab_icon())
        addAction(buttonTitle: R.string.localizable.crimeFilter(), icon: R.image.crime_fab_icon())
        addAction(buttonTitle: R.string.localizable.eventFilter(), icon: R.image.event_fab_icon())
        addAction(buttonTitle: R.string.localizable.newsFilter(), icon: R.image.news_fab_icon())
        
        if ArchiveService.shared.currentProfile?.type == .business {
            addAction(buttonTitle: R.string.localizable.offerFloatyTitle(), icon: R.image.offer_fab_icon())
        }
    }
    
    private func getPostTypeByTitle(_ title: String) -> TypeOfPost {
        switch title {
        case R.string.localizable.generalPostsFilter():
            return .general
        case R.string.localizable.newsFilter():
            return .news
        case R.string.localizable.crimeFilter():
            return .crime
        case R.string.localizable.offerFloatyTitle():
            return .offer
        case R.string.localizable.eventFilter():
            return .event
        default:
            return .general
        }
    }
}
