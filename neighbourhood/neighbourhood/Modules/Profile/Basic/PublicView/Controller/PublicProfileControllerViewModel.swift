//
//  PublicProfileControllerViewModel.swift
//  neighbourhood
//
//  Created by Administrator on 21.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import GBKSoftRestManager

enum PublicProfileLoadingState {
    case didNotStart
    case inProgress
    case albumLoaded
    case profileLoaded
    case loadFinished
    case loadFailed(APIError)
}

extension PublicProfileLoadingState: Equatable {
    static func ==(lhs: PublicProfileLoadingState, rhs: PublicProfileLoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.didNotStart, .didNotStart):
            return true
        case (.inProgress, .inProgress):
            return true
        case (.albumLoaded, .albumLoaded):
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

final class PublicProfileControllerViewModel {
    
    // MARK: Internal properties

    
    var profileId: Int = 0
    var albumImages: [ImageModel] {
        return mediaPosts.compactMap { ImageModel(post: $0) }
    }
    
    // MARK: Private properties
    private lazy var profileManager: RestProfileManager = RestService.shared.createOperationsManager(from: self, type: RestProfileManager.self)
    private lazy var followManager: RestProfileFollowManager = RestService.shared.createOperationsManager(from: self, type: RestProfileFollowManager.self)
    
    @Observable private(set) var profile: PublicProfileModel?
    @Observable private(set) var mediaPosts: [PostModel] = []
    @Observable private(set) var isLoadingProfile: Bool = true
    @Observable private(set) var isLoadingMedia: Bool = true
    @Observable private(set) var error: Error?
    private var pages: [ProfileDetailsSection] = [.publicInterests]
    private var albumCurrentPage = 0
    private var albumTotalImages = 0
    
    // MARK: - Internal API
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
    
    func configureImagesView(in pagingView: PagingView, delegatedBy delegate: UIViewController?) -> UIView {
        let page = ProfileDetailsSection.images
        pages.append(page)
        let view = ProfileDetailsSection.images.view(delegatedBy: delegate)
        pagingView.views.append(PagingView.PagingChildView(buttonTitle: page.title, view: view))
        return view
    }

    func chatProfile() -> ChatProfile? {
        return profile?.chatProfile
    }
}

// MARK: - REST requests
extension PublicProfileControllerViewModel {
    func fetchProfileData() {
        guard ValidationManager().checkInternetConnection() else {
            Toast.show(message: R.string.localizable.internetConnectionError())
            return
        }
        
        profileManager.getPublicProfile(profileId: profileId)
            .onStateChanged({ [weak self] (state) in
                self?.isLoadingProfile = state == .started
            })
            .onComplete { [weak self] (result) in
                guard let self = self else { return }
                
                if let profile = result.result {
                    self.profile = profile
                }
        } .onError { [weak self] (error) in
            self?.error = error
        } .run()
    }
    
    func loadAlbum() {
        guard mediaPosts.isEmpty || mediaPosts.count < albumTotalImages else {
            return
        }
        profileManager.getMediaPosts(by: profileId, page: albumCurrentPage)
            .onStateChanged({ [weak self] (state) in
                self?.isLoadingMedia = state == .started
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
        guard let profile = profile else {
            return
        }
        let operation = profile.isFollowed ? followManager.unfollow(profile: profile.postProfile) : followManager.follow(profile: profile.postProfile)
        operation.onComplete { [weak self] (_) in
            self?.profile?.isFollowed.toggle()
        }.run()
    }

    func removeFollower() {
        guard let profile = profile else {
            return
        }
        followManager.removeFollower(profile: profile.postProfile)
            .onComplete { [weak self] (_) in
                self?.profile?.isFollower = false
            }.run()
    }

}
