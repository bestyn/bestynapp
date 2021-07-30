//
//  ReactionsListViewModel.swift
//  neighbourhood
//
//  Created by Artem Korzh on 19.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import GBKSoftRestManager

class ReactionsListViewModel {

    let post: PostModel

    private lazy var reactionsManager: RestReactionsManager = RestService.shared.createOperationsManager(from: self)

    private(set) var reactionFilter: Reaction?
    private var unfilteredPage: Int = 1
    private var filteredPages: [Reaction: Int] = [:]
    private var maxUnfilteredPage: Int = 0
    private var maxFilteredPages: [Reaction: Int] = [:]
    private var unfilteredLoading = false
    private var filteredLoading: [Reaction: Bool] = [:]
    @Observable public var unfilteredReactions: [PostReactionModel] = []
    @Observable public var filteredReactions: [Reaction: [PostReactionModel]] = [:]
    @Observable public var error: APIError?

    lazy var availableReactions: [(key: Reaction, value: Int)] = post.reactions.filter({$0.value > 0}).sorted(by: {$0.value > $1.value})

    init(post: PostModel) {
        self.post = post
    }

    public func fetchMoreReactions() {
        let filter = reactionFilter
        let page: Int = {
            guard let filter = filter else {
                return unfilteredPage
            }
            return filteredPages[filter] ?? 1
        }()
        let maxPage: Int = {
            guard let filter = filter else {
                return maxUnfilteredPage
            }
            return maxFilteredPages[filter] ?? 0
        }()
        if maxPage > 0, page >= maxPage {
            return
        }
        let loading: Bool = {
            guard let filter = filter else {
                return unfilteredLoading
            }
            return filteredLoading[filter] ?? false
        }()
        if loading {
            return
        }
        restFetchReactions(filter: filter, page: page) { [weak self] (reactions, pagination) in
            guard let filter = filter else {
                self?.unfilteredReactions.append(contentsOf: reactions)
                self?.unfilteredPage = pagination.currentPage + 1
                self?.maxUnfilteredPage = pagination.pageCount
                return
            }
            self?.filteredReactions[filter]?.append(contentsOf: reactions)
            self?.filteredPages[filter] = pagination.currentPage + 1
            self?.maxFilteredPages[filter] = pagination.pageCount
        }
    }

    public func changeFilter(selectedReaction: Reaction?) {
        reactionFilter = selectedReaction
        guard let selectedReaction = selectedReaction else {
            if unfilteredReactions.count == 0, !unfilteredLoading {
                restFetchReactions(filter: nil, page: 1) { [weak self] (reactions, pagination) in
                    self?.unfilteredReactions = reactions
                    self?.unfilteredPage = pagination.currentPage + 1
                    self?.maxUnfilteredPage = pagination.pageCount
                }
            }
            return
        }
        if filteredReactions[selectedReaction] == nil {
            filteredReactions[selectedReaction] = []
        }
        if let storedReactions = filteredReactions[selectedReaction],
           storedReactions.count == 0, !(filteredLoading[selectedReaction] ?? false) {
            restFetchReactions(filter: selectedReaction, page: 1) { [weak self] (reactions, pagination) in
                self?.filteredReactions[selectedReaction]?.append(contentsOf: reactions)
                self?.filteredPages[selectedReaction] = pagination.currentPage + 1
                self?.maxFilteredPages[selectedReaction] = pagination.pageCount
            }
        }
    }
}

extension ReactionsListViewModel {
    private func restFetchReactions(filter: Reaction?, page: Int, completion: @escaping ([PostReactionModel], Pagination) -> Void) {
        reactionsManager.reactionsList(postID: post.id, reaction: filter, page: page)
            .onStateChanged({[weak self] (state) in
                if let filter = filter {
                    self?.filteredLoading[filter] = state == .started
                } else {
                    self?.unfilteredLoading = state == .started
                }
            })
            .onError({ [weak self] (error) in
                self?.error = error
            })
            .onComplete { (response) in
                if let pagination = response.pagination,
                 let reactions = response.result {
                    completion(reactions, pagination)
                }
            }.run()
    }
}
