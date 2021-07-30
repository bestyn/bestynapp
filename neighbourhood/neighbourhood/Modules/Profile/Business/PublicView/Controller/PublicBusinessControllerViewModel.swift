//
//  PublicBusinessControllerViewModel.swift
//  neighbourhood
//
//  Created by Administrator on 23.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import GBKSoftRestManager

class PublicBusinessControllerViewModel {
    @Observable private(set) var currentProfile: BusinessProfile?
    @Observable private(set) var mediaPosts: [PostModel] = []
    @Observable private(set) var error: Error?
    @Observable private(set) var isProfileLoading: Bool = true
    @Observable private(set) var isAlbumLoading: Bool = false

    var businessId: Int?

    // MARK: Private properties
    private lazy var businessProfileManager: RestBusinessProfileManager = RestService.shared.createOperationsManager(from: self)
    private lazy var profileManager: RestProfileManager = RestService.shared.createOperationsManager(from: self)
    private lazy var followManager: RestProfileFollowManager = RestService.shared.createOperationsManager(from: self)

    private var albumCurrentPage = 0
    private var albumTotalImages = 0
    
}

//MARK: Rest methods
extension PublicBusinessControllerViewModel {
    func fetchProfile() {
        guard ValidationManager().checkInternetConnection() else {
            Toast.show(message: R.string.localizable.internetConnectionError())
            return
        }
        
        guard let id = businessId else { return }
        businessProfileManager.getBusinessProfiles(profileId: id)
            .onStateChanged({ [weak self] (state) in
                self?.isProfileLoading = state == .started
            })
            .onComplete { [weak self] (result) in
                self?.currentProfile = result.result
            } .onError { [weak self] (error) in
                self?.error = error
            } .run()
    }
    
    func loadAlbum() {
        guard let profileId = businessId,
              mediaPosts.isEmpty || mediaPosts.count < albumTotalImages else {
            return
        }
        profileManager.getMediaPosts(by: profileId, page: albumCurrentPage)
            .onStateChanged({ [weak self] (state) in
                self?.isAlbumLoading = state == .started
            })
            .onComplete { [weak self] (result) in
                guard let self = self else {
                    return
                }
                let newImages = result.result?.filter { (post) in
                    !self.mediaPosts.contains(where: {$0.id == post.id })
                } ?? []
                self.mediaPosts += newImages
                if let pagination = result.pagination {
                    self.albumCurrentPage = pagination.currentPage + 1
                    self.albumTotalImages = pagination.totalCount
                }
            }
            .onError { [weak self] error in
                self?.error = error
            }
            .run()
    }

    func toggleFollow() {
        guard let profile = currentProfile else {
            return
        }
        let operation = (profile.isFollowed ?? false) ? followManager.unfollow(profile: profile.postProfile) : followManager.follow(profile: profile.postProfile)
        operation.onComplete { [weak self] (_) in
            self?.currentProfile?.isFollowed.toggle()
        }
        .onError({ [weak self] (error) in
            self?.error = error
        })
        .run()
    }

    func removeFollower() {
        guard let profile = currentProfile else {
            return
        }
        followManager.removeFollower(profile: profile.postProfile)
            .onComplete { [weak self] (_) in
                self?.currentProfile?.isFollower = false
            }.run()
    }
}
