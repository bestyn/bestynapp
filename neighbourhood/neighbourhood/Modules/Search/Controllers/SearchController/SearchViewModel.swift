//
//  SearchViewModel.swift
//  neighbourhood
//
//  Created by Artem Korzh on 23.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

class SearchViewModel {

    enum SearchMode: String, CaseIterable {
        case posts
        case people
        case audio

        var title: String {
            switch self {
            case .audio:
                return "Audio Track"
            default:
                return rawValue.capitalized
            }
        }
    }

    struct State {
        var searching: Bool = false
        var foundPosts: [PostModel] = []
        var foundPeople: [PostProfileModel] = []
        var foundAudios: [AudioTrackModel] = []
        var recentSearches: [String] = []
        var currentQuery: String = ""
        var currentMode: SearchMode = .posts
        var lastError: Error?
    }

    private lazy var profilesManager: RestProfileManager = {
        let manager: RestProfileManager = RestService.shared.createOperationsManager(from: self)
        manager.assignErrorHandler { [weak self] (error) in
            self?.state.lastError = error
            self?.state.lastError = nil
        }
        return manager
    }()
    private lazy var postsManager: RestMyPostsManager = {
        let manager: RestMyPostsManager = RestService.shared.createOperationsManager(from: self)
        manager.assignErrorHandler { [weak self] (error) in
            self?.state.lastError = error
            self?.state.lastError = nil
        }
        return manager
    }()
    private lazy var reactionsManager: RestReactionsManager = {
        let manager: RestReactionsManager = RestService.shared.createOperationsManager(from: self)
        manager.assignErrorHandler { [weak self] (error) in
            self?.state.lastError = error
            self?.state.lastError = nil
        }
        return manager
    }()
    private lazy var audioManager: RestAudioTracksManager = {
        let manager: RestAudioTracksManager = RestService.shared.createOperationsManager(from: self)
        manager.assignErrorHandler { [weak self] (error) in
            self?.state.lastError = error
            self?.state.lastError = nil
        }
        return manager
    }()

    private var pages: [SearchMode: (page: Int, maxPage: Int)] = [:]

    @Observable var state: State = State.init(recentSearches: ArchiveService.shared.recentSearches)

    func changeMode(_ mode: SearchMode) {
        state.currentMode = mode
        search()
    }

    func changeQuery(query: String) {
        var newState = state
        newState.currentQuery = query
        newState.foundPeople = []
        newState.foundPosts = []
        newState.foundAudios = []
        self.pages = [:]
        state = newState
        updateRecentSearches(with: query)
        search()
    }

    func removeRecentQuery(query: String) {
        var searches = ArchiveService.shared.recentSearches
        guard searches.contains(query) else {
            return
        }
        searches.removeAll(where: {$0 == query})
        ArchiveService.shared.recentSearches = searches
        state.recentSearches = searches
    }

    public func search() {
        guard !state.currentQuery.isEmpty, canLoadMore(for: state.currentMode) else {
            return
        }
        switch state.currentMode {
        case .posts:
            restSearchPosts(query: state.currentQuery, page: pages[.posts]!.page)
        case .people:
            restSearchPeople(query: state.currentQuery, page: pages[.people]!.page)
        case .audio:
            restSearchAudio(query: state.currentQuery, page: pages[.audio]!.page)
        }
    }

    public func viewMedia(media: MediaDataModel) {
        restViewMedia(media: media)
    }

    private func updateRecentSearches(with query: String) {
        if query.isEmpty {
            return
        }
        var searches = ArchiveService.shared.recentSearches
        if searches.contains(query) {
            return
        }
        searches.insert(query, at: 0)
        ArchiveService.shared.recentSearches = searches
        state.recentSearches = searches
    }

    private func canLoadMore(for mode: SearchMode) -> Bool {
        if let pages = self.pages[mode] {
            return pages.maxPage == 0 || pages.page <= pages.maxPage
        }
        self.pages[mode] = (1,0)
        return true
    }
}

// MARK: - REST requests

extension SearchViewModel {

    private func restSearchPosts(query: String, page: Int) {
        postsManager.getGlobalPosts(postTypes: [], search: query, page: page)
            .onStateChanged({ (state) in
                self.state.searching = state == .started
            })
            .onComplete {[weak self] (response) in
                if let posts = response.result {
                    self?.state.foundPosts.append(contentsOf: posts)
                }
                if let pagination = response.pagination {
                    self?.pages[.posts]?.page = pagination.currentPage + 1
                    self?.pages[.posts]?.maxPage = pagination.pageCount
                }
            }
            .run()
    }

    private func restSearchPeople(query: String, page: Int) {
        profilesManager.searchProfile(search: query, page: page)
            .onStateChanged({ (state) in
                self.state.searching = state == .started
            })
            .onComplete {[weak self] (response) in
                if let people = response.result {
                    self?.state.foundPeople.append(contentsOf: people)
                }
                if let pagination = response.pagination {
                    self?.pages[.people]?.page = pagination.currentPage + 1
                    self?.pages[.people]?.maxPage = pagination.pageCount
                }
            }
            .run()
    }

    private func restSearchAudio(query: String, page: Int) {
        let data = AudioTracksData(page: page, search: query, onlyMy: false, isFavorite: nil)
        audioManager.list(data: data)
            .onStateChanged({ (state) in
                self.state.searching = state == .started
            })
            .onComplete {[weak self] (response) in
                if let audios = response.result {
                    self?.state.foundAudios.append(contentsOf: audios)
                }
                if let pagination = response.pagination {
                    self?.pages[.audio]?.page = pagination.currentPage + 1
                    self?.pages[.audio]?.maxPage = pagination.pageCount
                }
            }
            .run()
    }

    private func restRefreshPost(post: PostModel) {
        postsManager.getPost(postId: post.id)
            .onComplete { [weak self] (response) in
                guard let self = self,
                    let updatedPost = response.result,
                    let postIndex = self.state.foundPosts.firstIndex(where: {$0.id == post.id}) else {
                        return
                }
                self.state.foundPosts[postIndex] = updatedPost
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

    private func restTogglePostFollow(post: PostModel) {
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
                      let postIndex = self.state.foundPosts.firstIndex(where: { $0.id == post.id }) else {
                        return
                }
                self.state.foundPosts.remove(at: postIndex)
                let message = post.type.deleteSuccessMessage
                Toast.show(message: message)
        }.run()
    }

    private func restToggleAudioFollow(audioTrack: AudioTrackModel) {
        var willBeFavorite = !audioTrack.isFavorite
        let operation = willBeFavorite
            ? audioManager.followTrack(track: audioTrack)
            : audioManager.unfollowTrack(track: audioTrack)


        operation
            .onComplete { [weak self] (response) in
                if let trackIndex = self?.state.foundAudios.firstIndex(where: {$0.id == audioTrack.id}) {
                    var updatedTrack = audioTrack
                    updatedTrack.isFavorite = willBeFavorite
                    self?.state.foundAudios[trackIndex] = updatedTrack
                }
        }.run()
    }

    private func restViewMedia(media: MediaDataModel) {
        postsManager.viewMedia(mediaId: media.id).run()
    }
}

// MARK: - Public methods

extension SearchViewModel {
    public func addReaction(post: PostModel, reaction: Reaction) {
        restAddReaction(post: post, reaction: reaction)
    }

    public func removeReaction(post: PostModel) {
        restRemoveReaction(post: post)
    }

    public func togglePostFollow(post: PostModel) {
        restTogglePostFollow(post: post)
    }

    public func deletePost(post: PostModel) {
        restRemovePost(post)
    }
    
    public func updatePost(post: PostModel) {
        restRefreshPost(post: post)
    }

    public func removePost(post: PostModel) {
        state.foundPosts = state.foundPosts.filter({$0.id != post.id})
    }

    public func toggleAudioFollow(audioTrack: AudioTrackModel) {
        restToggleAudioFollow(audioTrack: audioTrack)
    }
}
