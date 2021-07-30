//
//  RestStoriesManager.swift
//  neighbourhood
//
//  Created by Artem Korzh on 07.12.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import GBKSoftRestManager

class RestStoriesManager: RestOperationsManager {
    private let postExpand = "totalMessages, media, categories, profile, media.formatted,profile.avatar.formatted,iFollow,counters,myReaction, audio.profile, audio.isFavorite,profile.isFollower,profile.isFollowed"

    struct PagingData {
        var page: Int? = nil
        var idAfter: Int? = nil
        var idBefore: Int? = nil
    }

    func getAllStories(hashtags: [Int] = [], paging: PagingData) -> PreparedOperation<[StoryListModel]> {
        var query: [String: Any] = [
            "types": [TypeOfPost.story],
            "hashtagIds": hashtags,
            "sort": "-createdAt",
            "expand": postExpand]
        if let page = paging.page {
            query["page"] = page
        } else if let idBefore = paging.idBefore {
            query["idBefore"] = idBefore
        } else if let idAfter = paging.idAfter {
            query["idAfter"] = idAfter
        }

        let request = Request(
            url: RestURL.MyPosts.globalPosts,
            method: .get,
            query: query,
            withAuthorization: true)

        return prepare(request: request)
    }

    func getMyStories(paging: PagingData) -> PreparedOperation<[StoryListModel]> {
        var query: [String: Any] = [
            "types": [TypeOfPost.story],
            "authorIsMe": 1,
            "sort": "-createdAt",
            "expand": postExpand
        ]
        if let page = paging.page {
            query["page"] = page
        } else if let idBefore = paging.idBefore {
            query["idBefore"] = idBefore
        } else if let idAfter = paging.idAfter {
            query["idAfter"] = idAfter
        }

        let request = Request(
            url: RestURL.MyPosts.getMyPosts,
            method: .get,
            query: query,
            withAuthorization: true)

        return prepare(request: request)
    }

    func createStory(data: StoryData, fileURL: URL) -> PreparedOperation<PostModel> {
        let request = Request(url: RestURL.Stories.create,
                              method: .post,
                              query: ["expand": postExpand],
                              withAuthorization: true,
                              body: data,
                              media: ["file": .mp4(fileURL)])
        return prepare(request: request)
    }

    func updateStory(id: Int, data: StoryData) -> PreparedOperation<PostModel> {
        let request = Request(url: RestURL.Stories.edit(id: id),
                              method: .patch,
                              query: ["expand": postExpand],
                              withAuthorization: true,
                              body: data)
        return prepare(request: request)
    }

    func getStoriesByAudio(audioTrackID: Int, paging: PagingData) -> PreparedOperation<[StoryListModel]> {
        var query: [String: Any] = [
            "types": [TypeOfPost.story],
            "sort": "-createdAt",
            "audioId": audioTrackID,
            "expand": postExpand
        ]
        if let page = paging.page {
            query["page"] = page
        } else if let idBefore = paging.idBefore {
            query["idBefore"] = idBefore
        } else if let idAfter = paging.idAfter {
            query["idAfter"] = idAfter
        }

        let request = Request(
            url: RestURL.MyPosts.globalPosts,
            method: .get,
            query: query,
            withAuthorization: true)

        return prepare(request: request)
    }
}
