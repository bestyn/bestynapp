//
//  TypeOfPost+Extension.swift
//  neighbourhood
//
//  Created by Artem Korzh on 16.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

extension TypeOfPost {

    var filterTitle: String {
        switch self {
        case .general:
            return R.string.localizable.generalPostsFilter()
        case .news:
            return R.string.localizable.newsFilter()
        case .crime:
            return R.string.localizable.crimeFilter()
        case .offer:
            return R.string.localizable.offersFilter()
        case .event:
            return R.string.localizable.eventFilter()
        case .onlyBusiness:
            return R.string.localizable.businessFilter()
        case .media:
            return R.string.localizable.mediaFilter()
        case .shared:
            return R.string.localizable.sharedFilter()
        case .repost:
            return R.string.localizable.repostFilter()
        case .story:
            return R.string.localizable.storiesFilter()
        }
    }

    var detailsTitle: String {
        switch self {
        case .general:
            return R.string.localizable.generalPostsTitle()
        case .news:
            return R.string.localizable.newsTitle()
        case .crime:
            return R.string.localizable.crimeTitle()
        case .offer:
            return R.string.localizable.offersTitle()
        case .event:
            return R.string.localizable.eventTitle()
        default:
            return title
        }
    }

    var title: String {
        return rawValue.capitalized
    }
    
    var icon: UIImage? {
        return UIImage(named: "\(rawValue)_icon")
    }

    var markBackgroundColor: UIColor? {
        switch self {
        case .news:
            return R.color.accent3Transparent()
        case .crime:
            return R.color.darkGreyTransparent()
        case .offer:
            return R.color.accentBlueLabelTransparent()
        case .event:
            return R.color.accentRedTransparent()
        case .media:
            return R.color.pinkTransparent()
        default:
            return nil
        }
    }

    var markTextColor: UIColor? {
        switch self {
        case .news:
            return R.color.accent3()
        case .crime:
            return R.color.darkGrey()
        case .offer:
            return R.color.accentBlueLabel()
        case .event:
            return R.color.accentRed()
        case .media:
            return R.color.pinkLabelColor()
        default:
            return nil
        }
    }
    
    var deleteAlertTitle: String {
        switch self {
        case .event: return Alert.Title.deleteEvent
        case .media: return Alert.Title.deleteImage
        default: return Alert.Title.deletePost
        }
    }
    
    var deleteSuccessMessage: String {
        switch self {
        case .event:    return R.string.localizable.eventDeleted()
        case .media:    return R.string.localizable.removedImage()
        default:        return R.string.localizable.postDeleted()
        }
    }
}
