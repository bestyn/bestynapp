//
//  RestFollowManager.swift
//  neighbourhood
//
//  Created by Artem Korzh on 09.03.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import Foundation
import GBKSoftRestManager

class RestProfileFollowManager: RestOperationsManager {

    func followList(page: Int, data: ProfilesData) -> PreparedOperation<[PostProfileModel]> {
        var query: [String: Any] = [
            "expand": "avatar.formatted,isFollower,isFollowed",
            "page": page,
        ]
        if let isFollowed = data.isFollowed {
            query["isFollowed"] = isFollowed
        }
        if let isFollower = data.isFollower {
            query["isFollower"] = isFollower
        }
        if let fullName = data.fullName {
            query["fullName"] = fullName
        }
        if let type = data.type {
            query["type"] = type.rawValue
        }
        let request = Request(
            url: RestURL.Profile.list,
            method: .get,
            query: query,
            withAuthorization: true)
        return prepare(request: request)
    }

    func follow(profile: PostProfileModel) -> PreparedOperation<Empty> {
        let request = Request(
            url: RestURL.Profile.follow(id: profile.id),
            method: .post,
            withAuthorization: true)

        return prepare(request: request)
    }

    func unfollow(profile: PostProfileModel) -> PreparedOperation<Empty> {
        let request = Request(
            url: RestURL.Profile.follow(id: profile.id),
            method: .delete,
            withAuthorization: true)

        return prepare(request: request)
    }

    func removeFollower(profile: PostProfileModel) -> PreparedOperation<Empty> {
        let request = Request(
            url: RestURL.Profile.follower(id: profile.id),
            method: .delete,
            withAuthorization: true)

        return prepare(request: request)
    }
}
