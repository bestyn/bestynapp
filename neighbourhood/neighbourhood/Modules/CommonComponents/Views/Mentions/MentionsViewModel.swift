//
//  MentionsViewModel.swift
//  neighbourhood
//
//  Created by Artem Korzh on 15.03.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import Foundation

class MentionsViewModel {

    private lazy var profilesManager: RestProfileManager = RestService.shared.createOperationsManager(from: self)

    @Observable private(set) var profiles: [PostProfileModel] = []

    private var nextPage = 1
    private var lastPage = 0
    private var lastSearchQuery = ""


    func searchProfiles(name: String) {
        lastSearchQuery = name
        if name.isEmpty {
            profiles = []
            return
        }
        restSearchProfiles(name: name, page: nextPage, refresh: true)
    }

    func loadMoreProfiles() {
        if lastPage > 0, nextPage > lastPage {
            return
        }
        restSearchProfiles(name: lastSearchQuery, page: nextPage)
    }
}

extension MentionsViewModel {

    private func restSearchProfiles(name: String, page: Int, refresh: Bool = false) {
        profilesManager.searchProfileForMention(search: name, page: page)
            .onComplete { [weak self] (response) in
                if let pagination = response.pagination {
                    self?.lastPage = pagination.pageCount
                    self?.nextPage = pagination.currentPage + 1
                }
                if let profiles = response.result {
                    if refresh {
                        self?.profiles = profiles
                    } else {
                        self?.profiles.append(contentsOf: profiles)
                    }
                }
            }.onError { [weak self] (error) in
                print(error)
                self?.profiles = []
            }.run()
    }
}
