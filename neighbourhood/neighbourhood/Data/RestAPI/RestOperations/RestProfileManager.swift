//
//  RestProfileManager.swift
//  neighbourhood
//
//  Created by Dioksa on 30.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GBKSoftRestManager

final class RestProfileManager: RestOperationsManager {
    private let postExpand = "totalMessages, media, categories, profile, media.formatted,profile.avatar.formatted,iFollow,counters,myReaction,media.counters"
    
    func getUser() -> PreparedOperation<UserModel> {
        
        let query: [String: Any] = [
            "expand": "profile.avatar.formatted, businessProfiles.avatar.formatted, profile.hasUnreadMessages, businessProfiles.hasUnreadMessages,businessProfiles.hashtags, businessProfiles.counters, profile.hashtags, profile.counters"
        ]
        
        let request = Request(
            url: RestURL.Profile.profile,
            method: .get,
            query: query,
            withAuthorization: true)
        
        return prepare(request: request)
    }
    
    func changeUserProfile(data: UpdateProfileData?,
                           image: UIImage? = nil) -> PreparedOperation<UserProfileModel> {
        
        var userImage: [String: RequestMedia]?
        
        if let compressedImage = image?.compress(maxSizeMB: 1) {
            userImage = ["image": .jpg(compressedImage, nil)]
        }

        let request = Request(
            url: RestURL.Profile.changeProfile,
            method: .patch,
            query: ["expand": "hashtags, avatar.formatted"],
            withAuthorization: true,
            body: data,
            media: userImage)
        
        return prepare(request: request)
    }
    
    func removeUserAvatar() -> PreparedOperation<UserProfileModel> {
        
        let request = Request(
            url: RestURL.Profile.changeProfile,
            method: .patch,
            query: ["expand": "hashtags"],
            withAuthorization: true,
            body: ["image": "undefined"])
        
        return prepare(request: request)
    }
    
    func changeProfilePassword(data: ProfilePasswordData) -> PreparedOperation<Empty> {
        
        let request = Request(
            url: RestURL.Profile.changePassword,
            method: .patch,
            withAuthorization: true,
            body: data)
        
        return prepare(request: request)
    }
    
    func changeProfileEmail(email: String) -> PreparedOperation<Empty> {
        
        let request = Request(
            url: RestURL.Profile.changeEmail,
            method: .post,
            withAuthorization: true,
            body: ["newEmail": email])
        
        return prepare(request: request)
    }
    
    func getPublicProfile(profileId: Int) -> PreparedOperation<PublicProfileModel> {
        
        let query: [String: Any] = [
            "expand": "avatar.formatted, hashtags, isFollowed, isFollower"
        ]
        
        let request = Request(
            url: RestURL.Profile.getPublicProfile(profileId),
            method: .get,
            query: query,
            withAuthorization: true)
        
        return prepare(request: request)
    }
    
    func saveHashtags(hashtagsIds: [Int]) -> PreparedOperation<UserProfileModel> {
        
        let request = Request(
            url: RestURL.Profile.changeProfile,
            method: .patch,
            query: ["expand": "hashtags"],
            withAuthorization: true,
            body: ["hashtagIds": hashtagsIds])
        
        return prepare(request: request)
    }
    
    func getMediaPosts(by profileId: Int,
                       page: Int) -> PreparedOperation<[PostModel]> {
        
        let query: [String: Any] = [
            "profileId": profileId,
            "types": [TypeOfPost.media],
            "page": page,
            "expand": postExpand]
        
        let request = Request(
            url: RestURL.Profile.getPosts,
            method: .get,
            query: query,
            withAuthorization: true)

        return prepare(request: request)
    }

    func searchProfile(search: String, page: Int) -> PreparedOperation<[PostProfileModel]> {
        let query: [String: Any] = [
            "expand": "avatar.formatted, address,isFollowed,isFollower",
            "page": page,
            "fullName": search
        ]
        let request = Request(
            url: RestURL.Profile.list,
            method: .get,
            query: query,
            withAuthorization: true)

        return prepare(request: request)
    }

    func searchProfileForMention(search: String, page: Int) -> PreparedOperation<[PostProfileModel]> {
        let query: [String: Any] = [
            "expand": "avatar.formatted, address,isFollowed,isFollower",
            "page": page,
            "sort" : "-isFollowed,fullName",
            "fullName": search
        ]
        let request = Request(
            url: RestURL.Profile.list,
            method: .get,
            query: query,
            withAuthorization: true)

        return prepare(request: request)
    }

    func getBasicProfileType(profileId: Int) -> PreparedOperation<UserProfileTypeModel> {
        let request = Request(
            url: RestURL.Profile.getPublicProfile(profileId),
            method: .get, query: ["fields": "type"],
            withAuthorization: true)
        return prepare(request: request)
    }

    func getBusinessProfileType(profileId: Int) -> PreparedOperation<UserProfileTypeModel> {
        let request = Request(
            url: RestURL.BusinessProfile.getBusinessProfile(profileId),
            method: .get, query: ["fields": "type"],
            withAuthorization: true)
        return prepare(request: request)
    }
}
