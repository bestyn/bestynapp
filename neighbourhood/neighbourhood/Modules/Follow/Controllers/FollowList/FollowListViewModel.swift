//
//  FollowListViewModel.swift
//  neighbourhood
//
//  Created by Artem Korzh on 02.03.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import Foundation

class FollowListViewModel {

    enum Mode {
        case followers
        case followed
    }

    @Observable private(set) var profiles: [PostProfileModel] = []
    @Observable private(set) var totalProfiles: Int = 0
    @Observable private(set) var error: Error?
    @Observable private(set) var activeFilters: [ProfileType] = []

    private var nextPage = 1
    private var lastPage = 0
    private var searchQuery: String = ""
    private var requestData: ProfilesData {
        var data = ProfilesData(fullName: searchQuery)
        switch mode {
        case .followed:
            data.isFollowed = true
        case .followers:
            data.isFollower = true
        }
        if activeFilters.count == 1 {
            data.type = activeFilters[0]
        }

        return data
    }

    let mode: Mode

    private lazy var followManager: RestProfileFollowManager = {
        let manager = RestService.shared.createOperationsManager(from: self, type: RestProfileFollowManager.self)
        manager.assignErrorHandler { [weak self] (error) in
            self?.error = error
        }
        return manager
    }()


    init(mode: Mode) {
        self.mode = mode
    }
}

// MARK: - Public methods

extension FollowListViewModel {
    func loadMoreProfiles() {
        if lastPage > 0, nextPage > lastPage {
            return
        }
        restLoadMoreProfiles(page: nextPage, data: requestData)
    }

    func follow(profile: PostProfileModel) {
        restToggleFollow(profile: profile, follow: true)
    }

    func unfollow(profile: PostProfileModel) {
        restToggleFollow(profile: profile, follow: false)
    }

    func removeFollower(profile: PostProfileModel) {
        restRemoveFollower(profile: profile)
    }

    func toggleFilter(_ filter: ProfileType) {
        if let index = activeFilters.firstIndex(of: filter) {
            activeFilters.remove(at: index)
        } else {
            activeFilters.append(filter)
        }
        refreshProfilesList()
    }

    func search(query: String) {
        if searchQuery == query{
            return
        }
        searchQuery = query
        refreshProfilesList()
    }

    func refreshProfilesList() {
        restLoadMoreProfiles(page: 1, data: requestData, refresh: true)
    }
}

// MARK: - REST requests

extension FollowListViewModel {
    private func restLoadMoreProfiles(page: Int, data: ProfilesData, refresh: Bool = false) {
        followManager.followList(page: page, data: data)
            .onComplete { [weak self] (response) in
                if let pagination = response.pagination {
                    self?.lastPage = pagination.pageCount
                    self?.nextPage = pagination.currentPage + 1
                    if data.noFilters {
                        self?.totalProfiles = pagination.totalCount
                    }
                }
                if let profiles = response.result {
                    if refresh {
                        self?.profiles = profiles
                    } else {
                        self?.profiles.append(contentsOf: profiles)
                    }
                }
            }.run()
    }

    private func restToggleFollow(profile: PostProfileModel, follow: Bool) {
        let operation = follow ? followManager.follow(profile: profile) : followManager.unfollow(profile: profile)

        operation.onComplete { [weak self] (_) in
            guard let self = self else {
                return
            }
            var profile = profile
            profile.isFollowed = follow
            self.profiles = self.profiles.map({$0.id == profile.id ? profile : $0})
        }.run()
    }

    private func restRemoveFollower(profile: PostProfileModel) {
        followManager.removeFollower(profile: profile)
            .onComplete { [weak self] (_) in
                self?.profiles.removeAll(where: {$0.id == profile.id})
            }.run()
    }
}
