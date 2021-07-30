//
//  AudioDetailsViewModel.swift
//  neighbourhood
//
//  Created by Artem Korzh on 15.02.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import Foundation

class AudioDetailsViewModel {

    @Observable private(set) var stories: [StoryListModel] = []
    @Observable private(set) var isFetching: Bool = false
    @Observable private(set) var audioTrack: AudioTrackModel
    @SingleEventObservable private(set) var lastError: Error?

    private var nextPage: Int = 1
    private var lastPage: Int = 0

    private lazy var storiesManager: RestStoriesManager = {
        let manager = RestService.shared.createOperationsManager(from: self, type: RestStoriesManager.self)
        manager.assignErrorHandler { [weak self] (error) in
            self?.lastError = error
        }
        return manager
    }()

    private lazy var audioManager: RestAudioTracksManager = {
        let manager = RestService.shared.createOperationsManager(from: self, type: RestAudioTracksManager.self)
        manager.assignErrorHandler { [weak self] (error) in
            self?.lastError = error
        }
        return manager
    }()


    init(audioTrack: AudioTrackModel) {
        self.audioTrack = audioTrack
        fetchMoreStories()
    }

}

// MARK: - Public methods

extension AudioDetailsViewModel {
    public func fetchMoreStories() {
        if lastPage > 0, nextPage > lastPage {
            return
        }
        restFetchStories(page: nextPage)
    }

    public func toggleTrackFavorite() {
        restToggleAudioFavorite(isFavorite: !audioTrack.isFavorite)
    }
}

// MARK: - Private methods

extension AudioDetailsViewModel {

}

// MARK: - REST requests

extension AudioDetailsViewModel {
    private func restFetchStories(page: Int) {
        storiesManager.getStoriesByAudio(audioTrackID: audioTrack.id, paging: .init(page: page))
            .onStateChanged { [weak self] (state) in
                self?.isFetching = state == .started
            }.onComplete { [weak self] (response) in
                if let stories = response.result {
                    self?.stories.append(contentsOf: stories)
                }
                if let pagination = response.pagination {
                    self?.nextPage = pagination.currentPage + 1
                    self?.lastPage = pagination.pageCount
                }
            }.run()
    }

    private func restToggleAudioFavorite(isFavorite: Bool) {
        let operation = isFavorite
            ? audioManager.followTrack(track: audioTrack)
            : audioManager.unfollowTrack(track: audioTrack)

        operation.onComplete { [weak self] (_) in
            guard let self = self else {
                return
            }
            var updatedAudioTrack = self.audioTrack
            updatedAudioTrack.isFavorite = isFavorite
            self.audioTrack = updatedAudioTrack
        }.run()
    }
}
