//
//  StoriesListViewModel.swift
//  neighbourhood
//
//  Created by Artem Korzh on 16.02.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import Foundation
import GBKSoftRestManager
import GSPlayer

class StoriesListViewModel {

    enum Mode {
        case all
        case my
        case followed
        case audio(AudioTrackModel)
    }

    enum PagingMode {
        case normal
        case bothDirections
    }

    @Observable private(set) var stories: [StoryListModel] = []
    @Observable private(set) var isFetchingNext: Bool = false
    @SingleEventObservable private(set) var lastError: Error?

    let mode: Mode
    private let pagingMode: PagingMode

    private lazy var storiesManager: RestStoriesManager = createManager(of: RestStoriesManager.self)
    private lazy var postsManager: RestMyPostsManager = createManager(of: RestMyPostsManager.self)
    private lazy var reactionsManager: RestReactionsManager = createManager(of: RestReactionsManager.self)
    private var isFetchingPrevious = false
    private var nextPage = 1
    private var lastPage = 0
    private var firstStoryID: Int?
    private var lastStoryID: Int?
    private var canLoadPreviousStories: Bool = true
    private var canLoadNextStories: Bool = true

    init(mode: Mode, anchorStory: PostModel?) {
        self.mode = mode
        if let anchorStory = anchorStory {
            self.pagingMode = .bothDirections
            self.stories = [StoryListModel(story: anchorStory)]
            self.firstStoryID = anchorStory.id
            self.lastStoryID = anchorStory.id
        } else {
            self.pagingMode = .normal
            loadNextStories()
        }
        setupObservers()
    }
}

// MARK: - Configuration

extension StoriesListViewModel {
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(onProfileChanged), name: .profileDidChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onPostCreated(notification:)), name: .postCreated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onPostUpdated(notification:)), name: .postUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onPostRemoved(notification:)), name: .postRemoved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(internetStatusChanged(notification:)), name: ReachabilityService.shared.reachabilityStatusChanged, object: nil)
    }
}

// MARK: - Public methods

extension StoriesListViewModel {
    public func loadNextStories() {
        if isFetchingNext {
            return
        }
        switch pagingMode {
        case .normal:
            if lastPage > 0, nextPage > lastPage {
                return
            }
            restLoadStories(paging: .init(page: nextPage))
        case .bothDirections:
            guard canLoadNextStories,
                  let lastStoryID = lastStoryID else {
                return
            }
            restLoadStories(paging: .init(idAfter: lastStoryID))
        }
    }

    public func loadPreviousStories() {
        guard pagingMode == .bothDirections,
              canLoadPreviousStories,
              let firstStoryID = firstStoryID else {
            return
        }
        if isFetchingPrevious {
            return
        }
        restLoadStories(paging: .init(idBefore: firstStoryID))
    }

    public func refreshList(force: Bool = false) {
        if case .all = mode, !force {
            return
        }
        nextPage = 1
        lastPage = 0
        canLoadNextStories = true
        canLoadPreviousStories = true
        restLoadStories(paging: .init(page: nextPage), clear: true)
    }

    public func removeReaction(story: PostModel) {
        restRemoveReaction(story: story)
    }

    public func addReaction(story: PostModel, reaction: Reaction) {
        restAddReaction(story: story, reaction: reaction)
    }

    public func unfollow(story: PostModel) {
        guard story.iFollow else {
            return
        }
        restToggleFollow(false, story: story)
    }

    public func follow(story: PostModel) {
        guard !story.iFollow else {
            return
        }
        restToggleFollow(true, story: story)
    }

    public func remove(story: PostModel) {
        restRemovePost(story: story)
    }
}

// MARK: - Private methods

extension StoriesListViewModel {

    private func createManager<T: RestOperationsManager>(of type: T.Type) -> T {
        let manager = RestService.shared.createOperationsManager(from: self, type: type)
        manager.assignErrorHandler { [weak self] (error) in
            self?.lastError = error
        }
        return manager
    }

    @objc private func onProfileChanged() {
        ArchiveService.shared.lastVisitedStory = nil
        refreshList(force: true)
    }

    @objc private func onPostCreated(notification: Notification) {
        guard let type = notification.object as? TypeOfPost,
              type == .story else {
            return
        }
        refreshList(force: true)
    }

    @objc private func onPostUpdated(notification: Notification) {
        guard let post = notification.object as? PostModel,
              post.type == .story else {
            return
        }
        stories = stories.map({ $0.story.id == post.id ? StoryListModel(story: post) : $0 })
    }

    @objc private func onPostRemoved(notification: Notification) {
        guard let post = notification.object as? PostModel,
              post.type == .story else {
            return
        }
        stories = stories.filter({ $0.story.id != post.id })
    }

    @objc private func internetStatusChanged(notification: Notification) {
        guard let status = notification.userInfo?["status"] as? ReachabilityStatus,
           status == .reachable else {
            return
        }
        if stories.count == 0 {
            refreshList(force: true)
        }
    }
}

// MARK: - REST requests

extension StoriesListViewModel {
    private func restLoadStories(paging: RestStoriesManager.PagingData, clear: Bool = false) {
        let interests = (ArchiveService.shared.currentProfile?.hashtags ?? []).map({$0.id})
        if case .followed = mode, interests.count == 0 {
            self.stories = []
            return
        }
        let operation: PreparedOperation<[StoryListModel]> = {
            switch mode {
            case .all:
                return storiesManager.getAllStories(paging: paging)
            case .my:
                return storiesManager.getMyStories(paging: paging)
            case .followed:
                return storiesManager.getAllStories(hashtags: interests, paging: paging)
            case .audio(let audioTrack):
                return storiesManager.getStoriesByAudio(audioTrackID: audioTrack.id, paging: paging)
            }
        }()

        operation
            .onStateChanged({ [weak self] (state) in
                if paging.idBefore != nil {
                    self?.isFetchingPrevious = state == .started
                } else {
                    self?.isFetchingNext = state == .started
                }
            })
            .onComplete { [weak self] (response) in
                guard let self = self else {
                    return
                }
                if let pagination = response.pagination {
                    self.nextPage = pagination.currentPage + 1
                    self.lastPage = pagination.pageCount
                }
                if let stories = response.result {
                    var updatedStories: [StoryListModel] = self.stories
                    if clear {
                        updatedStories = stories
                    } else if paging.idBefore != nil {
                        updatedStories.insert(contentsOf: stories.reversed(), at: 0)
                    } else {
                        updatedStories.append(contentsOf: stories)
                    }
                    self.stories = updatedStories

                    VideoPreloadManager.shared.set(waiting: stories.compactMap({$0.story.media?.first?.origin}))
//                    stories.forEach { (story) in
//                        if let url = story.story.media?.first?.origin {
////                            CacheManager.of(type: .file).insert(url: url, completion: nil)
//                        }
//                    }
                    self.canLoadNextStories = stories.count > 0 && paging.idAfter != nil
                    self.canLoadPreviousStories = stories.count > 0 && paging.idBefore != nil
                    self.lastStoryID = stories.last?.story.id
                    self.firstStoryID = stories.first?.story.id
                }
            }.run()
    }

    private func restToggleFollow(_ follow: Bool, story: PostModel) {
        let operation = follow
            ? postsManager.followPost(postId: story.id)
            : postsManager.unfollowPost(postId: story.id)

        operation
            .onComplete { [weak self] (response) in
                self?.restRefreshStory(story: story)
        }.run()
    }

    private func restAddReaction(story: PostModel, reaction: Reaction) {
        reactionsManager.addReaction(postID: story.id, reaction: reaction)
            .onComplete { [weak self] (_) in
                self?.restRefreshStory(story: story)
        }.run()
    }

    private func restRemoveReaction(story: PostModel) {
        reactionsManager.removeReaction(postID: story.id)
            .onComplete { [weak self] (_) in
                self?.restRefreshStory(story: story)
            }.run()
    }

    private func restRefreshStory(story: PostModel) {
        postsManager.getPost(postId: story.id)
            .onComplete {(response) in
                if let updatedPost = response.result {
                    NotificationCenter.default.post(name: .postUpdated, object: updatedPost)
                }
        }.run()
    }

    private func restRemovePost(story: PostModel) {
        postsManager.deletePost(postId: story.id)
            .onError {(error) in
                print(error)
            }
            .onComplete { (_) in
                NotificationCenter.default.post(name: .postRemoved, object: story)
                Toast.show(message: Alert.Message.storyDeleted)
            }.run()
    }
}
