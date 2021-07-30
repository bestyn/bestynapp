//
//  RestMyPostsManager.swift
//  neighbourhood
//
//  Created by Dioksa on 25.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GBKSoftRestManager

final class RestMyPostsManager: RestOperationsManager {

    private let postExpand = "totalMessages, media, categories, profile, media.formatted,profile.avatar.formatted,iFollow,counters,myReaction,profile.isFollower,profile.isFollowed,media.counters"

    func addPost(postType: TypeOfPost,
                 data: PostData) -> PreparedOperation<PostModel> {
        
        let request = Request(
            url: RestURL.MyPosts.createPost(type: postType),
            method: .post,
            query: ["expand": postExpand],
            withAuthorization: true,
            body: data)
        
        return prepare(request: request)
    }

    func addImageToPost(postID: Int, imageData: UploadImageData) -> PreparedOperation<MediaDataModel> {
        let request = Request(
            url: RestURL.MyPosts.addMedia(postID),
            method: .post,
            withAuthorization: true,
            body: imageData.crop,
            media: ["file": .jpg(imageData.image, nil)])

        return prepare(request: request)
    }

    func addVideoToPost(postID: Int, videoURL: URL) -> PreparedOperation<MediaDataModel> {
        let request = Request(
            url: RestURL.MyPosts.addMedia(postID),
            method: .post,
            withAuthorization: true,
            media: ["file": .mp4(videoURL)])

        return prepare(request: request)
    }

    func addAudioToPost(postID: Int, audioURL: URL) -> PreparedOperation<MediaDataModel> {
        let request = Request(
            url: RestURL.MyPosts.addMedia(postID),
            method: .post,
            withAuthorization: true,
            media: ["file": .custom(fileURL: audioURL, contentType: audioURL.mimeType)])

        return prepare(request: request)
    }

    func deleteMediaToPost(mediaId: Int) -> PreparedOperation<Empty> {
        
        let request = Request(
            url: RestURL.MyPosts.deleteMedia(mediaId),
            method: .delete,
            withAuthorization: true)
        
        return prepare(request: request)
    }
    
    func getPost(postId: Int) -> PreparedOperation<PostModel> {
        
        let query: [String: Any] = [
            "expand": postExpand
        ]
        
        let request = Request(
            url: RestURL.MyPosts.anyPost(postId),
            method: .get,
            query: query,
            withAuthorization: true)
        
        return prepare(request: request)
    }
    
    func getMyPost(search: String = "",
                   types: [TypeOfPost],
                   authorMe: Int = 1,
                   page: Int) -> PreparedOperation<[PostModel]> {
        
        let query: [String: Any] = [
            "types": types,
            "search": search,
            "authorIsMe": authorMe,
             "page": page,
            "expand": postExpand
        ]
        
        let request = Request(
            url: RestURL.MyPosts.getMyPosts,
            method: .get,
            query: query,
            withAuthorization: true)
        
        return prepare(request: request)
    }
    
    func updatePost(postType: TypeOfPost,
                    postId: Int,
                    data: PostData) -> PreparedOperation<PostModel> {
        
        let request = Request(
            url: RestURL.MyPosts.getPost(type: postType, postId: postId),
            method: .patch,
            query: ["expand": postExpand],
            withAuthorization: true,
            body: data)
        
        return prepare(request: request)
    }
    
    func deletePost(postId: Int) -> PreparedOperation<Empty> {
        
        let request = Request(
            url: RestURL.MyPosts.anyPost(postId),
            method: .delete,
            withAuthorization: true)
        
        return prepare(request: request)
    }
    
    func likePost(postId: Int) -> PreparedOperation<Empty> {
        
        let request = Request(
            url: RestURL.MyPosts.likePost(postId),
            method: .post,
            withAuthorization: true)
        
        return prepare(request: request)
    }
    
    func dislikePost(postId: Int) -> PreparedOperation<Empty> {
        
        let request = Request(
            url: RestURL.MyPosts.dislikePost(postId),
            method: .delete,
            withAuthorization: true)
        
        return prepare(request: request)
    }
    
    func getLocalPosts(postTypes: [TypeOfPost],
                       search: String = "",
                       withinMyInterests: Bool = false,
                       onlyBusinessPosts: Bool = false,
                       page: Int) -> PreparedOperation<[PostModel]> {
        
        let query: [String: Any] = [
            "types": postTypes,
            "search": search,
            "withinMyInterests": withinMyInterests ? 1 : 0,
            "onlyBusinessPosts": onlyBusinessPosts ? 1 : 0,
            "page": page,
            "expand": postExpand]
        
        let request = Request(
            url: RestURL.MyPosts.localPosts,
            method: .get,
            query: query,
            withAuthorization: true)
        
        return prepare(request: request)
    }

    func getGlobalPosts(postTypes: [TypeOfPost],
                       search: String = "",
                       hashtags: [Int] = [],
                       page: Int) -> PreparedOperation<[PostModel]> {

        let query: [String: Any] = [
            "types": postTypes,
            "search": search,
            "hashtagIds": hashtags,
            "page": page,
            "expand": postExpand]

        let request = Request(
            url: RestURL.MyPosts.globalPosts,
            method: .get,
            query: query,
            withAuthorization: true)

        return prepare(request: request)
    }
    
    func followPost(postId: Int) -> PreparedOperation<Empty> {
        
        let request = Request(
            url: RestURL.MyPosts.followPost(postId),
            method: .post,
            withAuthorization: true)
        
        return prepare(request: request)
    }
    
    func unfollowPost(postId: Int) -> PreparedOperation<Empty> {
        
        let request = Request(
            url: RestURL.MyPosts.unfollowPost(postId),
            method: .delete,
            withAuthorization: true)
        
        return prepare(request: request)
    }
    
    func addImageToAlbum(postType: TypeOfPost,
                         imageData: UploadImageData) -> PreparedOperation<ImageUploadResponseModel> {
        let request = Request(
            url: RestURL.MyPosts.createPost(type: postType),
            method: .post,
            withAuthorization: true,
            body: imageData.crop,
            media: ["file": .jpg(imageData.image, nil)])
        
        return prepare(request: request)
    }

    func postsByHashtag(_ hashtag: String, page: Int) -> PreparedOperation<[PostModel]> {
        let query: [String: Any] = [
            "hashtag": hashtag,
            "page": page,
            "expand": postExpand]

        let request = Request(
            url: RestURL.MyPosts.globalPosts,
            method: .get,
            query: query,
            withAuthorization: true)

        return prepare(request: request)
    }

    func viewMedia(mediaId: Int) -> PreparedOperation<Empty> {
        let request = Request(
            url: RestURL.MyPosts.mediaView(mediaId: mediaId),
            method: .post,
            withAuthorization: true)
        return prepare(request: request)
    }
}
