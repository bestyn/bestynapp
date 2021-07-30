//
//  PostProfileModel+Extension.swift
//  neighbourhood
//
//  Created by Artem Korzh on 10.03.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import Foundation

extension PublicProfileModel {
    var postProfile: PostProfileModel {
        return .init(id: id, fullName: fullName, type: .basic, avatar: avatar, isFollowed: isFollowed, isFollower: isFollower)
    }
}


extension BusinessProfile {
    var postProfile: PostProfileModel {
        return .init(id: id, fullName: fullName, type: .basic, avatar: avatar, isFollowed: isFollowed, isFollower: isFollower)
    }
}
