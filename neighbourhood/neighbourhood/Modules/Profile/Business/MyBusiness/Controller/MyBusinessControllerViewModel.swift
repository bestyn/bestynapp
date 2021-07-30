//
//  MyBusinessControllerViewModel.swift
//  neighbourhood
//
//  Created by Administrator on 23.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import UIKit
import GBKSoftRestManager

class MyBusinessControllerViewModel {
    // MARK: Internal properties
    @ObservableState var loadingState: ProfileLoadingState = .didNotStart
    var albumImages: [ImageModel] {
        return mediaPosts.compactMap { ImageModel(post: $0) }
    }
    var currentProfile: BusinessProfile?
    
    // MARK: Private properties
    private lazy var authorizationManager: RestAuthorizationManager = RestService.shared.createOperationsManager(from: self, type: RestAuthorizationManager.self)
    private lazy var profileManager: RestProfileManager = RestService.shared.createOperationsManager(from: self, type: RestProfileManager.self)
    private lazy var businessProfileManager: RestBusinessProfileManager = RestService.shared.createOperationsManager(from: self, type: RestBusinessProfileManager.self)
    private lazy var postsManager: RestMyPostsManager = {
        let manager = RestService.shared.createOperationsManager(from: self, type: RestMyPostsManager.self)
        manager.assignErrorHandler { [weak self] (error) in
            self?.loadingState = .loadFailed(error)
        }
        return manager
    }()

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(profileChanged), name: .profileDidChanged, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private(set) var mediaPosts: [PostModel] = []
    private var albumCurrentPage = 0
    private var albumLastPage = 0
    
    // MARK: - Internal API
    func bindLoadingState(handler: @escaping ((ProfileLoadingState) -> ())) {
        $loadingState.bind(l: handler)
    }
    
    func uploadImage(_ image: UIImage, crop: CGRect) {
        let data = UploadImageData(image: image, crop: .init(cgRect: crop))
        loadingState = .inProgress
        addToAlbum(image: data)
    }
    
    func remove(_ image: ImageModel) {
        removeFromAlbum(with: image.id)
    }

    func loadMore() {
        loadMoreAlbumImages()
    }

    func refresh() {
        albumLastPage = 0
        albumCurrentPage = 1
        loadMoreAlbumImages(clear: true)
    }
}

extension MyBusinessControllerViewModel {

    @objc private func profileChanged() {
        guard let currentProfile = ArchiveService.shared.currentProfile,
              self.currentProfile?.id != currentProfile.id else {
            return
        }
        self.currentProfile = ArchiveService.shared.userModel?.businessProfiles?.first(where: {$0.id == currentProfile.id})
        loadingState = .inProgress
        loadingState = .profileLoaded
        mediaPosts = mediaPosts.map({ (post) -> PostModel in
            var post = post
            var profile = post.profile
            profile?.avatar = currentProfile.avatar
            post.profile = profile
            return post
        })
    }
}

// MARK: - REST requests
extension MyBusinessControllerViewModel {
    func fetchUserProfile() {
        profileManager.getUser()
            .onComplete { [weak self] (response) in
                guard let self = self else {
                    return
                }
                if let user = response.result {
                    ArchiveService.shared.userModel = user
                    guard let profile = user.businessProfiles?.first(where: {$0.id == ArchiveService.shared.currentProfile?.id}) else {
                        ArchiveService.shared.currentProfile = user.profile.selectorProfile
                        return
                    }
                    self.currentProfile = profile
                    ArchiveService.shared.currentProfile = profile.selectorProfile
                    self.loadingState = .profileLoaded
                }
            }.onError { (error) in
                self.loadingState = .loadFailed(error)
            }.run()
    }
    
    func addToAlbum(image: UploadImageData) {
        guard ValidationManager().checkInternetConnection() else {
            Toast.show(message: R.string.localizable.internetConnectionError())
            return
        }
        loadingState = .inProgress
        postsManager.addImageToAlbum(postType: .media, imageData: image)
            .onComplete { [weak self] (uploadResult) in
                guard let self = self else {
                    return
                }
                self.getNewMediaPost(by: uploadResult.result?.id)
                self.loadingState = .loadFinished
            }
            .onError { [weak self] error in
                self?.loadingState = .imageUploadFailed(error)
            }
            .run()
    }
    
    func removeFromAlbum(with id: Int) {
        loadingState = .inProgress
        postsManager.deletePost(postId: id)
            .onComplete { [weak self] (result) in
                guard let self = self else {
                    return
                }
                self.mediaPosts = self.mediaPosts.filter { $0.id != id }
                self.loadingState = .albumLoaded
                Toast.show(message: R.string.localizable.removedImage())
            }
            .onError { [weak self] error in
                self?.loadingState = .loadFailed(error)
            }
            .run()
    }
    
    func loadMoreAlbumImages(clear: Bool = false) {
        if albumLastPage > 0, albumCurrentPage > albumLastPage {
            return
        }
        loadingState = .inProgress
        postsManager.getMyPost(types: [.media], page: albumCurrentPage)
            .onComplete { [weak self] (result) in
                guard let self = self else {
                    return
                }
                if let posts = result.result {
                    if clear {
                        self.mediaPosts = posts
                    } else {
                        let newImages = result.result?.filter { (post) in
                            !self.mediaPosts.contains(where: {$0.id == post.id })
                        } ?? []
                        self.mediaPosts.append(contentsOf: newImages)
                    }
                }
                if let pagination = result.pagination {
                    self.albumCurrentPage = pagination.currentPage + 1
                    self.albumLastPage = pagination.pageCount
                }
                self.loadingState = .albumLoaded
            }
            .onError { [weak self] error in
                self?.loadingState = .loadFailed(error)
            }
            .run()
    }
    
    func getNewMediaPost(by postId: Int?) {
        guard let postId = postId else {
            return
        }
        loadingState = .inProgress
        postsManager.getPost(postId: postId)
            .onComplete { [weak self] (result) in
                if let post = result.result {
                    self?.mediaPosts.insert(post, at: 0)
                    self?.loadingState = .imageUploadCompleted(ImageModel(post: post))
                }
            } .onError { (error) in
                self.loadingState = .imageUploadFailed(error)
            } .run()
    }
    
    func signOut() {
        guard ValidationManager().checkInternetConnection() else {
            Toast.show(message: R.string.localizable.internetConnectionError())
            return
        }
        
        authorizationManager.signOut().onError { (error) in
            self.loadingState = .loadFailed(error)
        }
        .onComplete { (_) in
            RootRouter.shared.exitApp()
        } .run()
    }
}
