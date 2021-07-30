//
//  SelectorProfileModel.swift
//  neighbourhood
//
//  Created by Artem Korzh on 21.08.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

enum ProfileType: String, Codable {
    case basic
    case business

    var title: String {
        switch self {
        case .basic:
            return ""
        case .business:
            return self.rawValue.capitalizingFirstLetter()
        }
    }
}

struct SelectorProfileModel: Codable {
    let id: Int
    let fullName: String
    let avatar: ImageModel?
    let type: ProfileType
    let address: String?
    let dateOfCreation: Date?
    var hasUnreadMessages: Bool?
    var longitude: Float?
    var latitude: Float?
    var hashtags: [HashtagModel]

    init(from profile: UserProfileModel) {
        id = profile.id
        fullName = profile.fullName
        avatar = profile.avatar
        type = .basic
        address = profile.address
        dateOfCreation = profile.createdAt
        hasUnreadMessages = profile.hasUnreadMessages
        longitude = profile.longitude
        latitude = profile.latitude
        hashtags = profile.hashtags
    }

    init(from profile: BusinessProfile) {
        id = profile.id
        fullName = profile.fullName
        avatar = profile.avatar
        type = .business
        address = profile.address
        dateOfCreation = profile.createdAt
        hasUnreadMessages = profile.hasUnreadMessages
        longitude = profile.longitude
        latitude = profile.latitude
        hashtags = profile.hashtags
    }

    init(from profile: PublicProfileModel) {
        id = profile.id
        fullName = profile.fullName
        avatar = profile.avatar
        type = .business
        address = profile.address
        dateOfCreation = nil
        hasUnreadMessages = nil
        longitude = nil
        latitude = nil
        hashtags = []
    }
}


extension UserProfileModel {
    var selectorProfile: SelectorProfileModel {
        SelectorProfileModel(from: self)
    }
}

extension BusinessProfile {
    var selectorProfile: SelectorProfileModel {
        SelectorProfileModel(from: self)
    }
}

extension PublicProfileModel {
    var selectorProfile: SelectorProfileModel {
        SelectorProfileModel(from: self)
    }
}
