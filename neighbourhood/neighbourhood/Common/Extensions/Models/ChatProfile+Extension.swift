//
//  ChatProfile+Extension.swift
//  neighbourhood
//
//  Created by Artem Korzh on 19.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

extension UserProfileModel {
    var chatProfile: ChatProfile {
        ChatProfile(id: id, avatar: avatar, fullName: fullName, type: .basic, isOnline: false)
    }
}

extension BusinessProfile {
    var chatProfile: ChatProfile {
        ChatProfile(id: id, avatar: avatar, fullName: fullName, type: .business, isOnline: false)
    }
}

extension PostProfileModel {
    var chatProfile: ChatProfile {
        ChatProfile(id: id, avatar: avatar, fullName: fullName, type: type, isOnline: false)
    }
}

extension PublicProfileModel {
    var chatProfile: ChatProfile {
        ChatProfile(id: id, avatar: avatar, fullName: fullName, type: .basic, isOnline: false)
    }
}
