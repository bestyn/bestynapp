//
//  AudioListViewModel.swift
//  neighbourhood
//
//  Created by Artem Korzh on 28.01.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import Foundation

class AudioListViewModel {
    enum Filter {
        case discover
        case myTracks
        case favorites
    }

    private lazy var tracksManager: RestAudioTracksManager = RestService.shared.createOperationsManager(from: self)
    private var nextPage: Int = 1
    private var lastPage: Int = 0
    private var search: String?

    @Observable private(set) var filter: Filter = .discover
    @Observable private(set) var tracks: [AudioTrackModel] = []

    init() {
        reloadList()
    }
}

// MARK: - Public methods

extension AudioListViewModel {
    public func changeFilter(_ filter: Filter) {
        self.filter = filter
        reloadList()
    }

    public func search(query: String) {
        self.search = query
        reloadList()
    }

    public func clearSearch() {
        self.search = nil
        reloadList()
    }

    public func loadMore() {
        loadMoreTracks()
    }

    public func toggleFollowed(track: AudioTrackModel) {
        if track.isFavorite {
            restUnfollow(track: track)
        } else {
            restFollow(track: track)
        }
    }
}

// MARK: - Private methods

extension AudioListViewModel {
    private func reloadList() {
        let data = AudioTracksData(page: 1, search: search, onlyMy: filter == .myTracks, isFavorite: filter == .favorites ? true : nil)
        restLoadTracks(data: data, clear: true)
    }

    private func loadMoreTracks() {
        if lastPage > 0, nextPage > lastPage {
            return
        }
        let data = AudioTracksData(page: nextPage, search: search, onlyMy: filter == .myTracks, isFavorite: filter == .favorites ? true : nil)
        restLoadTracks(data: data)
    }
}

extension AudioListViewModel {

    private func restLoadTracks(data: AudioTracksData, clear: Bool = false) {
        tracksManager.list(data: data)
            .onComplete { [weak self] (response) in
                if let pagination = response.pagination {
                    self?.nextPage = pagination.currentPage + 1
                    self?.lastPage = pagination.pageCount
                }
                if let tracks = response.result {
                    clear ? self?.tracks = tracks : self?.tracks.append(contentsOf: tracks)
                }
            }.run()
    }

    private func restFollow(track: AudioTrackModel) {
        tracksManager.followTrack(track: track)
            .onComplete { [weak self] (_) in
                if let trackIndex = self?.tracks.firstIndex(where: {$0.id == track.id}) {
                    var followedTrack = track
                    followedTrack.isFavorite = true
                    self?.tracks[trackIndex] = followedTrack
                }
            }.run()
    }

    private func restUnfollow(track: AudioTrackModel) {
        tracksManager.unfollowTrack(track: track)
            .onComplete { [weak self] (_) in
                if let trackIndex = self?.tracks.firstIndex(where: {$0.id == track.id}) {
                    if self?.filter == .favorites {
                        self?.tracks.remove(at: trackIndex)
                        return
                    }
                    var unfollowedTrack = track
                    unfollowedTrack.isFavorite = false
                    self?.tracks[trackIndex] = unfollowedTrack
                }
            }.run()
    }

}
