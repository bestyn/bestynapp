//
//  ProfileControllerViewModel.swift
//  neighbourhood
//
//  Created by Administrator on 15.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import GBKSoftRestManager

enum ProfileLoadingState {
    case didNotStart
    case inProgress
    case albumLoaded
    case imageUploadCompleted(ImageModel?)
    case imageUploadFailed(APIError)
    case profileLoaded
    case loadFinished
    case loadFailed(APIError)
}

extension ProfileLoadingState: Equatable {
    static func ==(lhs: ProfileLoadingState, rhs: ProfileLoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.didNotStart, .didNotStart):
            return true
        case (.inProgress, .inProgress):
            return true
        case (.albumLoaded, .albumLoaded):
            return true
        case (.imageUploadCompleted, .imageUploadCompleted):
            return true
        case (.profileLoaded, .profileLoaded):
            return true
        case (.loadFinished, .loadFinished):
            return true
        case (.loadFailed, .loadFailed):
            return true
        default:
            return false
        }
    }
}

final class ProfileControllerViewModel {
    
    // MARK: Internal properties
    @Observable private(set) var profile: UserProfileModel?
    @Observable private(set) var error: Error?
    @Observable private(set) var isLoading = false
    @Observable private(set) var mediaPosts: [PostModel] = []

    var albumImages: [ImageModel] {
        return mediaPosts.compactMap { ImageModel(post: $0) }
    }
    
    // MARK: Private properties
    private lazy var profileManager: RestProfileManager = RestService.shared.createOperationsManager(from: self, type: RestProfileManager.self)
    private lazy var authorizationManager: RestAuthorizationManager = RestService.shared.createOperationsManager(from: self, type: RestAuthorizationManager.self)
    private lazy var postsManager: RestMyPostsManager = {
        let manager = RestService.shared.createOperationsManager(from: self, type: RestMyPostsManager.self)
        manager.assignErrorHandler { [weak self] (error) in
            self?.error = error
        }
        return manager
    }()
    
    private let pages: [ProfileDetailsSection] = [.interests, .images]
    private var albumCurrentPage = 1
    private var albumLastPage = 0

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(currentProfileChanged), name: .profileDidChanged, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Internal API
//    func pageViews(delegatedBy delegate: UIViewController?) -> [PagingView.PagingChildView] {
//        return pages.map { PagingView.PagingChildView(buttonTitle: $0.title, view: $0.view(delegatedBy: delegate)) }
//    }
    
    func configurePagingView(_ pagingView: PagingView,
                             delegatedBy delegate: UIViewController?) -> [ProfileDetailsSection: UIView] {
        var pageViews: [PagingView.PagingChildView] = []
        var viewsByPage: [ProfileDetailsSection: UIView] = [:]
        for page in pages {
            let pageItemView = page.view(delegatedBy: delegate)
            viewsByPage[page] = pageItemView
            pageViews.append(PagingView.PagingChildView(buttonTitle: page.title, view: pageItemView))
        }
        pagingView.views = pageViews
        return viewsByPage
    }
        
    func uploadImage(_ image: UIImage, crop: CGRect) {
        let data = UploadImageData(image: image, crop: .init(cgRect: crop))
        isLoading = true
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

// MARK: - REST requests
extension ProfileControllerViewModel {
    func fetchUserProfile() {
        profileManager.getUser()
            .onStateChanged { [weak self] (state) in
                self?.isLoading = state == .started
        }
        .onComplete { [weak self] (result) in
            if let profile = result.result?.profile {
                self?.updateStoredUser(with: profile)
                self?.profile = profile
            }
        } .onError { [weak self] (error) in
            self?.error = error
        } .run()
    }
    
    func addToAlbum(image: UploadImageData) {
        postsManager.addImageToAlbum(postType: .media, imageData: image)
            .onStateChanged({ [weak self] (state) in
                self?.isLoading = state == .started
            })
            .onComplete { [weak self] (uploadResult) in
                guard let self = self else {
                    return
                }
                self.getNewMediaPost(by: uploadResult.result?.id)
            }
            .onError { [weak self] error in
                self?.error = error
            }
            .run()
    }
    
    func removeFromAlbum(with id: Int) {
        postsManager.deletePost(postId: id)
            .onStateChanged({ [weak self] (state) in
                self?.isLoading = state == .started
            })
            .onComplete { [weak self] (result) in
                guard let self = self else {
                    return
                }
                self.mediaPosts = self.mediaPosts.filter { $0.id != id }
                Toast.show(message: R.string.localizable.removedImage())
            }
            .onError { [weak self] error in
                self?.error = error
            }
            .run()
    }
    
    func loadMoreAlbumImages(clear: Bool = false) {
        if albumLastPage > 0, albumCurrentPage > albumLastPage {
            return
        }
        postsManager.getMyPost(types: [.media], page: albumCurrentPage)
            .onStateChanged({ [weak self] (state) in
                self?.isLoading = state == .started
            })
            .onComplete { [weak self] (result) in
                guard let self = self else {
                    return
                }
                if let pagination = result.pagination {
                    self.albumCurrentPage = pagination.currentPage + 1
                    self.albumLastPage = pagination.pageCount
                }
                if let posts = result.result {
                    if clear {
                        self.mediaPosts = posts
                    } else {
                        let newImages = posts.filter { (post) in
                            !self.mediaPosts.contains(where: {$0.id == post.id })
                        }
                        self.mediaPosts.append(contentsOf: newImages)
                    }
                }

            }
            .onError { [weak self] error in
                self?.error = error
            }
            .run()
    }
    
    func getNewMediaPost(by postId: Int?) {
        guard let postId = postId else {
            return
        }
        postsManager.getPost(postId: postId)
            .onStateChanged({ [weak self] (state) in
                self?.isLoading = state == .started
            })
            .onComplete { [weak self] (result) in
                if let post = result.result {
                    self?.mediaPosts.insert(post, at: 0)
                }
            } .onError { (error) in
                self.error = error
            } .run()
    }
    
    func restSignOut() {
        guard ValidationManager().checkInternetConnection() else {
            Toast.show(message: R.string.localizable.internetConnectionError())
            return
        }
        authorizationManager.signOut()
            .onError { (error) in
                self.error = error
        }
            .onComplete { _ in
                ArchiveService.shared.currentProfile = nil
                RootRouter.shared.exitApp()
        } .run()
    }
}

// MARK: - Supporting methods
private extension ProfileControllerViewModel {
    func updateStoredUser(with profile: UserProfileModel) {
        var user = ArchiveService.shared.userModel
        user?.profile = profile
        ArchiveService.shared.userModel = user
        ArchiveService.shared.seeBusinessContent = profile.seeBusinessPosts
        ArchiveService.shared.currentProfile = profile.selectorProfile
    }

    @objc private func currentProfileChanged() {
        guard let currentProfile = ArchiveService.shared.currentProfile,
              currentProfile.id == mediaPosts.first?.profile?.id else {
            return
        }
        mediaPosts = mediaPosts.map({ (post) -> PostModel in
            var post = post
            var profile = post.profile
            profile?.avatar = currentProfile.avatar
            post.profile = profile
            return post
        })
    }
}
