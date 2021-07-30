//
//  AlbumViewModel.swift
//  neighbourhood
//
//  Created by Artem Korzh on 26.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import UIKit

class AlbumViewModel {

    private lazy var postsManager: RestMyPostsManager = RestService.shared.createOperationsManager(from: self)
    private lazy var profileManager: RestProfileManager = RestService.shared.createOperationsManager(from: self)
    private lazy var businessProfileManager: RestBusinessProfileManager = RestService.shared.createOperationsManager(from: self)
    private lazy var reactionsManager: RestReactionsManager = RestService.shared.createOperationsManager(from: self)

    @Observable private(set) var profile: SelectorProfileModel
    @Observable private(set) var mediaPosts: [PostModel] = []
    private var currentPage: Int
    private var lastPage: Int = 0

    init(profile: SelectorProfileModel, loadedPosts: [PostModel]) {
        self.profile = profile
        self.mediaPosts = loadedPosts
        self.currentPage = (loadedPosts.count / 20)  + (loadedPosts.count % 20 > 0 ? 1 : 0)
        NotificationCenter.default.addObserver(self, selector: #selector(profileChanged), name: .profileDidChanged, object: nil)
    }

    @objc private func profileChanged() {
        guard let newProfile = ArchiveService.shared.currentProfile,
              profile.id == newProfile.id else {
            return
        }
        profile = newProfile
        self.mediaPosts = mediaPosts.map({ (post) -> PostModel in
            var post = post
            var profile = post.profile
            profile?.avatar = newProfile.avatar
            post.profile = profile
            return post
        })
    }
}

// MARK: - Public methods

extension AlbumViewModel {

    func loadMore() {
        if lastPage > 0, currentPage > lastPage {
            return
        }
        restLoadMore()
    }

    public func addReaction(post: PostModel, reaction: Reaction) {
        restAddReaction(post: post, reaction: reaction)
    }

    public func removeReaction(post: PostModel) {
        restRemoveReaction(post: post)
    }

    public func toggleFollow(post: PostModel) {
        restToggleFollow(post: post)
    }

    public func deletePost(post: PostModel) {
        restRemovePost(post)
    }

    public func setAsAvatar(_ post: PostModel) {
        guard post.type == .media,
              let imageURL = post.media?.first?.formatted?.medium else {
            return
        }
        UIImage.load(from: imageURL) { [weak self] (image) in
            if let image = image {
                self?.restSaveAsAvatar(image: image)
            }
        }
    }
    
    public func updatePost(post: PostModel) {
        restRefreshPost(post: post)
    }

    public func removePost(post: PostModel) {
        mediaPosts.removeAll(where: {$0.id == post.id})
    }
}

// MARK: - REST requests

extension AlbumViewModel {

    private func restLoadMore() {
        profileManager.getMediaPosts(by: profile.id, page: currentPage)
            .onComplete { [weak self] (response) in
                guard let self = self else { return }
                if let pagination = response.pagination {
                    self.lastPage = pagination.pageCount
                    self.currentPage = pagination.currentPage + 1
                }
                if let posts = response.result {
                    let newPosts = posts.filter { (post) in
                        !self.mediaPosts.contains(where: {$0.id == post.id })
                    }
                    self.mediaPosts.append(contentsOf: newPosts)
                }
            }.run()
    }

    private func restRefreshPost(post: PostModel) {
        postsManager.getPost(postId: post.id)
            .onComplete { [weak self] (response) in
                guard let self = self,
                    let updatedPost = response.result,
                    let postIndex = self.mediaPosts.firstIndex(where: {$0.id == post.id}) else {
                        return
                }
                self.mediaPosts[postIndex] = updatedPost
        }.run()
    }

    private func restAddReaction(post: PostModel, reaction: Reaction) {
        reactionsManager.addReaction(postID: post.id, reaction: reaction)
            .onComplete { [weak self] (_) in
                self?.restRefreshPost(post: post)
            }.run()
    }

    private func restRemoveReaction(post: PostModel) {
        reactionsManager.removeReaction(postID: post.id)
            .onComplete { [weak self] (_) in
                self?.restRefreshPost(post: post)
            }.run()
    }

    private func restToggleFollow(post: PostModel) {
        let operation = post.iFollow
            ? postsManager.unfollowPost(postId: post.id)
            : postsManager.followPost(postId: post.id)

        operation
            .onComplete { [weak self] (response) in
                self?.restRefreshPost(post: post)
        }.run()
    }

    private func restRemovePost(_ post: PostModel) {
        postsManager.deletePost(postId: post.id)
            .onComplete { [weak self] (response) in
                guard let self = self,
                      let postIndex = self.mediaPosts.firstIndex(where: { $0.id == post.id }) else {
                        return
                }
                self.mediaPosts.remove(at: postIndex)
                let message = post.type.deleteSuccessMessage
                Toast.show(message: message)
        }.run()
    }

    private func restSaveAsAvatar(image: UIImage) {
        guard let currentProfile = ArchiveService.shared.currentProfile else {
            return
        }
        if currentProfile.type == .business {
            businessProfileManager.updateProfile(id: currentProfile.id, data: nil, image: image)
                .onComplete { (result) in
                    if let profile = result.result {
                        var user = ArchiveService.shared.userModel
                        let businessProfiles = user?.businessProfiles?.map({ (businesProfile) -> BusinessProfile in
                            if businesProfile.id == profile.id {
                                return profile
                            }
                            return businesProfile
                        })
                        user?.businessProfiles = businessProfiles
                        ArchiveService.shared.userModel = user
                        ArchiveService.shared.currentProfile = profile.selectorProfile
                        Toast.show(message: R.string.localizable.avatarChanged())
                    }
                }.run()
        } else {
            profileManager.changeUserProfile(data: nil, image: image)
                .onComplete { (result) in
                    if let profile = result.result {
                        var user = ArchiveService.shared.userModel
                        user?.profile = profile
                        ArchiveService.shared.userModel = user
                        ArchiveService.shared.currentProfile = profile.selectorProfile
                        Toast.show(message: R.string.localizable.avatarChanged())
                    }
                }.run()
        }
    }
}
